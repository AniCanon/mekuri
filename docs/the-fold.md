# The fold

The sheet bends around a cylinder whose axis is parallel to the spine and travels across the page as the turn progresses; the corner lifts before the edge, and the crease bows. Progress runs 0 at rest to 1 at a completed turn. The same constants produce the same numbers on both platforms.

| Constant | Value | Meaning |
|---|---|---|
| `cylinderRadius` | `0.25 × pageWidth` | Radius at the held end; a wide roll reads as a page, a tight one as a peeled sticker |
| `radiusOpening` | `0.25` | Growth of the radius per page width of fold distance from the held end |
| `cornerShear` | `0.10` | Horizontal travel of the fold line per unit of vertical distance from the page centre |
| `creaseBow` | `0.35` | How far the free corner runs ahead of a straight crease |
| `backFaceDim` | `0.86` | Darkest brightness of the lit reverse of the sheet |
| `creaseShadowWidth` | `0.10 × pageWidth` | Shadow band cast along the fold onto the page below |
| `creaseShadowOpacity` | `0.35` | Peak opacity of that band |
| `snapThreshold` | `0.35` | Share of the finger's range a drag must cover before its release completes the turn |
| `flingVelocity` | `600 pt/s` | Velocity past which a release completes regardless of progress |
| `settleAnimation` | timing curve `(0.35, 0.1, 0.75, 0.85)`, `0.42 s` | Completion and fall-back; slow off the grab, quick into the landing |
| `tapZoneWidth` | `0.25 × pageWidth` | Outer zone on each side; the middle half is the centre zone |
| `minimumDoublePageWidth` | `270 pt` | Narrowest fitted page at which `.automatic` lays out a spread |
| `minimumDoubleFillFraction` | `0.6` | Least share of the container's height a fitted spread may cover |

Six of these are the modifiers above: `cylinderRadius`, `cornerShear`, `creaseBow`, `snapThreshold`, `settleAnimation` and `tapZoneWidth`. Radius opening, back-face dimming, the crease shadow and the fling velocity keep their tuned values. [the architecture](architecture.md) describes how the fold is drawn and what a turn costs.

The names differ per platform: see [SwiftUI](swiftui.md) and [Compose](compose.md).
