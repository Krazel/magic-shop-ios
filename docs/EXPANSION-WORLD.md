# Architectural annex — World contract

Date: 2026-09-21. Baseline: app 0.4, repository HEAD 2a68541.
Status: World implementation written after director selection of the full left
reference; static verification passes. Native compile, interaction tests and
runtime visual comparison are pending root integration. No saved state changes.
Owner: World lane; reference/material art belongs to commerce_visuals, and
integration/tests/versioning belong to root.

## Defect observed

The current [free-play capture](../design/runtime/0.4/a701788/freeplay-runtime.png)
shows an annex resembling a low tray attached to a taller building. Its back wall
is much shorter relative to a floor cell, the copied floor has a separate lighting
field, and the shared-wall cover is a strip of floor rather than a built opening.
The historical rear-room capture also shows floor drawn across the old plaster
wall, making the attachment resemble a ramp or poster.

ShopScene.addAnnex currently combines the complete AnnexRoomBackground bitmap,
a replacement floor copied from RepairedShopBackground, and another floor strip
over the shared wall. makeProjectedAnnex maps the entire asset through a floor
projection, including its upright walls. makeMatchingFloor relocates a lit source
region, so the baked lighting and material seams do not describe one room.

## Selected structural direction

A five-by-five adjoining showroom with a deliberately framed wide opening:
matching tall cream/teal walls, real wall thickness, endpoint jambs, and a thin,
flush pale-stone threshold. Keep the whole five-cell connection walkable. No
center pillar, narrow doorway, step, raised platform or lintel hiding customers.
Root selected [left v2](../design/approved/expansion-left-v2.png) under delegated
direction before World implementation and then selected
[right v2](../design/approved/expansion-right-v2.png). The rear uses the same
architecture, now selected as [rear v3](../design/approved/expansion-rear-v3.png). Its generative widening of the main room is explicitly excluded: native projection and persisted coordinates remain unchanged.

The original shop plate remains preserved. A shaped aperture will remove the
shared wall from its displayed layer. In the rear orientation this must remove
the full plaster/wainscot/cap height, not cover it with projected floor. Newly
rendered planes behind the aperture supply the adjoining room. Materials and
lighting should explain the connection rather than conceal it with a blend.

## Geometry and save invariants

| Direction | Starter origin | Annex floor | Fully open seam |
| --- | --- | --- | --- |
| Left | (5,0) | x=0...5, y=3...8 | x=5, y=3...8 |
| Right | (0,0) | x=11...16, y=3...8 | x=11, y=3...8 |
| Rear | (0,0) | x=3...8, y=11...16 | y=11, x=3...8 |

The intervals above describe geometric edges, not inclusive cell indices. Each
room retains exactly 25 cells. Domain connection cells are five per side, and
RestorationWorld derives the outside perimeter from the union of both rooms.

Preserve project(), its inverse, ExpansionState, hitmap, fixture IDs/origins,
stock references, floor styles, dirt and ShopAccess paths. No save migration,
relocation or new blocker is needed. Jambs occupy the existing wall thickness
outside the passable floor; threshold art does not add a gameplay obstacle.
Existing Oak/Checkered/Terracotta cell overrides continue rendering in their
persisted cells. The base annex must remain visually terracotta, not silently
turn existing wornTerracotta state into an Oak surface.

## Material contract agreed with commerce_visuals

Four opaque full-bleed source textures, without scene perspective or baked
strong directional shadows:

- AnnexFloorTerracotta: top-down worn terracotta base.
- AnnexWallPlasterTeal: frontal cream wall, approximately 70% plaster above a
  30% teal wainscot; no baked corners or scene silhouette.
- AnnexWallCapTeal: top-down teal wall cap/thickness material.
- AnnexThresholdStone: top-down pale stone for the flush threshold.

World constructs textured floor quads, vertical wall planes, caps and endpoint
jambs. Upright wall height is independent of floor depth. The full-room asset
warp used by the previous annex is replaced, not merely recolored. Sources and
imagesets are owned by the art lane. Native geometry must retain painted texture
and the selected complete reference; untextured placeholder walls are not a
finished deliverable.

## Implementation boundaries and verification plan

The change belongs in ShopScene's environment/annex construction, with focused
World helpers if useful. Keep furniture, customers, clean/paint layers and the
existing pause fix intact. The shared-wall mask and architectural planes must
be derived from the same projected boundary used by actual movement.

Root will seed annex-left/right/rear with two tables, a physical potion and a
four-cell Oak patch. Verify normal, compact and accessible layouts, with pan/zoom:

- opening has correct thickness and no remaining plaster/cap across the passage;
- room walls share the visual scale and perspective of the main building;
- five adjacent crossing paths remain visibly open, including their endpoints;
- floor editing, fixtures, products and customer depth remain registered to cells;
- saved placement/floor choices survive the renderer change without mutation;
- camera framing leaves the annex usable and its connection understandable;
- pauses continue rendering changed camera/product state while time stays stopped.

A seamless single-room alternative is possible, but requires three coherent
expanded plates with fixed starter landmarks, opening, perimeter and shared
lighting authored together. Retouching only the current seam cannot achieve it.
The selected framed-room approach keeps the original plate and state model while
making the connection an intentional architectural feature.

## Implementation delivered

Only `MagicShop/World/ShopScene.swift` and this report changed in the World lane.
The complete-room `makeProjectedAnnex` and copied-lit-floor `makeMatchingFloor`
renderers were removed. Their old assets remain preserved in the repository but
are no longer used by World.

- The original starter/repaired sprite remains intact. An SKCropNode uses an
  outer path plus an opposite-winding shared-wall hole. Side openings follow
  calibrated original wall cross-sections; the rear removes the full plaster,
  cap and baked lamp over x=3...8, down to the floor at y=11.
- The annex floor is one projected quad of the new five-by-five terracotta
  material. Upright rear walls are separate quads, 224 authored pixels tall,
  matching the original rear wall (about 4.54 floor rows). Side rooms have
  progressively cut-away side walls and a low front lip. The rear annex has
  full-height side walls at its connection to the original rear wall.
- Wall caps and endpoint jambs use the same material family. Jamb footprints
  are wholly in outside cells beyond the shared edge endpoints. No pillar or
  lintel covers the five passable connection cells. The pale threshold is only
  0.24 cells wide, at floor height, over the full five-cell opening.
- Existing floor overrides still render at z=-85 above the annex base at -92;
  threshold trim is -82, dust -60 and furniture retains its original depth.
  No world map, route, saved floor, fixture or inventory data is written.
- Expanded camera fitting includes the original exterior, annex floor and tall
  walls. It reserves the top HUD and bottom preparation area, including on the
  compact viewport. Stock's automatic lift is corrected when necessary to keep
  its selected display between 28% and 47% of viewport height. User pan is added
  after that automatic correction and remains free. Unexpanded camera behavior
  is unchanged.
- Annex clocks/paintings mount at the actual wall height; short cutaway walls
  constrain their art height. Existing main-room decoration placement is
  unchanged. Front annex decorations remain small on the low cutaway fascia;
  they do not float above a nonexistent full front wall.
- Paused scenes still render direct camera/stock updates via the existing
  running SKView + paused scene tree. No animation, Reduce Motion, drag,
  accessibility identity or customer behavior changed.

## Verification at World handoff

`powershell -ExecutionPolicy Bypass -File scripts/verify-static.ps1`: PASS.
This is a Windows static check, not a SpriteKit/Xcode compile or visual pass.
Independent Core-lane arithmetic confirmed 876 projection round trips across
three directions and regular/compact viewports (maximum error 3.55e-15 cells).
Its first selected annex display lands around screen y=254..255 on 402x874 and
194..196 on 375x667 after Stock lift. Native captures remain the acceptance gate
for mask alpha, material balance, joints and occlusion.

Root's `annex-left/right/rear` fixtures contain two annex tables, one physical
potion and four persisted Oak cells. The first table retains accessibility ID
`fixture-world-10000000-0000-0000-0000-000000000001`; Root's UI test selects it,
returns stock and restocks using native controls. Inspect all three overview
captures plus compact and larger-text variants. No Git or Actions operation was
performed by this lane.
Independent review found and fixed a camera continuity edge case before CI:
starting a drag on the selected rear-room display from Stock now retains the
automatic correction using the persisted fixture anchor, while its draft moves.
Otherwise removing that correction at touch-down would shift the camera by about
107 points and change finger-to-cell mapping mid-gesture. A new purchase draft
has no persisted matching fixture and receives no such correction.