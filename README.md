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
- Android minSdk 33, Kotlin with Compose. The fold is an AGSL `RuntimeShader` applied as a render effect. The library is its own Gradle build under `android/`.

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/AniCanon/mekuri.git", from: "0.2.0")
```

Gradle, from GitHub Packages:

```kotlin
implementation("studio.anicanon.mekuri:mekuri:0.2.0")
```

Both need a little more than one line — the Swift product to depend on, the Maven repository and its credentials. The platform guides below have the whole thing.

## Documentation

| | |
|---|---|
| [SwiftUI](docs/swiftui.md) | Install, the page mode, spreads, and every modifier |
| [Jetpack Compose](docs/compose.md) | Install, the page mode, spreads, and every parameter |
| [The fold](docs/the-fold.md) | The constants both platforms share, and what each one does |
| [Accessibility](docs/accessibility.md) | What the pager exposes, and what it does not |
| [The demos](docs/demos.md) | Running the comic on either platform |
| [Testing](docs/testing.md) | The suites, and how parity is held |
| [Architecture](docs/architecture.md) | How the fold is drawn and what a turn costs |
| [Porting notes](docs/porting.md) | The description the Compose port was built from |

## Out of scope

Deliberately absent, and not planned:

- **Page content of any kind.** The library never loads, decodes or caches an image. A page is a closure the consumer writes, and the library only asks it for an index.
- **Zoom and pan.** A pinch-to-zoom reader wraps the pager and stands paging down with `mekuriPagingEnabled(false)` / `pagingEnabled = false` while it is zoomed.
- **Vertical and continuous-scroll reading modes.** The fold is a horizontal page turn and nothing else.
- **Chrome.** Page counters, thumbnails, a scrubber and a table of contents are the consumer's, and the demos show one way to build them.

## Licence

MIT — see [LICENSE](LICENSE).
