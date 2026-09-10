# Mekuri for SwiftUI

How to install the pager, how a page learns it is being turned, and every modifier.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/AniCanon/mekuri.git", from: "0.1.0")
]
```

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "Mekuri", package: "mekuri")
])
```

In Xcode, use **File > Add Package Dependencies** and paste the same URL.

`Package.swift` sits at the repository root, because Swift Package Manager looks for a manifest only there when a package is consumed by URL. Its targets point into `ios/`.

## Using the pager

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

Nothing is captured. The shader samples the face's live rendered content every frame, on both platforms, so **the turning view must be static for as long as the turn lasts**. Draw it from what is already in memory. Anything that resolves mid-turn — a placeholder that fills in, an image that finishes loading, an animation still running — re-renders inside the fold, and the reader sees the sheet change under the finger.

### Selection

`currentPage` is the consumer's. A turn writes it when the leaf lands. Setting it from outside curls to a neighbouring page or spread and crossfades to anything further away; setting it to the other page of the spread already on screen moves nothing and is never written back.

### Spreads

```swift
.mekuriSpread(.automatic)          // .automatic, .single, .double
.mekuriCoverStandsAlone(true)      // page 0 opens alone in the trailing slot
.mekuriPageAspectRatio(2.0 / 3.0)  // width over height of one page
```

Under `.automatic` two pages are laid out at whatever size actually fits, and the spread appears when each fitted page is at least 270 points wide and the pair covers at least 60 percent of the container's height. The first is a readability floor, the second keeps a spread from leaving nearly half the container empty; neither is a device test. Written out, a container of `width × height` at `aspect` spreads when `aspect × height ≥ 270`, `width ≥ 540` and `width ≥ 1.2 × aspect × height`. At the default 2/3 shape that is 405 points of height, 540 of width, and `width ≥ 0.8 × height`: a phone in portrait is too narrow either way, a phone in landscape spreads once it is 405 points tall, so larger ones do and smaller ones do not, and a tablet spreads in landscape but not in portrait. A narrower page shape needs a taller container to clear the floor and a less wide one to fill it. A spread holding one page (the cover, or a lone last page) sits centred and slides into its slot as the first turn begins.

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

## Working against a checkout

To develop against the library rather than a release, point at a clone of this repository. For Swift, `.package(path: "../mekuri")`.

See [the Compose guide](compose.md) for the same API in Kotlin, and [the fold](the-fold.md) for what the constants mean.
