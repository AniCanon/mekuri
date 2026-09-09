# 📖 Mekuri

A page-curl pager for SwiftUI and Jetpack Compose. Pages turn the way paper does — the corner lifts, the sheet peels under the finger, the back face shows through — and the library knows nothing about what is drawn on those pages.

> **Why "Mekuri"?** Mekuru (めくる) is the Japanese verb for turning a page.

## Status

Under construction. The Swift package currently ships the fold geometry and its configuration; the pager, the fold renderer and the Compose implementation follow.

## Requirements

- Swift 6.0, iOS 18 / macOS 14
- No dependencies beyond the platform SDK

## Installation

Until the first tagged release, consume it as a local package:

```swift
dependencies: [
    .package(path: "../Mekuri")
]
```

## Tests

```bash
swift test --package-path Mekuri
```

The geometry is UIKit-free, so the tests run on macOS without a simulator.

## Licence

MIT — see [LICENSE](LICENSE).
