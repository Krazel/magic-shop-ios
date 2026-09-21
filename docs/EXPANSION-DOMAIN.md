# Expansion domain invariants — 0.4.1 visual correction

Date: 2026-09-21. Audited baseline: 2a68541 (app 0.4).
The owner requests a coherent architectural expansion instead of the present
attached-looking room. This document bounds a presentation-only correction.
There are no production Core or schema changes in this lane.

## Saved geometry

The shop consists of its 11 x 11 starter area plus exactly one 5 x 5 room.
Each expanded layout stores 176 cells: 146 inside the building and 30 outside.
The two original front columns remain blocked. All coordinate ranges below
are inclusive, with y increasing toward the rear.

| Direction | Starter cells | Added room cells | Five connections | Entrance |
| --- | --- | --- | --- | --- |
| Left | x5...15, y0...10 | x0...4, y3...7 | x4 ↔ x5, each y3...7 | (10,0) |
| Right | x0...10, y0...10 | x11...15, y3...7 | x10 ↔ x11, each y3...7 | (5,0) |
| Rear | x0...10, y0...10 | x3...7, y11...15 | y10 ↔ y11, each x3...7 | (5,0) |

The whole shared side is open, not a one-cell doorway. Exterior wall adjacency
is recalculated around the union of the two areas. The internal connection has
no mounting wall. The outer annex edges retain their respective walls.

ExpansionState stores its direction and derives these coordinates. GameState
schema 5 also persists the full hitmap, floor tiles, fixture origins, stock,
dirt and active visitor routes. Its validator requires the exact union shape;
turning the 30 outside cells into floor would invalidate the saved expansion
contract. Left expansion translates existing fixture origins, floor styles and
dirt by +5 x exactly once. IDs, rotations, stock references and prices persist.

## Placement and movement constraints

Expansion requires preparing phase, three completed repairs, enough cash and
the $60 recoverable-capital rule. Every original connection cell must be free
of fixtures, including nonblocking rugs or mounted artwork. At least one
connection must be reachable from the entrance before purchase.

Placement uses the saved hitmap and occupied furniture footprints. Shelves,
clocks and paintings require a common adjacent wall across their footprint.
World chooses the actual wall for mounting, with rotation choosing among
available walls at corners. A visual replacement must preserve actual wall
planes at these cells; it cannot draw a wall through the shared passage.

ShopAccess uses cardinal BFS on inside cells without static blockers or
walk-blocking furniture. Wall adjacency is mounting metadata, not an edge that
blocks BFS. Furniture in either room must remain accessible from the same
entrance. Saved living visitors contain their exact browse and exit paths;
presentation may reproject them but must not silently regenerate or teleport
their positions or outcomes. This also matters when opening an expanded save
in the middle of a trading day.

## Recommended presentation boundary

Use an integrated architectural alcove with a generous five-cell opening,
a floor-level threshold and structural framing outside the traversable span.
Choose one perspective, wall thickness, plinth, tile scale and light treatment
for the whole building. Prepare a complete expanded composition per orientation
instead of overlapping independently drawn room plates and covering the old
wall with a floor patch. Preserve the original unexpanded artwork and history.

The underlying 11 + 5 layout, entrance, occupied cells and coordinates can remain
unchanged. A broad lintel or arch is visual overhead structure; its end posts
must not occupy or falsely obstruct walkable cells. The annex remains usable
for shelving and decorations along its saved exterior walls. A continuous
floor must also align with user-painted tiles and saved dirt.

Presentation-only alternatives include reframing the camera around the new
alcove or focusing between the two areas of the same world. These are camera
choices, not permission to change coordinates or the customer's route. An
extra view/navigation flow would require App coordination and visual validation.

A genuinely larger rectangular shop, relocated room, narrow door, stairs, new
floor level, new entrance or blocked passage changes geometry or route semantics.
It needs an explicit migration and treatment of existing furniture, flooring,
dirt and mid-day routes; it is not part of a no-migration visual correction.
Decorative floor must not imply that the 30 outside cells are buildable.

## Why the current visual is fragile

ShopScene.addAnnex composes a separate annex sprite, a floor crop and a second
narrow floor crop over the original shared wall. makeProjectedAnnex derives an
8 x 8 warp from independent source landmarks; makeMatchingFloor stretches a
sample from RepairedShopBackground through a 16 x 16 warp. A side expansion
scales the starter to 0.84 and offsets the camera toward the new room.

The captured left/right joins retain hard lighting and tile transitions. The
rear capture reads as a strip laid over the old back wall. These observations
come from archived native screenshots, not a new simulator run:
design/runtime/0.4/a701788/freeplay-runtime.png and the right/rear captures under
design/runtime/0.2/4087139. A more convincing wall junction requires coherent
architecture and source composition, not another shade adjustment at the seam.

## Regression coverage and verification

The existing RestorationTests testAllExpansionDirectionsPreserveWorldStockIdentityAndCreateReachableCompactRoom
already covers all three directions, fixture and stock identity, custom floor
style, 146/30 inside/outside counts, entrance, path to annex furniture, sale and
JSON roundtrip. It is extended in place with:

- saved dirt preservation and the correct translation in every orientation;
- reachability of all five inner/annex connection pairs and outer-wall cells;
- absence of mounting walls across every connection;
- presence of the correct mounting wall along the opposite annex edge.

This avoids duplicating the existing roundtrip/journey tests. No new XCTest
method or Xcode project entry is needed.

Complementary existing tests cover void placement, forbidden wall mounting at
the shared opening, allowed mounting at an exterior annex wall, obstruction
before expansion, malformed expanded shape rejection, floor/dirt left shift,
normal four-day restoration with FileGameStateStore relaunch, and chunked
living-day determinism. Those remain unchanged.

Windows can check source structure and whitespace, not execute Swift.
Authoritative XCTest/build validation belongs to root's macOS CI. New native
captures must cover all directions, an occupied annex, each exterior mounting
wall, user-painted tiles crossing the join, dirt, and a visitor crossing the
full opening. Test taps and drags after camera pan/zoom and panel lift. A single
empty-room screenshot cannot establish correct hit mapping or old-save behavior.

Handoff verification: scripts/verify-static.ps1 PASS (118 XCTest methods declared,
0.4.1 build 1); git diff --check clean for the changed test. This is not an
executed Swift/XCTest result. No production Core file was modified.
