# One rectangular shop — World implementation

Date: 2026-09-22. Status: implemented after exact owner approval of all three
images ("Sí, aplica las tres"). Static verification passes. Native compile,
interaction tests and visual comparison remain root's acceptance gate.
World changed only ShopScene.swift and this report; no Core, App, tests, assets,
Git or workflow operation belongs to this lane.

## Approved direction

The owner replaced the adjoining-room concept with one larger rectangle. The
chosen wall moves entirely to the new exterior; there is no wing, neck, doorway,
internal wall, post or threshold. References:

- `design/approved/rectangular-right-v1.png`
- `design/approved/rectangular-left-v1.png`
- `design/approved/rectangular-rear-v2.png`

Root first selected the direction, then obtained the owner's exact approval of
the three full images after the automatic visual-approval block. The owner also
explicitly authorized the saved-map adaptation after root explained it. These
gates are resolved; no final implementation occurred while they were pending.
Generated furniture rearrangements and minor UI shifts are not copied: native
saved coordinates and the existing UI govern those details.

## Domain and projection contract

| Direction | Final layout | Starter origin | Added strip |
| --- | --- | --- | --- |
| Left | 16x11 | (5,0) | origin(0,0), footprint5x11 |
| Right | 16x11 | (0,0) | origin(11,0), footprint5x11 |
| Rear | 11x16 | (0,0) | origin(0,11), footprint11x5 |

All 176 cells are interior. Core owns schema 6, the 30 newly filled former-void
cells, wall-fixture relocation, route repair, columns and saved data. World uses
`expansion.layout` and final metadata and does not migrate or relocate anything.
The calibrated starter project()/inverse remain unchanged. Left's existing
starterOrigin offset is applied once in projection, not written into the save.
Stock IDs, fixture IDs, floor overrides, dirt and visitor paths stay domain-owned.

## Renderer delivered

`rebuildEnvironment` has two explicit paths. Unexpanded shops retain the exact
original Starter/Repaired background sprite and partial repair overlays. An
expanded shop renders a complete rectangular composition and returns before the
original room sprite is added. Consequently the previous wall cannot survive
under a floor patch. The former opening mask, addAnnex, narrow floor join,
threshold, endpoint jambs and rear-opening decoration clamp are removed.

### Floor

`addRectangularFloor` covers the full layout with a clipped, continuous painted
mosaic, independent of the old boundary. A clean two-by-two source block from
RepairedShopBackground (x374...480,y785...909) repeats at 1.9x2.5 logical cells,
maintaining painted tile scale instead of stretching eleven cells across sixteen.
The same footprint mask clips the last partial blocks exactly. A static broad
ambient shader shades the room's edges/rear; no separate extension lighting field
is pasted on. Persisted floor overrides render above the base in their actual
cells. Dirt, placement and preview layers remain unchanged.

### Rear wall and lamp

Plain wall sections reuse x148...393,y446...629 from the original plate, preserving
warm plaster, shaded rail and teal wainscot. Bounded sections repeat rather than
stretching the entire room. The lamp occupies its own five-cell source section
(x295...549,y446...629) at starterOrigin.x+5.5. Its chain and painted body retain
their scale while the remaining wall gains length. Rear expansion translates the
entire wall to y=16; side expansions extend it to width16.

The upright face is 186 authored pixels; the painted cap adds38 pixels for the
original224-pixel total height. Floor depth never scales wall height.

### Side walls, corners and facade

Both side walls exist only at x=0 and x=layout.width. Their cutaway profile rises
from the near edge to the full rear wall, with the original outward near plaster
face. Textured sections keep detail scale as the wall grows in depth. Caps reuse
x148...694,y406...446, including bevel, highlight and dark fascia. Curved source
corner masks retain the original rounded front and back moulding; no flat
substitute outline is used. Contact shadows are stationary and respect pause and
Reduce Motion without new animation.

The facade preserves the original inner x105...749,y1172...1428 source span,
including door and windows. A lateral extension adds one painted window section
and a narrow framed facade column, below the floor edge. Original exterior
corner/post art moves to the new left/right endpoint. There are no walk-blocking
posts inside the floor. The door stays at the persisted starter entrance and is
therefore off-center after a lateral expansion. Rear expansion preserves the
whole front span.

Wall decorations follow final adjacentWalls metadata. Their expanded mounting
uses the actual perimeter wall face; no old doorway/jamb clamp remains. The
unexpanded decoration positions are unchanged. All furniture/product art,
customer depth, AX identities and gesture callbacks are preserved.

## Camera and interaction

Expanded fitting uses the full rectangular floor/perimeter, including curved
corner and facade lateral extents, with extra source margin and12 screen points
reserved before scaling. The lower facade can continue behind preparation UI,
while the complete interactive floor is framed below the HUD. Unexpanded fitting
is unchanged. Manual pan and zoom remain available.

The existing Stock automatic correction and matching persisted-fixture preview
condition are retained. A drag begun from Stock keeps its automatic camera anchor
throughout the gesture; the user's camera pan is applied afterwards. Paused
scenes still permit direct framebuffer updates through the running SKView while
actions/time remain paused.

## Verification at World handoff

- Required Windows static script: PASS (version0.5/build1 configured by root).
- 1,056 cell-center round trips across all three rectangles at two scales:
  maximum projection/inverse error5.33e-15 cells; all176 cells per layout have
  positive projected area.
- Conservative painted perimeter/corner extrema have minimum lateral margins
  of18.07pt on402x874 and17.64pt on375x667 for side expansions, exceeding8pt.
  Rear margins are56.34pt/77.11pt at those viewports.
- Rear cap screen Y is approximately204pt regular/156pt compact. Side cap Y is
  approximately258pt/176pt. Native captures must verify the actual HUD spacing.
- Static source search finds no annex, jamb, threshold, opening-mask or roomOrigin
  use in ShopScene. Game state mutation and domain/persistence calls were not added.

Root's expanded-* fixtures should show stockable tables and floor overrides in
newly filled cells and across the former boundary. Verify all three normal,
compact and large-text captures, native restock and existing-fixture drag, then
compare painted wall/floor/facade continuity against the approved full images.
Passing model tests alone is not visual acceptance. Source mosaic joints and
repeated wall panels in particular require the native image check.