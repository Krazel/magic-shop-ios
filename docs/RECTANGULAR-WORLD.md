# One rectangular shop — World implementation

Date: 2026-09-22. Status: implemented after the owner's exact approval of all
three images ("Sí, aplica las tres"). The first native Release compiled, but
its visual finish was rejected. The corrections below pass static verification;
a new native capture and interaction check remain root's acceptance gate.

This lane changes only MagicShop/World/ShopScene.swift and this report. Core,
App, tests, assets, Git and workflows belong to other lanes.

## Approved direction and domain contract

References:

- design/approved/rectangular-right-v1.png
- design/approved/rectangular-left-v1.png
- design/approved/rectangular-rear-v2.png

The chosen wall moves entirely to the new exterior. There is one larger room,
with no wing, neck, doorway, internal wall, post or threshold. The exact image
approval and the owner's explicit authorization to adapt saved maps resolved
both earlier approval gates. Generated furniture rearrangements and minor UI
shifts are excluded: native saved coordinates and the existing UI govern them.

| Direction | Final layout | Starter origin | Added strip |
| --- | --- | --- | --- |
| Left | 16 x 11 | (5,0) | origin (0,0), footprint 5 x 11 |
| Right | 16 x 11 | (0,0) | origin (11,0), footprint 5 x 11 |
| Rear | 11 x 16 | (0,0) | origin (0,11), footprint 11 x 5 |

All 176 cells are interior. Core owns schema 6, filling the 30 former-void cells,
wall-fixture relocation, route repair, columns and saved data. World consumes
expansion.layout and final metadata; it does not migrate or relocate anything.
The calibrated starter project()/inverse remain unchanged. Left's existing
starterOrigin offset is used once in projection, never written into the save.

## Environment and painted surfaces

Unexpanded shops retain the exact original Starter/Repaired background sprite
and partial repair overlays. Expanded shops render a complete rectangular
composition and return before adding the original room sprite. The old wall
cannot survive under a floor patch. All former opening masks, addAnnex logic,
floor joins, thresholds, endpoint jambs and rear-opening decoration clamps are
removed.

The floor covers the entire layout with one clipped painted mosaic, independent
of the former boundary. A clean two-by-two source block from the repaired plate
(x374...480, y785...909) repeats at 1.9 x 2.5 logical cells. Last partial blocks
are clipped to the exact floor footprint. A broad static ambient shader adds
edge and rear shading. Persisted floor overrides and dirt remain above the base
at their actual saved coordinates. No permanent gameplay grid is drawn.

The rear wall is a single surface sampling the original continuous source span
x143...701, y446...629. Its horizontal UV mapping has three connected spans:
x143...295, x295...549, x549...701. Both joins sample the exact same source
coordinate, so no lighting discontinuity can be introduced there. The lamp's
central span stays five cells wide at starterOrigin.x + 5.5; the empty side
plaster gains the remaining length. Rear expansion moves this entire wall to
y=16. This intentionally favors continuous original painted lighting over
repeating wall panels with mismatched light at their edges.

Each side wall samples one uninterrupted original side-wall quadrilateral:
floor-near (106,1172), floor-far (143,629), cap-far (115,461), cap-near (61,1141).
The right side mirrors the same source. Rear-wall wainscot is never repeated
along the side. The source's narrow green inner rail and continuous plaster
therefore follow the complete floor edge without the former dark zigzags.
These two source remaps use static SpriteKit texture shaders; no bitmap or asset
file is rewritten and no animation is added.

The upright rear face is 186 authored pixels high, with a painted 38-pixel cap.
Side caps are 30 authored pixels wide, matching the original side moulding.
Their near endpoint sits 45 pixels outside and 31 pixels above the floor; their
far endpoint sits 28 pixels outside and 15 pixels below the rear face's top.
The rear curved source elbow stays anchored to the horizontal rear cap, so the
side cap enters the curve instead of leaving a detached corner outside it.
Rounded source masks preserve both front and rear painted corners.

The facade retains the original x105...749, y1172...1428 span with its door and
windows. A lateral expansion adds one window span and a narrow framed facade
column below the floor edge; exterior posts move to the outer corners. No post
blocks an interior tile. The door stays at the saved starter entrance, so it is
off-center after a side expansion. Rear expansion preserves the front span.

Wall decorations follow the final adjacentWalls metadata and the actual side
face height. Their unexpanded positions are unchanged. Furniture/product art,
customer depth, AX identities, pause behavior and gesture callbacks are intact.

## Native rejection and corrective pass

Root and art reviewed all nine regular/large-text images from source 67eb7da,
run 35666931133. Release compilation succeeded; visual acceptance failed:

1. Rear-wall crops created strong vertical light seams on both sides of the
   lamp. Replaced with the single continuous source/UV surface described above.
2. Repeated rear-wall material created dark zigzags on the side walls. Replaced
   with the original continuous side face, preserving its own painted shading.
3. Rear elbows protruded beyond and detached from the straight side caps.
   Corrected cap width and endpoints to enter the original curved source.
4. The rear facade and front floor were hidden behind the preparation panel.
   Expanded bounds now include the complete facade, down to source y1428 plus
   ten pixels of margin, rather than stopping just beyond the floor edge.

The source mosaic has no reported blocking hole or boundary, but its repeated
joints and the new shaders still require the next native visual comparison.
The rejected first-pass captures are evidence, not the accepted final result.

## Camera and interaction

The entire rectangular architecture, including rounded lateral extrema and the
complete facade, is uniformly fitted between the HUD and preparation card.
The conservative band covers both normal and accessibility text without relying
on a SwiftUI text-size override becoming a UIKit trait:

- 402 x 874: bounds fit within screen Y 204.52...512.16 points.
- 375 x 667: bounds fit within screen Y 138.07...380.86 points.
- 430 x 932: proportional band Y 218.09...546.15 points.

These bands follow measured regular AX Calendar/panel edges (196/520 points)
and the compact reference (129.5/389 points). Uniform fitting preserves the
calibrated projection and relative furniture/cell scale; the deeper rear room
necessarily appears smaller when its entire facade is shown. User pan and zoom
remain available. Unexpanded fitting is unchanged.

The existing Stock correction retains a selected persisted fixture's anchor
while its matching drag preview exists. This keeps finger-to-cell mapping stable
when a drag begins from Stock. User pan is applied afterwards. No drag, hitmap,
transaction or persistence logic changed in the corrective pass. Paused scenes
still render direct UI changes through a running SKView while scene actions and
simulation time remain paused.

## Verification and remaining acceptance

- Required Windows static script: PASS; root configured version 0.5/build 1.
- Initial rectangular Release compiled natively. Its visual rejection is
  recorded above; it does not validate the corrective shaders.
- Independent Core review of the unchanged projection verified 14,256 centers
  across directions, viewports, zooms and pans: no incorrect cell; maximum
  inverse error 1.07e-14 cells. Stock preview preserved its persisted anchor.
- Corrective fit calculation: actual painted rear cap is approximately screen
  Y209.5 for sides /208.5 for rear on 402 x 874; full facade base Y509.2/509.8.
  On 375 x 667, cap Y142.0/141.2; facade base Y378.6/379.0.
- Conservative lateral margins after this fit are at least 35.16 points on
  402 x 874 and 56.62 points on 375 x 667, exceeding the required eight points.
- Both rear UV joins have zero source-coordinate discontinuity. All side source
  coordinates are inside the preserved 853 x 1844 plate.
- No annex, jamb, threshold, opening-mask or roomOrigin use remains in ShopScene.
  World adds no game-state mutation or domain/persistence calls.

Root must capture all three directions in normal, compact and large text, check
continuous plaster/side rails/corner silhouette against the approved references,
and verify that the full facade is visible. Repeat native stock and existing
fixture drag after the fit change. Passing model tests is not visual acceptance.
