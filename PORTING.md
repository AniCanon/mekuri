# Porting Mekuri to Jetpack Compose

This is written for the engineer building the Android half of Mekuri from
scratch. It assumes Kotlin and Compose fluency and no familiarity with the
SwiftUI sources. Read it before opening `ios/`; most of what is worth knowing
about the iOS implementation is not visible in the code, because it was
learned by measuring what the renderer actually did and then arranging the
code so the measurement came out right.

The library splits into three parts. A pure arithmetic core (fold geometry,
turn state, spread layout, drag and tap rules) ports line for line and must
not be reinvented; the numbers in it are asserted equal on both platforms. A
fold renderer that is a fragment shader per platform, where the maths ports
but the plumbing around it does not. And a pager that composes the two, whose
public shape should be idiomatic to Compose rather than a transliteration of
SwiftUI.

## 1. The fold, briefly

A page is a sheet bending around a cylinder whose axis is parallel to the
spine. Progress runs 0 (flat) to 1 (turned). The axis sweeps from the free
edge at progress 0 to the spine at progress 1. Fold distance is measured from
the held end of the page (the bottom, `y == height`) toward the free corner at
the top (`y == 0`).

Three things shape the crease. Corner shear moves the fold line horizontally
by `cornerShear` per unit of vertical distance from the page centre, so the
corner lifts before the edge; it is a ratio, never an angle, which is what
makes it survive a change of page aspect. Crease bow lets the free corner run
ahead of the straight crease by `creaseBow × pageWidth × p(1 − p)`, so the
crease is straight again at both ends of the turn. Radius opening grows the
cylinder radius along the fold from the held end, so the roll widens toward
the corner the way a lifted sheet does.

In page space with the flap entering from the right, every pixel is classified
by its signed distance `d` from the fold axis:

```
held    = 1 − y / height
lead    = bow × width × p × (1 − p)
axis    = width × (1 − p) + shear × (y − height / 2) − lead × held²
flap    = width − axis
d       = x − axis
radius  = heldRadius + radiusSlope × (height − y)
halfTurn = π × radius
```

- `d > radius`: past the roll. The page beneath shows through, darkened by the
  contact shadow, `alpha = opacity × (heldRadius / radius) × reach²` with
  `reach` falling from 1 at the rim to 0 two radii past it.
- `0 ≤ d ≤ radius`: on the roll. `front = radius × asin(d / radius)`,
  `back = halfTurn − front`. If `back ≤ flap` the back of the sheet is visible
  here, sampled at `axis + back` and shaded; otherwise if `front ≤ flap` the
  rising front is visible, sampled at `axis + front`; otherwise nothing has
  reached this pixel and it is contact shadow.
- `d < 0`: short of the crease. If `halfTurn − d ≤ flap` the landed back lies
  here, sampled at `axis + (halfTurn − d)`; otherwise it is the flat, unlifted
  front, sampled in place and dimmed by the crease ramp
  `opacity × saturate(1 + d / shadowWidth)²`.

The back face is lit by a fixed unit light `(0.45, 0.893)` in the x/z plane.
On the roll the normal is `(d / r, √(1 − (d / r)²))`; on the flat landed back
it is `(0, 1)`. Brightness is `mix(backFaceDim, 1, facing³)`, which gives a
highlight band near the top of the roll, darkens to `backFaceDim` at the rim,
and puts the flat back at about 0.96. The front is not shaded. The light
lives in shader space, so it mirrors with the turn; a right-to-left turn is
lit as the exact mirror of a left-to-right one. That is deliberate.

The shader takes a `face` argument that selects one of four passes over the
same arithmetic. `whole` samples one layer for both faces and carries both
shadows; this is single-page mode, where the reverse of the sheet is its own
front mirrored. `front` returns the rising front on the roll and the flat
front short of the crease, and is transparent everywhere else. `back` returns
the back on the roll and the landed back, transparent elsewhere. `shadow`
returns only the contact shadow and the crease ramp, transparent elsewhere.
The faces never overlap on screen, so the stacking order of the front and back
passes carries no meaning, and each shadow is emitted by exactly one pass.

The shader folds a flap entering from the right only. A right-to-left turn is
drawn by mirroring the content horizontally before the effect and mirroring
the result back after it, with the same non-negative progress. Do not try to
mirror by feeding `1 − p` or a negative progress: with the axis at
`width × (1 − p)` a mirrored scalar puts the axis at the wrong edge at the
start of a drag, `d > radius` holds across almost the whole page, and the page
renders as already turned. The mirror has to be spatial.

## 2. What was learned by measurement

Each item below was found by measuring rendered output or counting calls, not
by design. A specification cannot carry these, and rediscovering any of them
on Android costs a day. For each, what was seen, what it means, and what
happens if the Android implementation ignores it.

### 2.1 The shader's product chains are fragile to reassociation

When the leaf was made two slots wide and hinged at the spine, the obvious
implementation was to add a `spine` argument to the shader and rewrite the
axis as `spine + span × (1 − p) + …`. With `spine = 0` that is the same
arithmetic. It was not the same pixels: 26 to 32 pixels differed by exactly
1/255, scattered over the roll, the landed back and the contact shadow, in
every test case, repeatable launch to launch. Rewriting the axis as the
original expression plus `spine × p` did not help. A four-variant bisect
pinned it: adding an unused shader parameter changed nothing, adding the face
branches changed nothing, adding `(width − spine)` into the `lead` product
changed 26 pixels, and adding `spine × p` into the axis sum changed 32. The
compiler's fast-math reassociates the chain, so an operand that is
arithmetically zero still changes the rounding order of the whole expression.

That is why the hinge lives outside the shader. The shader's whole-mode
arithmetic is untouched from the single-page version; a hinged leaf is
expressed entirely through the arguments it is given (section 4.2). AGSL is
compiled by Skia's SkSL pipeline and should be assumed to have the same class
of behaviour. The rule that follows: once the fold is on screen and looks
right, treat the axis and lead expressions as frozen text. New behaviour goes
into the Kotlin side as a transformation of the arguments, never as a new
term in the chain. If it is ignored: the Android fold silently drifts by a
few pixels from its own earlier self every time someone touches the shader,
and there is no way to tell a harmless change from a real regression by eye.

A second, distinct incident is worth separating from this one. When the face
branches were first added, the `layer.sample(position)` call for the flat
region was moved below the new checks and a `half(shade)` conversion was
shared between two consumers. Whole-mode output changed by 1/255 on 7,427
pixels at progress 0.15, all in the crease-ramp band. That was not
reassociation of a product; it was the compiler materialising a float-to-half
conversion differently once it had two users. The fix was to keep the
whole-mode statement sequence verbatim (sample, reach, shade, return) and give
the new branch its own helper. Both incidents motivate the pixel comparison in
section 6; they need different rules to prevent.

### 2.2 A layer effect draws at the model placement of an animated offset

When a spread holds only one page (the cover, or a lone last page), the
whole stack of slots and leaf is shifted so the page sits centred, and the
shift slides to zero as the first turn begins. The first implementation
applied a plain animated offset to the stack. On screen the live slots slid
correctly, but the turning leaf sat at its final, unshifted position from the
first frame and folded there; the cover appeared to jump sideways and then
turn. Measured on the mid-turn captures: the revealed page's edge moved
343 → 437 pt across frames while the cover's edge stayed at 605 pt, the slot's
final place. Deferring the settle by a frame did not change it.

What fits every measurement is that the subtree under the layer effect is
rendered at the model value of an animated geometry modifier, not at its
interpolated presentation value, while plain views follow the interpolation.
The fix was to compute the offset inside the same animatable modifier that
drives the fold, from the interpolated progress, so the model value itself
changes every frame. Then the leaf travelled with the slots (cover edge
327 → 346 → 382 → 409 → 442 → 473 pt across the early frames).

Compose has the same shape of trap available: a `graphicsLayer` carrying a
`RenderEffect` inside a parent whose offset is animated separately. Do not
assume the effect layer follows an animated parent. Compute the spread shift
from the same progress value that drives the shader, in the same draw, and
verify with the edge-position measurement above. If it is ignored: the cover
pops to its slot on the first frame of the first turn, which is exactly the
motion the centred cover exists to avoid.

### 2.3 Translucent shader output composites once per drawing node

The first contact shadow rendered almost opaque black. Two probe builds
showed a constant 0.05 alpha darkening the page to 27% and a constant 0.35
coming out fully opaque. The mechanism was confirmed by scaling: with the
shadow branch returning a constant `(0, 0, 0, 0.2)` and the page reduced to a
stack of N opaque rectangles, the darkening ratio measured 0.800 with one
rectangle and 0.165 with eight (predicted `0.8⁸ = 0.168`); with the content
flattened into one layer before the effect it measured 0.800 with eight. The
shader was being run once per drawing node of the page's view tree (the demo
page had about 25) and its output composited that many times. Opaque outputs
hide this, because scaling every node's colour and compositing equals
compositing and then scaling; only the additive constant-alpha shadow
stacked.

On iOS the fix is to flatten each face into a single layer before the effect
runs. On Compose a `graphicsLayer` is a single surface, so the natural place
to attach the render effect probably already flattens; do not take that on
faith. Run the N-rectangle probe once and confirm the ratio is independent of
N. If it is ignored: the shadow's darkness depends on how many primitives the
consumer's page happens to contain, which no tuning constant can fix.

A related detail: the shadow pass on iOS is drawn on an opaque black layer,
not a transparent one, because the framework culls a layer with nothing
visible in it before the effect can run. The shader replaces every pixel and
samples none, so the layer's own colour never shows. Check whether Compose
skips drawing an effect over an empty or fully transparent layer; if it does,
give the shadow layer an opaque fill the same way.

### 2.4 The per-frame body must not rebuild the back face

The leaf's back face was first handed to the animatable modifier as a
builder closure, and the modifier's body, which runs every animation frame,
called it. Counting invocations of the consumer's page builder over a
four-second turn gave 168 calls for the back face against 3 for the front.
The framework's diff kept the page's own body from re-running, so the cost
was construction and diffing rather than rendering, but it was a consumer
call per frame that the front never paid. The fix was to build the back face
once, beside the front, outside the per-frame path, and pass it in as a
value; the count fell to 4.

In Compose the equivalent mistake is invoking the page composable lambda from
inside a per-frame draw or from a composable that recomposes on every
animation frame. Build the faces where the turn state changes (once per turn
phase, or once per drag sample) and let only progress-dependent drawing sit on
the frame path. The consequence of the fix, which the consumer should know: a
page that is expensive to construct now pays that once per pager
recomposition instead of never, so a consumer with a heavy page should build
its data outside the lambda. If it is ignored: every frame of a spread turn
calls into the consumer, and a page with any non-trivial construction cost
drops frames.

### 2.5 A flat sheet is not transparent

An early version of the two-sided leaf made the front pass return only the
crease shadow over the flat region (the part of the leaf short of the crease,
not yet lifted), on the reasoning that the shadow belongs on what is beneath.
On screen the departing page vanished from the flat region and the page
beneath showed through between the spine and the crease. No book does that.
The rule that stands: the part of the leaf that has not lifted draws the
departing page, opaque and undimmed. The crease ramp and the contact shadow
are not on the leaf at all; they are drawn by the separate `shadow` pass in a
layer beneath the leaf and above the revealed pages, so each composites once
and the leaf's own faces carry no shadow. If it is ignored: the leaf reads as
tracing paper.

Once the leaf is opaque short of the crease, the crease ramp in the shadow
layer almost never reaches the eye: it lies under the opaque flat front, and
within the first tenth of the turn the landed back covers the band where it is
drawn. Only the contact shadow past the rim shapes the look of a spread turn.
The ramp stays in the shader because it would show through a page with
transparent regions, but do not spend time tuning it for spreads.

### 2.6 The leaf spans the whole spread and hinges at the spine

The two-sided leaf was first sized to one page. The shader's axis sweeps
across the whole of its layer, so a one-page-wide leaf's back landed at that
page's inner edge and never reached the other slot; the back page was clipped
at the spine. The leaf has to be a layer two slots wide. Its front is placed
in the trailing slot, its back is mirrored within its own slot and placed the
same way, and the fold sweeps from the outer edge to the spine at the centre
of the layer. Placement is by geometry offsets, never by layout alignment,
because layout alignment follows the layout direction and the leaf must
follow the reading direction. In single-page mode the leaf stays one page
wide and the hinge is simply absent. If it is ignored: the back page stops
dead at the spine mid-turn.

### 2.7 Faces are stills; slots and the revealed page are live

During a turn, the pager draws the two settled slots and the page being
revealed as live content (playback and interaction running) and the two faces
of the turning leaf as stills, each told through its page mode that it is
turning. On iOS the turning page's live view leaves the hierarchy for the
duration of the turn and is recreated when the turn lands or reverts, which
is how a video panel stops without a callback and why per-page view state
does not survive a turn. Mid-turn screenshots confirm both at once: the leaf's
face shows a frozen clock while the page beneath it ticks. The shader samples
the face's rendered content every frame, so a face must be drawable from what
is already in memory; content that arrives asynchronously turns as whatever
placeholder is showing when the turn begins, and anything animating inside a
face is rasterised as it plays. Consumers are told to stand playback down when
the mode is `turning` and draw the last frame they have. If it is ignored: a
video keeps decoding inside a sheet that is being bent, and the two copies of
the page disagree.

## 3. What changed for Android

The minimum API level is 33 for both the app and the library. That makes
`RuntimeShader` available, so the Android fold is an AGSL runtime shader
applied as a render effect on the face's graphics layer, a near-transliteration
of the Metal source. The original Android design, written when the minimum
was lower, was a bitmap mesh: record the turning page into a graphics layer,
convert it to a bitmap when a drag began, and draw that bitmap through a
vertex mesh on a canvas with a colour array dimming the back face.

That design is gone, and with it three problems the Android side no longer has
to solve. There is no capture timing question: nothing has to be snapshotted
before the first fold frame, so a tap-to-turn does not wait a frame for a
bitmap, and a drag that begins during a settle has nothing to re-capture. There
is no staleness question: the shader samples the composable's own rendered
content each frame, so a face is never a stale copy of a page that has since
changed (the page mode still tells the face to hold still, but that is the
consumer's choice, not a capture artefact). And there is no per-turn bitmap
allocation. That figure is arithmetic rather than measurement: one ARGB_8888
capture of a full-screen page at a typical 1080 × 2400 is about 10 MB, and a
two-faced leaf would have needed two, per turn, on the allocation path that
Compose's own frame work shares. The shader approach allocates a `Shader`
value's argument block per frame and nothing else.

Neither platform now captures anything. The mesh density constants the
original Android design carried (`meshColumns`, `meshRows`) do not exist.

## 4. What ports directly

Everything in this section is arithmetic that was tested on iOS and must
produce the same numbers in Kotlin. Port it, write the same tests, and keep
the constants in one place so a parity test can assert them.

### 4.1 The constants

Fold and gesture tuning, with the value and what each does:

| Constant | Value | What it does |
|---|---|---|
| `cylinderRadiusRatio` | 0.04 | Radius of the roll at the held end, as a ratio of page width. Tighter reads as thin paper, wider as card. 0.10 was tried first and the half-turn arc consumed the whole flap, so the back never appeared |
| `radiusOpening` | 1.0 | Growth of the radius per page width of fold distance from the held end, as a multiple of `cylinderRadiusRatio`. `radiusSlope = cylinderRadiusRatio × radiusOpening`. 0 keeps the radius constant |
| `creaseBow` | 0.35 | How far the free corner runs ahead of a straight crease, 0…1. The axis stays monotonic in progress at every row for values up to 1 |
| `cornerShear` | 0.10 | Horizontal travel of the fold line per unit of vertical distance from the page centre. A ratio, never an angle |
| `backFaceDim` | 0.86 | Darkest brightness of the lit back, reached where the surface turns fully away from the light |
| `creaseShadowWidthRatio` | 0.10 | Width of the crease ramp as a ratio of page width |
| `creaseShadowOpacity` | 0.35 | Peak opacity of both shadows |
| `snapThreshold` | 0.35 | Progress past which a released drag completes the turn |
| `flingVelocity` | 600 pt/s | Velocity along the turn past which a release completes regardless of progress. Points on iOS are dp on Android |
| `tapZoneRatio` | 0.25 | Width of each edge tap zone as a ratio of the container width; the middle half is the centre zone |
| `minimumDoublePageWidth` | 320 pt | Narrowest single page at which two pages are shown automatically |
| `landingFraction` | 0.12 | Share of a spread turn over which a hinged leaf's roll flattens |
| `landingFloor` | 0.01 | Smallest radius scale during landing; the contact shadow divides by the radius, so it cannot be 0 |
| drag `minimumDistance` | 10 pt | Travel before a drag reports at all |
| `horizontalDominance` | 1 | Horizontal travel must exceed vertical travel times this before a drag locks a turn; a tie does not lock |
| `blockedDamping` | 1/3 | Fraction of drag travel kept when the turn is blocked at either end |

`settleAnimation` is a spring with response 0.35 and damping fraction 0.86 on
iOS. It is deliberately not held in parity: the two animation systems have no
shared representation, so Kotlin uses its own spring spec and the feel is
matched by eye. The parity test asserts numbers only.

The public knobs are a subset: direction, paging enabled, centre tap, spread
mode, cover stands alone, page aspect ratio, fold radius, corner lift (which
sets `cornerShear`), crease bow, tap zone, snap threshold, settle animation
and reduced motion. Radius opening, back-face dim, the crease shadow and the
fling velocity keep their tuned values and are not exposed.

### 4.2 The fold geometry and the hinged sweep

`MekuriFoldGeometry(pageWidth, configuration)` is the pure form of the shader
maths and is what the unit tests exercise; the shader must match it. It
provides the straight axis `pageWidth × (1 − p)`, the full axis with shear
and bow at a given row, `bowLead(p)`, `heldRadius`, `radiusSlope`,
`radius(atFoldDistance)`, the crease shadow band (full height, width
`pageWidth × creaseShadowWidthRatio`, centred on the straight axis) and the
landing scale. Progress clamps to 0…1 everywhere.

A hinged leaf is drawn by the same shader with transformed arguments. The
layer is two slots wide, the page is the half past the hinge, and the hinge
is always exactly half the layer width. Given page progress `p`, layer width
`W` and hinge `s`:

```
shaderProgress = p × (W − s) / W          // the axis stops at the spine
creaseBow'     = creaseBow × (1 − p) / (1 − shaderProgress)
```

The bow rescale exists because the halved progress alone would leave the bow
lead at half its peak at the end of the turn and pull the crease through the
spine; with it, the lead in layer space equals the page's own
`bow × pageWidth × p(1 − p)` at every progress. Note that it divides by
`1 − shaderProgress`, which is safe only because the hinge is half the layer,
so `shaderProgress ≤ 0.5`. A different hinge fraction would need a different
formula. Radius and shadow width for a hinged leaf come from the page width
(`W − s`), not the layer width.

Without further treatment, progress 1 leaves a roll of radius `r` standing on
the spine, the landed back short of the outer edge by `πr`, and a crease that
crosses the spine diagonally because of the shear. So a hinged leaf's held
radius, radius slope and corner shear are all multiplied by
`landingRadiusScale(p) = max(min((1 − p) / landingFraction, 1), landingFloor)`:
1 until the last twelfth of the turn, then linearly down to 0.01 at progress
1, at which point the back lies flat in its slot and meets the revealed page
on a vertical seam at the spine. Whole mode never sees this; the multiplier
is applied only when a hinge is given.

The parity test worth copying: for progress in {0.1, 0.25, 0.5, 0.75, 0.9,
1} and rows {0, 200, 400, 600, 800} on a 400-wide page in an 800-wide layer,
the layer's axis at `shaderProgress` with `creaseBow'` equals 400 plus the
page's axis at `p`, to 1e-3.

### 4.3 Spreads and the leaf table

`MekuriSpreadLayout(pageCount, coverStandsAlone)` pairs pages. One offset
drives it, `slotOffset = if (coverStandsAlone) 1 else 0`:

```
spreadCount              = (pageCount + slotOffset + 1) / 2
spreadIndex(containing p) = (p + slotOffset) / 2
pages(inSpread k)        = (2k − slotOffset, 2k + 1 − slotOffset), each null outside 0 until pageCount
```

With the cover standing alone, spread 0 holds only page 0 in its trailing
slot. A leaf is built from the current spread and the target spread `k ± 1`,
never from index arithmetic on the page:

| Turn | front | back | revealed | lands in |
|---|---|---|---|---|
| forward | current.trailing | target.leading | target.trailing | leading slot |
| backward | current.leading | target.trailing | target.leading | trailing slot |

A turn refuses (null leaf, null selection) when the target spread is outside
`0 until spreadCount` or the departing slot is absent. Guard on the target
spread existing, not on the trailing slot: the last paired spread has a
trailing page and would otherwise hand back a leaf with nothing behind it.
The selection after a turn is `target.leading ?: target.trailing`.

Six-page matrix to pin, cover alone: spreads are (null, 0), (1, 2), (3, 4),
(5, null), count 4; forward from spread 1 is front 2, back 3, revealed 4,
selects 3; forward from spread 0 is front 0, back 1, revealed 2; forward from
spread 2 is front 4, back 5, revealed null, selects 5; forward from spread 3
and backward from spread 0 are null; backward from spread 2 is front 3, back
2, revealed 1, lands trailing, selects 1; backward from spread 1 selects 0
with revealed null. Paired: spreads (0, 1), (2, 3), (4, 5), count 3; forward
from spread 0 is front 1, back 2, selects 2. Neither the layout nor the leaf
mentions left or right; that is the direction's job.

Automatic spread mode shows two pages when both conditions hold on the
container: `width ≥ 2 × height × aspect` and `height × aspect ≥ 320`. The
second is the floor that keeps a phone in landscape at one page. The page
size in a spread is the largest at the given aspect such that two fit:
`height = min(containerHeight, containerWidth / (2 × aspect))`. Forced single
and forced double ignore the container. The default aspect is 2/3, width over
height.

### 4.4 The turn state

A turn is described as what is on screen, not as a delta: two live base
slots (`leading`, `trailing`, either absent), a leaf with two faces
(`leafFront`, `leafBack`, either absent), the page selected when the turn
began, the page to select when it lands (null when blocked), a progress in
the turn's own direction, the progress the current drag started from (non-zero
after a takeover), and a phase: `dragging`, `armed(decision)` or
`settling(decision)`.

The fold renderer never reads progress directly; it reads
`foldProgress = if forward then p else 1 − p`. A backward turn is the
previous spread's forward leaf run in reverse, so its faces swap:

| Turn | base leading | base trailing | leaf front | leaf back | fold progress |
|---|---|---|---|---|---|
| forward | current.leading | leaf.revealed | leaf.front | leaf.back | p |
| backward | leaf.revealed | current.trailing | leaf.back | leaf.front | 1 − p |

At fold progress 1 a backward turn shows the current leading page flat in its
slot, which is the current state; unfolding lifts it off the page two back
while the previous trailing page lands. Wire it by what each argument means,
not by the labels in the leaf table. A blocked turn (no target spread) lifts
the departing page over nothing with a clear other face and reverts, damped.
A turn whose departing slot is absent has no face and is refused before it
starts.

Single-page mode is the degenerate spread: no leading slot, no back face, the
leaf is the current page across the whole container with its own front
mirrored on the reverse (the `whole` shader pass). Forward: base is the next
page, leaf front is the current page. Backward: base is the current page,
leaf front is the previous page, fold progress `1 − p`. Blocked forward at the
last page has no base; blocked backward at the first page has no leaf and does
nothing at all. That asymmetry is intentional: a backward turn curls the
previous page in, and at the first page there is none to draw.

The spread shift for a lone page: a lone trailing page shifts the whole stack
by `−reading × pageWidth / 2`, a lone leading page by `+reading × pageWidth / 2`,
a full spread by 0, where `reading` is +1 left-to-right and −1 right-to-left.
During a turn the shift runs linearly from the departing spread's rest shift
to the landing spread's (a blocked turn lands where it began), with progress
clamped to 0…1 so a spring's overshoot never slides the book past centre.
Always zero in single-page mode.

### 4.5 Taps, zones and release

A tap resolves to a zone by its x within the container width: `x < width ×
tapZoneRatio` is leading, `x > width × (1 − tapZoneRatio)` is trailing, and
everything else, including points exactly on either boundary, is centre. The
strictness is a deliberate contract: a tap on a boundary never turns a page,
and the test that pins it (width 400, ratio 0.25, x = 100 and x = 300 both
centre) fails if either comparison is relaxed.

A zone becomes a turn through the direction: trailing is forward in
left-to-right and backward in right-to-left, leading is the mirror, centre is
never a turn. A centre tap calls the consumer's centre-tap callback and
nothing else; it fires even with paging disabled. An edge tap with paging
disabled does nothing. An edge tap whose target is out of range does nothing.
An edge tap with paging enabled performs a full animated turn, and does nothing
while another turn is in flight.

The release decision is `progress ≥ snapThreshold || velocity ≥ flingVelocity`,
commit or revert. `velocity` here is not a magnitude: it is the drag velocity
projected onto the turn's axis, positive toward completion, and compared
signed, so a fling against the turn never commits. The axis is −1 for a
forward turn in left-to-right or a backward turn in right-to-left, +1
otherwise; projected velocity is `velocity.x × axis`. The pinning test: a
forward left-to-right turn at progress 0.1 with a +900 pt/s flick projects to
−900 and reverts, even though 900 exceeds the fling threshold. Mutation
testing showed that changing the comparison to `abs(velocity)` fails exactly
that test, so keep it. A blocked turn always reverts on release regardless of
velocity.

### 4.6 Drags

A drag reports after 10 pt of travel. Before a turn locks, every sample's
cumulative translation is checked for horizontal dominance,
`|dx| > |dy| × horizontalDominance` with the constant at 1, so a drag within
45 degrees of horizontal locks and a tie does not. Curl drags are commonly
diagonal toward the spine, which is why the threshold is not stricter. The
check is stateless and re-evaluated on every sample until a turn locks: a
drag that starts vertical and later becomes decisively horizontal locks at
that sample. It is stateless because a drag cancelled by a consumer's
scrollable never delivers an end event, so a sticky "this drag is vertical"
flag would leak into the user's next horizontal drag. If it is ignored: a
vertical-first scroll with a one-pixel horizontal component locks a turn and
reverts it, under every consumer that scrolls.

Once locked, the turn's direction comes from the sign of the horizontal
translation against the forward axis, and it stays locked for the drag;
progress is `clamp(start + dx × axis / width × damping, 0, 1)` with damping
1/3 when the turn is blocked and 1 otherwise, so reversing past the origin
flattens the page rather than starting the opposite turn. `width` is the
distance a drag travels to complete a turn: the container width in single
mode, twice the page width in a spread. A drag can start anywhere on the
page, not only in an edge zone.

A drag that arrives while a turn is settling (or armed and not yet settled)
takes it over, but only if the sample is horizontally dominant; a vertical
sample during a settle lets the animation run on. Takeover reads the last
progress the animation actually presented, writes it as both the start
progress and the current progress without animation, and sets the phase back
to dragging. The presented progress is recorded every frame by the animatable
modifier's setter; it is the one thing the animation system has to hand back
to the model. Each settle takes a token so that a completion callback from an
interrupted settle cannot finish a later one.

Reduced motion (the system setting, or the consumer's override in either
direction) turns every fold into a cut: taps and programmatic changes set the
page directly, and a drag shows no fold but applies the same snap-or-fling
decision on release.

### 4.7 Selection

The selection (`currentPage` on iOS, the pager state's page on Android) is
the consumer's. The pager keeps its own settled page as the record of what is
on screen and treats the consumer's value as a request when they differ.

- A gesture or accessibility turn, on landing, writes the landing spread's
  leading page, or its trailing page when the leading slot is absent (the
  cover). In single mode that is the target page.
- A change from outside by exactly one page (single mode) or one spread
  (spread mode) curls. The curl commits to the page the consumer chose, not
  to the spread's leading page, so the consumer's value is never rewritten
  when the consumer caused the turn. Measured in spreads, the other page of
  the spread on screen is a change of zero.
- A change within the shown spread moves nothing, is recorded as the settled
  page without animation, and is never written back.
- A larger jump crossfades the slots under the settle animation, no leaf.
- A change that arrives mid-turn drops the turn without animation, jumps the
  settled page, and ignores the rest of the current drag so it cannot restart
  a turn.
- A reverted turn writes the settled page back to the consumer if they
  differ, so a programmatic curl the user grabbed and pushed back leaves the
  consumer's value agreeing with the screen.
- A container size change drops any turn and re-lays out without animation.

The echo rule: when the pager writes the consumer's value on commit, the
consumer's change callback fires with a value equal to the settled page and
must return without doing anything. That is the whole mechanism that stops a
commit from triggering a second turn.

Tap-armed turns insert the leaf at progress 0 without animation and start the
settle the moment the leaf appears; a consumer's own animation scope around
its selection change must not leak into the leaf's insertion, or the flat
leaf crossfades in before it starts to curl.

## 5. What is idiomatic to SwiftUI and should not be copied

On iOS everything beyond the page count, the selection and the content is an
environment-backed modifier that cascades from any ancestor:
`.mekuriDirection(.rightToLeft)` set once at the top of a reader reaches every
pager below it. Compose has no cascading modifier for arbitrary values, and
building one out of composition locals for thirteen tuning values would be
fighting the framework. The Compose pager takes them as parameters with
defaults, grouped where that reads well, and the surface already described in
the README is the shape to keep to:

```kotlin
val state = rememberMekuriPagerState(pageCount = pages.size, direction = MekuriDirection.RightToLeft)

MekuriPager(
    state = state,
    pagingEnabled = !isZoomed,
    onCenterTap = { chromeHidden = !chromeHidden },
    spread = MekuriSpread.Automatic,
    coverStandsAlone = true,
    pageAspectRatio = 2f / 3f,
) { pageIndex ->
    PageContent(page = pages[pageIndex])   // reads LocalMekuriPageMode.current
}

state.animateToPage(n)
```

The one thing that must travel through the tree is the page mode. On iOS it
is an environment value the pager sets on each page's subtree, so a video
panel several composables below the page can read `turning` and stand itself
down without any parent threading a flag. On Android that is a composition
local, `LocalMekuriPageMode`, provided by the pager around each face and slot
it builds, defaulting to `Live` outside a pager. This is the reason the mode
is not a parameter of the page lambda: the consumer that needs it is rarely
the one that receives the lambda's arguments.

Two other iOS specifics are framework plumbing, not design. The pager's
"settled page" state lives in view state on iOS and belongs in the
remembered pager state on Android, alongside `animateToPage` and
`scrollToPage`. And the trick of recording the presented animation value from
inside the animatable modifier's setter is how SwiftUI hands the animated
value back; in Compose an `Animatable<Float>` is already readable at any
frame, so takeover simply reads it.

Gesture precedence on iOS is achieved by attaching the drag and tap to the
container with a hit-testable content shape and letting descendant buttons
win by default; there is no overlay and no high-priority gesture. On Compose
the equivalent is a `pointerInput` on the container that yields to events
already consumed by children, so a button inside a page keeps its taps even
inside an edge zone. With paging disabled the drag detector should not
compete with the consumer's own scroll or pinch inside the page at all.

## 6. Verification that caught things and should be repeated

Two measurements found real defects on iOS. Neither is expensive once the
harness exists, and both should be part of any change to the shader or the
pager.

**Pixel comparison of a fold, same frame, before and after.** A screenshot
burst of a running turn never lands on the same progress twice and the live
clock on the revealed page differs anyway, so the comparison has to be at a
fixed progress with nothing animating: a harness that draws a static page
beneath a folded page at a progress read from the launch environment, with
every page in `turning` mode. Establish determinism first (two launches of
the same build must differ by zero pixels; on iOS they did), then diff the
before and after captures over the full frame. Run three cases: 0.15 and 0.40
left-to-right, which between them exercise every branch of the whole-mode
shader (the rising front, the crease ramp and the contact shadow at 0.15; the
back on the roll, the landed back and the contact shadow at 0.40), and 0.40
right-to-left for the mirror. The pass criterion is zero differing pixels in
the page area. This is what caught the 7,427-pixel drift from a reordered
statement and the 26-pixel drift from a zero-valued term; neither was visible
by eye, and both would have been shipped as "no change". Keep the harness out
of the demo (it earns no place there) but keep it easy to swap back in.

**Counting page builds across a turn.** Instrument the consumer's page lambda
and the page's own composition with counters, log them per second, and run a
tap-driven turn at a slow settle (four seconds is long enough to make a
per-frame call unmistakable: 168 at the simulator's frame rate). The
expectations on iOS after the fix, which Android should match or beat: the
page lambda is called about three times per face or slot over a turn and zero
times at rest; page bodies evaluate once or twice per page per turn; nothing
outside the visible page or spread is ever built; a `Shader` argument block is
built once per pass per frame (one in single mode, three in a spread) and the
shader object itself is created once. A settled pager must evaluate nothing
even while a live page animates its own content.

Two further probes are cheap and worth keeping: the N-rectangle compositing
probe from section 2.3, and the edge-position measurement from section 2.2 on
the first frames of a turn away from a centred cover.

Three things were never observed on iOS and the Android side should verify
them on its own rather than trusting the port: the drag path on screen
(every mid-flight capture was a tap-driven settle, because injected touches
were delivered as taps), the interrupted-settle takeover (a finger can catch a
settle; the injection tools could not), and a rotation of a running app from
single to spread and back (the arrangement switch was exercised through the
forced-mode control instead). The drag path and the settle share the same
progress and the same modifier, so no difference is expected, but it is
expectation rather than evidence.


> The public tuning knobs number seven, not six: fold radius, corner lift, crease bow, tap zone,
> snap threshold, settle animation and the reduced-motion override. Everything else the fold uses
> stays internal on both platforms.

> Parity is asserted at an absolute tolerance of 1e-3 at page scale, not at exact equality.
> Compose geometry and the shader uniforms are single precision, where one unit in the last place at a
> page width of 400 is already about 3e-5, so exact equality is unreachable and a tighter tolerance
> would only be provable against a double-precision shadow of arithmetic the shader never runs.
> 1e-3 of a point is far below a pixel and is what the two platforms must genuinely agree to.
