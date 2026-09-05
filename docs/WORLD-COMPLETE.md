# World implementation and verification

Updated: 2026-09-05. Owner: delegated World implementation lane.
Scope: MagicShop/World/ShopScene.swift and ShopSceneContainer.swift.
Product target: 0.2 (1). This document records implementation and evidence; the
final simulator capture comparison remains an integration check.

## Snapshot contract

ShopSceneContainer accepts the complete immutable GameState, an optional
PlacementDraft with validation result, selectedFixtureID, activeVisit,
visitProgress (0...1), lastOutcome, reduceMotion, isPaused, cameraResetID,
contentLift, onGridTap and onFixtureTap.

AppModel owns time, purchases, stock, sales and persistence. World never invokes
GameEngine, advances a visit, charges money or saves state. The active visit
token is cached with its deterministic ShopAccess route. Root keeps that token
through the exit animation and commits the sale at progress 0.65. A receipt is
displayed at most once per visit ID.

The customer approaches during 0...0.55, browses through 0.73 and returns during
0.73...1. App timing is six seconds per visit, or three at fast speed, across
six visits from 09:00 to 18:00. Simulation calendar and weekday are native App
controls, not painted text. A restart uses the persisted next visit supplied by
AppModel; World does not invent a replacement transaction.

## Floor, hit testing and camera

The exact approved 853 x 1844 starter plate remains one sprite. No tile grid is
drawn. Its floor landmarks, in source pixels with Y downward, are:

| Edge | Left | Right |
| --- | --- | --- |
| Near, Y 1172 | X 106 | X 749 |
| Far, Y 629 | X 143 | X 701 |

The persistent 11 x 11 floor projects onto this trapezoid. Drawing and tap
inversion use the same calculation. Out-of-bounds and outside cells are rejected.
Authored debris landmarks now coincide with Core cells: rubble (1,5), broken
boards (9,5), discarded papers (9,2).

SpriteKit converts touch coordinates through the actual camera before floor
inversion, including zoom, native panel lift and expansion centering. Pan deltas
are multiplied by camera zoom, preserving finger speed. Horizontal pan is
available after expansion. Pinch remains incremental. The camera resets through
cameraResetID and VoiceOver actions.

The SKView is adjustable with Zoom in/out, Look toward rear wall, Look toward
entrance and Reset camera actions. Build and Stock provide the native alternative
to selecting painted furniture. Root provides panel lift in screen points and
pauses both its timer and SKView while inactive.

## Furniture and physical stock

All eight FixtureKinds use dedicated painted assets. The shelf uses alternate
side art and a horizontal mirror on the right wall; upright sprites are never
rotated onto their side or upside down. Uniform scaling preserves the artwork.
The side shelf height is calibrated separately from its transparent canvas width.

Stock is drawn on the tabletop or one of the two shelf surfaces. New stock
settles into place with a 0.20-second scale/fade, and a newly placed fixture with
a 0.18-second scale. Both are immediate under Reduce Motion. Stock disappears
only after the App state contains the committed sale; the departing visitor
carries the purchased product.

Wall Clock and Moon Painting use the actual adjacent wall. Rotation chooses
between valid walls at a corner. Rear art mounts above the baseboard; side art
uses an upright perspective quadrilateral. Front art mounts on the facade,
or at the smaller height of an annex cutaway cap. Rugs render below people and
standing furniture. Lantern and crystal glows are restrained native effects.

## Restoration and the one-room expansion

Partial repairs reveal feathered, local regions of RepairedShopBackground. Once
all three groups are repaired, the complete repaired plate is used. The original
starter source and runtime copy are unchanged. Repair visibility is derived from
persisted repairedGroups, not an ephemeral animation.

The expansion uses Core's exact 5 x 5 room:

| Direction | Starter origin | Room origin | Bounds |
| --- | --- | --- | --- |
| Left | (5,0) | (0,3) | 16 x 11 |
| Right | (0,0) | (11,3) | 16 x 11 |
| Rear | (0,0) | (3,11) | 11 x 16 |

Outside cells remain noninteractive. Furniture IDs and stock references retain
Core's migration semantics. Room source pixels are mapped through an 8 x 8
SpriteKit warp to the same projected cell coordinates; transparent padding
does not determine the floor footprint. Left uses a mirrored side module; rear
uses its own front-open art, without rotating the side image.

| Annex source | Canvas | Far floor edge | Near floor edge |
| --- | --- | --- | --- |
| AnnexRoomBackground | 1254 x 1254 | (158,355)-(1010,355) | (98,1108)-(1094,1108) |
| AnnexRoomRearBackground | 1292 x 1218 | (218,338)-(1070,338) | (142,1125)-(1140,1125) |

These are visually measured outer floor landmarks. The shared wall is opened by
a masked floor surface above the original plate and annex. The floor and opening
sample five by five tiles from RepairedShopBackground through a 16 x 16 warp,
keeping the starter material and tile scale. The original image file remains
intact. Camera framing widens for a side room and permits horizontal exploration.

## Asset dependencies

Existing: StarterShopBackground, BasicDisplayTable and SimpleShelf.
New: RepairedShopBackground, AnnexRoomBackground, AnnexRoomRearBackground,
AnnexFloorPatch, SimpleShelfSide, GlowPotion, LuckyCharm, PocketSpellbook,
CustomerPlum, CustomerGreen, CustomerPlumFront, CustomerGreenFront, PottedFern,
StarRug, CrystalDisplay, WallClock, MoonPainting and BrassLantern.

Asset ownership and source preparation belong to the separate visual lanes.
Sources remain under design/assets/complete-game and matching imagesets.
App's OrnatePanel is independent of World.

## Motion, layering and performance

A visitor follows the actual deterministic, walkable ShopAccess path. Its route
is retained when a sale removes the selected unit from stock. Back and front
views distinguish approach and exit. Depth ordering follows the feet, allowing
customers and furniture to overlap naturally. A product thought bubble signals
demand; a restrained gold receipt appears after a sale.

Reduce Motion removes travel, bobbing, glow pulsing and scale/fade insertion;
the visitor stays at its destination and receipt feedback is static. Pause stops
SKView actions and frame updates. Environment, fixtures and preview rebuild only
when their relevant state changes; ordinary progress ticks interpolate existing
customer nodes. Textures are cached.

## Verification and remaining capture checks

- scripts/verify-static.ps1: PASS after the World implementation, with 38 required
  files, 14 Core files, 87 declared XCTest methods, version 0.2 (1), four current
  approval hashes and pinned original asset hashes intact.
- Independent JavaScript arithmetic check: 559 playable cell centers across
  starter/left/right/rear layouts round-trip through floor projection and inverse.
  The three painted debris landmarks resolve to the intended cells.
- Separate arithmetic check of the annex 8 x 8 bilinear mesh: maximum sampled
  floor approximation below 0.001 cell on both sources. This is a geometry
  calculation, not execution of SpriteKit or XCTest.
- Source inspection confirms explicit SIMD2<Float> warp vertices and CGFloat
  geometry conversion, no World transaction/persistence calls, and no raster
  zRotation. The earlier integrated World compiled in root's 1828f16 snapshot;
  the final asset/calibration snapshot requires its own CI run.
- Windows has no Swift/Xcode toolchain. Do not treat static verification as an
  iOS build or a completed screenshot comparison.

Integration should capture starter, each repair state, all three annex choices,
each wall orientation, a stocked front/side shelf, mid-visit and exit, and Reduce
Motion on the same portrait device. Check floor taps after pan/pinch and panel
lift, no visible wall remains across a traversable join, physical products sit
on their surfaces, front-facing exit art is present, and no missing texture is
displayed. Compare the complete implemented screens against design/approved;
record final CI and actual screenshot evidence in the project integration docs.

SpriteKit's native warp API:
https://developer.apple.com/documentation/spritekit/skwarpgeometrygrid/init(columns:rows:sourcepositions:destinationpositions:)

## Runtime capture review: 826ab09 (2026-09-05)

Reviewed the real overview, open, placement, restored-left, restored-right and
restored-rear captures from CI run 33929958252 against
design/approved/complete-game-director-v2.png. Root reports all 90 executed
XCTests passing for that snapshot. UI panel sizing is handled in the App lane.

The screenshots exposed these concrete World defects, corrected in the next
World snapshot:

- Small visible silhouettes: table width increased from 0.88 to 1.16 floor-cell
  width, keeping its visible body close to one cell. Product width increased
  from 0.36 to 0.68 tile, with height capped at 0.82 tile. Customer height is now
  1.65 tiles. Shelf dimensions are retained.
- Decoration scale now accounts for transparent padding: fern canvas 1.30 tile
  width, rug 1.82, crystal 1.38, clock 1.12, painting 1.38 and lantern 1.72. The
  lantern's painted body occupies only 39% of its square source; its base still
  stays comfortably within a cell. The larger flat rug may extend under adjacent
  furniture; it remains nonblocking in Core.
- Rear wall decor was sitting on the baseboard. Mount height is now 2.25 tile
  heights above the rear floor edge, placing the art within the plaster panel.
- The crystal's broad flat oval was distracting. Native ambient light is now
  smaller and very faint (0.035 alpha with 0.009 pulse).
- The annex's orange floor clashed with the starter and showed a rectangular
  patch at the join. Both the annex floor and shared opening now sample a five
  by five tile region from RepairedShopBackground through a 16 x 16 warp and
  polygon crop. Source tile scale and native floor projection are retained.
  The dedicated annex artwork still supplies its walls and cutaway edges.
  AnnexFloorPatch remains an archived asset but is no longer rendered.
- Shrinking the starter for a side room exposed a flat dark strip beyond the
  photo. A painted earth backdrop sampled from the original plate fills that
  area, and a native shader feathers only the plate's outer margins in expanded
  states. The original building and source files are preserved.

Static verification passes after these corrections, including all seven current
approval hashes and archived runtime asset sources. The new World snapshot must
be compiled and recaptured before these visual fixes are considered verified.

## Final World review — 4087139

Public CI 33931440266 passed the Release build and all 90 XCTest. Independent
read-only review of restored-left/right/rear, all three partial repairs, open
and placement found no blocking visual issue. Sizes, mounted decor, product
surfaces, visible placement and independent debris removal are confirmed in
real screenshots archived at design/runtime/0.2/4087139. A rear painting can
touch the cutaway edge and joins retain a slight light/grout transition; these
are minor presentation limits, not gameplay blockers. The later 77cbc09 app
change only increases the Stock camera lift; World source is identical.
