<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/mekuri-dark.png">
    <img src="assets/mekuri-light.png" alt="Mekuri" width="220">
  </picture>
</p>

<p align="center">
  <img src="assets/mekuri-turn.gif" alt="A two-page spread turning forward, a drag released short of the threshold springing back, a backward turn, and a right-to-left turn" width="720">
  <br>
  <a href="assets/mekuri-turn.mp4">mp4</a> — recorded from the demo on an iPad in landscape
</p>

# Mekuri

A page-curl pager for SwiftUI and Jetpack Compose. Pages turn the way paper does — the corner lifts, the sheet peels under the finger, the back face shows through — and the library knows nothing about what is drawn on those pages.

> **Why "Mekuri"?** Mekuru (めくる) is the Japanese verb for turning a page.

## What it does

- One page across the container, or a two-page spread with a real double-sided leaf when the container is wide enough.
- Left-to-right and right-to-left reading. Page indices are always in reading order; direction only decides which edge is the spine.
- Drag to peel, release to snap or spring back, tap an outer zone to turn, tap the centre to report to the consumer.
- Each page reads whether it is settled or being turned, so a video panel deep inside a page can stand itself down without any parent threading a flag.
- Reduce Motion honoured: a turn becomes a cut.
- Nothing is built outside the visible page or spread, and a settled pager evaluates nothing.

## Requirements

- iOS 18 / macOS 14, Swift 6.0. The fold is a Metal `layerEffect`; on macOS the package builds so `swift test` runs anywhere, and the fold renders on iOS.
- Android arrives as its own Gradle build under `android/`.

## Installation

Until the first tagged release, consume the package by path:

```swift
dependencies: [
    .package(path: "../Mekuri")
]
```

`Package.swift` sits at the repository root — Swift Package Manager finds a manifest only there when a package is consumed by URL — and its targets point into `ios/`.

## SwiftUI

The initialiser takes only what a pager cannot exist without. Everything else is an environment-backed modifier that cascades from any ancestor.

```swift
import Mekuri

MekuriPager(pageCount: pages.count, currentPage: $index) { pageIndex in
    PageView(page: pages[pageIndex])       // reads @Environment(\.mekuriPageMode)
}
.mekuriDirection(.rightToLeft)
.mekuriPagingEnabled(!isZoomed)
.mekuriOnCenterTap { chromeHidden.toggle() }
```

Give the pager a background: a blocked turn at the first or last page lifts the page over whatever lies behind the pager.

### The page mode

```swift
struct PageView: View {
    @Environment(\.mekuriPageMode) private var mode

    var body: some View {
        switch mode {
        case .live:    LivePanel()          // playback, interaction
        case .turning: LastFrame()          // drawn from memory
        }
    }
}
```

A `.turning` face is rasterized by the fold shader every frame, so it must be drawable from what is already in memory. Content that arrives asynchronously turns as whatever is on screen when the turn begins.

### Selection

`currentPage` is the consumer's. A turn writes it when the leaf lands. Setting it from outside curls to a neighbouring page or spread and crossfades to anything further away; setting it to the other page of the spread already on screen moves nothing and is never written back.

### Spreads

```swift
.mekuriSpread(.automatic)          // .automatic, .single, .double
.mekuriCoverStandsAlone(true)      // page 0 opens alone in the trailing slot
.mekuriPageAspectRatio(2.0 / 3.0)  // width over height of one page
```

Under `.automatic` two pages appear when both fit the container at the page aspect and each is at least 320 points wide — a landscape iPad, not a phone. A spread holding one page (the cover, or a lone last page) sits centred and slides into its slot as the first turn begins.

### Modifiers

| Modifier | Default | Meaning |
|---|---|---|
| `mekuriDirection(_:)` | `.leftToRight` | Which edge is the spine |
| `mekuriPagingEnabled(_:)` | `true` | Off: drags and edge taps are ignored, centre taps still report |
| `mekuriOnCenterTap(_:)` | none | Called for a tap in the centre zone |
| `mekuriSpread(_:)` | `.automatic` | One page or two |
| `mekuriCoverStandsAlone(_:)` | `true` | Page 0 alone in the trailing slot |
| `mekuriPageAspectRatio(_:)` | `2/3` | Width over height of one page |
| `mekuriFoldRadius(_:)` | `0.04` | Cylinder radius as a ratio of page width |
| `mekuriCornerLift(_:)` | `0.10` | Fold-line travel per unit of vertical distance from the page centre |
| `mekuriCreaseBow(_:)` | `0.35` | How far the free corner runs ahead of a straight crease, 0…1 |
| `mekuriTapZone(_:)` | `0.25` | Width of each edge tap zone as a ratio of page width |
| `mekuriSnapThreshold(_:)` | `0.35` | Progress past which a release completes the turn |
| `mekuriSettleAnimation(_:)` | `nil` | Settle animation; `nil` is the package spring |
| `mekuriReducedMotion(_:)` | `nil` | Override the system setting either way; `nil` follows it |

## Jetpack Compose

Compose has no cascading modifier for arbitrary values, so the Compose API mirrors the concepts rather than the syntax. The page mode arrives through a composition local so a deep child can read it, exactly as on iOS. This is the designed surface; the module ships with the Android build.

```kotlin
val state = rememberMekuriPagerState(pageCount = pages.size, direction = MekuriDirection.RightToLeft)

MekuriPager(
    state = state,
    pagingEnabled = !isZoomed,
    onCenterTap = { chromeHidden = !chromeHidden },
) { pageIndex ->
    PageContent(page = pages[pageIndex])   // reads LocalMekuriPageMode.current
}

state.animateToPage(n)
```

## The fold

The sheet bends around a cylinder whose axis is parallel to the spine and travels across the page as the turn progresses; the corner lifts before the edge, and the crease bows. Progress runs 0 at rest to 1 at a completed turn. The same constants produce the same numbers on both platforms.

| Constant | Value | Meaning |
|---|---|---|
| `cylinderRadius` | `0.04 × pageWidth` | Radius at the held end; tighter reads as thin paper, wider as card |
| `radiusOpening` | `1.0` | Growth of the radius per page width of fold distance from the held end |
| `cornerShear` | `0.10` | Horizontal travel of the fold line per unit of vertical distance from the page centre |
| `creaseBow` | `0.35` | How far the free corner runs ahead of a straight crease |
| `backFaceDim` | `0.86` | Darkest brightness of the lit reverse of the sheet |
| `creaseShadowWidth` | `0.10 × pageWidth` | Shadow band cast along the fold onto the page below |
| `creaseShadowOpacity` | `0.35` | Peak opacity of that band |
| `snapThreshold` | `0.35` | Progress past which a release completes the turn |
| `flingVelocity` | `600 pt/s` | Velocity past which a release completes regardless of progress |
| `settleAnimation` | spring, response `0.35`, damping `0.86` | Completion and spring-back |
| `tapZoneWidth` | `0.25 × pageWidth` | Outer zone on each side; the middle half is the centre zone |

Six of these are the modifiers above: `cylinderRadius`, `cornerShear`, `creaseBow`, `snapThreshold`, `settleAnimation` and `tapZoneWidth`. Radius opening, back-face dimming, the crease shadow and the fling velocity keep their tuned values. [ARCHITECTURE.md](ARCHITECTURE.md) describes how the fold is drawn and what a turn costs.

## Demo

`ios/Demo/MekuriDemo.xcodeproj` is a six-page comic drawn in code, with every modifier on a control. Build it for an iPhone to see single pages and for an iPad in landscape to see spreads; the fourth and fifth pages are one composition that runs across the spine. Each page carries a clock that keeps ticking on a settled page and freezes on the face being turned.

The controls float over the page and a tap in the centre zone shows or hides them. **Presentation** turns off the harness affordances — the edge letters, the per-page button and the counter — and hides the status bar, leaving the page edge to edge; the centre tap still brings the controls back. It is off by default because those affordances are how the gesture-precedence checks are driven.

## Tests

```bash
swift test --package-path Mekuri
```

The geometry, the turn model and the spread layout are UIKit-free, so the suite runs on macOS without a simulator. The fold itself is verified by running the demo.

## Out of scope

Vertical and continuous-scroll reading modes; page thumbnails, counters and chrome; image loading of any kind; publishing to a registry.

## Licence

MIT — see [LICENSE](LICENSE).
