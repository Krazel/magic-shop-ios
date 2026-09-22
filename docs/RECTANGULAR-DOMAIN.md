# Rectangular expansion domain — schema 6

Date: 2026-09-22. Baseline: schema 5, app 0.4.1. Target: schema 6 and app 0.5.
The owner rejected the annex and requested moving the complete chosen wall to
make one rectangular shop. Core implements that contract; native verification
remains pending at this handoff.

## Authority and write history

Automatic approval review initially rejected the migration because the explicit
right-side visual request available to it did not authorize changing all saved
geometries. No code changed on that rejected attempt. Root paused the lane and
asked the owner: “¿Autorizas convertir la ampliación en una sala rectangular y
adaptar las partidas guardadas, conservando dinero, mercancía y suelo, y
recolocando únicamente los muebles de las paredes retiradas?”

The owner answered “lo que necesites”. Direction selected all three existing
orientations, and subsequent filesystem review accepted that new evidence.
The owner also approved the three exact visual references separately. This lane
owns Core, domain/model tests and this document only; root/World own integration,
rendering, versioning, CI and the project record.

## Public geometry contract

ExpansionState retains direction, price = 250 and roomSize = 5. Its roomSize
means added thickness, not a separate square room. API additions/changes:

| Direction | Final layout | starterOrigin | roomOrigin | roomFootprint | Entrance |
| --- | --- | --- | --- | --- | --- |
| left | 16 by 11 | (5,0) | (0,0) | 5 by 11 | (10,0) |
| right | 16 by 11 | (0,0) | (11,0) | 5 by 11 | (5,0) |
| rear | 11 by 16 | (0,0) | (0,11) | 11 by 5 | (5,0) |

roomFootprint is a GridFootprint; roomOrigin describes the full added strip.
starterConnectionCells describes all 11 cells of the removed starter wall, in
untranslated starter coordinates. ExpansionDirection.displayName becomes Left,
Right and Back; UI owns verbs and price formatting.

The final hitmap has 176 interior/entrance cells and no outside holes. Wall
adjacency exists only on the four exterior edges. There is no internal doorway,
threshold, mounting plane or step. A new purchase remains preparing-only, once
per shop, after the three repairs, at $250 and with the existing $60 recoverable
capital rule. A cancelled preview or failed transaction changes no state.

Front architectural columns move with the lateral perimeter: the former left
column at (5,0) goes to (0,0) after a left extension; right (10,0) goes to (15,0).
Rear preserves (0,0)/(10,0). There remain two blocked front corners, giving 174
walkable cells before dynamic furniture. Original entrance coordinates remain.

## Schema 4/5 to 6 migration

Schema 4 and 5 expanded saves use the same 176-cell rectangular storage but have
146 interior cells and 30 outside cells. The former annex is left x0...4/y3...7,
right x11...15/y3...7 or rear x3...7/y11...15. Filling those 30 outside cells
completes the rectangle without changing any existing coordinate. A previously
expanded left save must never receive a second +5 x translation.

1. Decode the original version and validate its original shape, wall metadata,
   fixture identities/occupancy, inventory, pricing, money and active journal.
   Do this before normalizing any geometry so a corrupt source is not made valid
   merely by overwriting its malformed cells or paths.
2. Build the candidate rectangle in memory. Preserve all original floor styles,
   including the already stored styles of the 30 formerly outside cells, and all
   dirt keys/levels. Update only zones, perimeter wall adjacency and the moved
   front corner blocker. There is no migration fee, refund or balance change.
3. Reposition only wall-dependent furniture that no longer has a valid common
   wall under its complete footprint. Keep all other origins unchanged. Preserve
   fixture ID, kind, rotation, array order and every stock ID/slot/reference/cost.
4. If movement affects a living itinerary, adapt its paths under the rule below.
5. Validate the complete candidate as schema 6 before making it writable. A
   failed migration must leave the original file untouched and surface a load
   error; never reset to a new $500 shop or drop an obstructing fixture.

Schemas 1–3 keep their existing calibration/default migrations; nonexpanded
schema 4/5 saves keep their world and economy. Reject future schemas, malformed
required fields, duplicate IDs/slots, impossible coordinates and broken routes.
All future writes use schema 6. The current atomic store/session ownership stays.
Loading alone must not overwrite the old file before successful validation.

## Deterministic furniture relocation

A new left purchase translates existing fixtures, floors and dirt by +5 x once.
After that translation, use the same perimeter-placement procedure as migration.
New right/rear purchases do not translate existing floor furniture.

Prefer the original mounting side at the new exterior edge, preserving rotation
and the coordinate parallel to that wall. For example, a rear-mounted shelf at
(x,10) becomes (x,15) when the rear wall moves. If a corner fixture still has a
valid other wall, leave it in place. A free-standing table, rug or plant never
moves merely because it touches the removed wall.

Reserve all fixtures that stay put, the entrance and static blockers first. Pack
remaining wall fixtures by footprint size descending, then stable UUID order.
Candidate positions prefer the same wall side, then shortest Manhattan distance,
then y/x order; consider other valid perimeter positions only when necessary.
Use deterministic backtracking rather than discarding furniture when an earlier
one-cell placement would strand a two-cell shelf. Keep rotation and stock intact.
The result must have no overlap, no entrance blockage and valid wall adjacency.
If no safe arrangement exists, fail before mutation and preserve the source.
A new-purchase packing failure reports expansionConnectionBlocked to the UI; a
failed saved-state migration reports a load validation error and leaves the
original bytes intact. There is no invented storage, refund, deletion or reset.

Each legacy outline has 48 wall-adjacent cells and the rectangle has 50.
There are 12 former boundary cells strictly inside each new rectangle;
that arithmetic is a planning bound, not proof that every crowded arrangement is
handled. The crowded fixture regression covers 45 saved fixtures in each direction,
including two shelves, without dropping or overlapping items.

## Living-day route semantics

Direction chose immediate relocation, with no deferred furniture or temporary
floating wall decor. This is a change to route arrays when geometry requires it,
not a claim that every saved GridPoint in a route can remain identical.

Preserve day ID, seed, day number, opening balance, cash flow, minute/cursor,
visitor IDs, arrival/browse/departure times, preferred/secondary products, budget,
interest, buying intent, stop fixture IDs, all outcomes and receipts. Reconstruct
paths from the same entrance through the same fixture stops and back to the
entrance using the new walkable map. Do not reroll visitors or replay a sale.

The visual visitor position may differ at the first migrated load because its
route changed; no migration animation or visible transition is required. Existing
outcomes and income remain immutable. A save/relaunch/retry of the same minute
must still reject duplicate advancement. Legacy six-visit days retain their
journal and cursor and continue under their existing rules. Where no path or
fixture change is required, preserve the original route arrays.

## Regression coverage added/updated

Coverage lives in RestorationTests.swift, with schema-version assertions updated
in LivingShopTests.swift. No new Xcode target/file registration is required.

- All three new purchases: 176 interior cells, zero outside holes, exact perimeter
  adjacency, all 11 former wall cells open, front columns at the exterior, correct
  entrance, unchanged IDs/stock/styles/dirt and a single $250 charge. Verify
  expanded furniture access, schema 6 roundtrip and rejection of repeat purchase.
- Furniture attached to each removed wall: table remains, shelf/clock/painting
  move deterministically; valid corner items stay; crowded destinations resolve
  without overlap or loss. Repeated loading produces identical results.
- Hand-authored schema 4/5 annex fixtures for all directions, independently built
  from the old 5 by 5 geometry rather than the new expansion helper. Include
  custom floors, dirt, stock, repaired/completed state and wall fixtures on both
  removed starter and former annex edges. Check every preserved field after load.
- Schema 5 living midday with a moved stocked shelf: preserve semantic fields,
  timings, cursor and existing outcomes; assert cardinal walkable paths ending
  next to the same display IDs. Save/relaunch, reject stale minute, finish once
  and compare balance/stock/outcomes with an uninterrupted migrated engine.
- Schema 4 legacy midday: preserve six-visit journal/cursor and continue through
  summary without duplicate income; schema 6 roundtrip remains stable.
- Reject malformed original annex zones/walls, overlapping or duplicate fixtures,
  invalid original browse route, missing schema 6 required fields and future
  schema versions. No malformed source is repaired implicitly by migration.
- Update old tests that assert 146/30 cells, a five-cell opening, blocked expansion
  merely because furniture touches the wall, or hard-coded current schema 5.
  Keep insufficient funds, recovery reserve, phase gates and transaction failure
  assertions. Static script version pins belong to root, not this lane.

## Implementation and verification limits

Changed Core: ShopRestoration.swift (geometry and deterministic packing),
GameState.swift (schema 6, strict original/final expansion validation),
LivingShopDay.swift (conditional path adaptation) and GameEngine.swift (preview
and atomic purchase candidate). No new persisted field or deferred migration
state was introduced; ExpansionState still encodes only its direction.

GameState validates the original annex before it constructs the rectangle.
Living routes are checked against all resulting walkable cells and fixture
endpoints. Any invalid route triggers deterministic re-routing with the same
profiles/times; otherwise every saved route remains unchanged. The file-store
regression verifies that load does not write the source, the next successful
session transaction writes the validated schema 6 state, and corrupt loads leave
the original bytes untouched.

Windows static verification: PASS with 126 declared XCTest methods, app 0.5 (1),
unchanged Core framework separation and verified asset/reference hashes. Scoped
git diff --check is clean. This is not Swift compilation or an XCTest execution.
Read-only independent arithmetic checked 146 old + 30 added = 176 interior cells
per direction. A separate packing model found collision-free layouts for each
45-fixture crowded regression (10/10/11 moved fixtures, 11/11/12 search nodes).
That model is supplementary reasoning, not a substitute for executing Swift.

Native result, 2026-09-22: all 126 domain/model tests passed on source
`67eb7dacaaee3cd6fedebec919f3a4e8f4d5a7d1`, run `35666931133`, iPhone 16 Pro
simulator with iOS 18.5. The complete run had one UI failure before opening Care;
it is not recorded as a passing full suite. Source `aed5e1a` changes only World
painting/framing, SwiftUI shortcut hit areas and the affected UI test; Core,
AppModel and their tests are byte-identical to this successful domain run.

Root owns the macOS build/test/capture run. Native verification must cover new
purchases and legacy migration, all three views, floor painting across former
seams, attached furniture and active visitors. Do not reuse the previous 131
native PASS as evidence for schema 6. A migrated visitor may appear at a different
position at first load, as documented above; there is no revenue replay.
