# Living shop domain — 0.3

Owner-authorized extension, 2026-09-05. Foundation only. No network, dependencies,
real-world timers, absence rewards or monetization.

## State and migration

Schema 5 adds `pricing: [ProductKind: Int]`, `dirt: [GridPoint: Int]`,
`manualRepairProgress: [RestorationGroupID: Int]` and optional
`livingDay: LivingShopDay`. The first three fields are required in schema 5;
missing/null data is rejected. Schemas 1–4 receive market prices, empty dirt and
zero manual progress. Their existing shop, economy, floor, restoration and
journals are preserved. Future schemas are rejected.

A pending six-visitor `currentDay` remains a legacy day after migration and
continues through `advanceDay` / `acknowledgeDaySummary`. It is never replaced
by a new simulation midway. `currentDay` and `livingDay` are mutually exclusive.
`dayHistory` stays one chronological array of `DaySummary`; summaries add
`simulation: .legacy | .living`, optional seed and computed `visitorCount`.
Missing simulation metadata on old summaries means legacy. The old initializer
and six-visitor API remain available for historical saves and tests.

`GameState.calendar` and `completedDays` cover both engines. Preparation is
untimed at 09:00; acknowledgment begins the next day/weekday at 09:00.

## New transaction API

- `openLivingDay(dayID: UUID = UUID(), seed: UInt64? = nil) -> LivingShopDay`
- `advanceLivingDay(expectedDayID: UUID, expectedMinute: Int, toMinute: Int) -> LivingDayAdvance`
- `acknowledgeLivingDaySummary(dayID: UUID) -> DaySummary`
- `setPrice(_ price: Int, for product: ProductKind)`
- `pricingQuote(for product: ProductKind, price: Int? = nil) -> PricingQuote`
- `cleanCell(at: GridPoint) -> CleaningResult`
- `paintFloor(at: GridPoint, style: FloorStyleID) -> Int` (charged amount)

Mutations throw on invalid state, phase, price, position or cursor. App uses
`GameSession.commit`: copy engine, apply command, validate and atomically save
candidate, then publish it. A failed save leaves money, units, routes, minute,
dirt and receipts unchanged. Multiple paint calls inside one session commit
make a whole selected stroke atomic.

An advance accepts only the exact persisted old minute, a matching day UUID,
and a strictly later minute up to 18:00. It evaluates every crossed event,
regardless of presentation chunk size. Repeating a consumed token fails without
repeating dirt or income. The whole candidate is validated before assignment;
there are no throwing partial mutations. App owns pacing and suspension while
backgrounded. Opening and advancing require no clock or system randomness.

## Visitors and world contract

`LivingShopDay` exposes `id`, `dayNumber`, `seed`, `minute`, `visitors`,
`activeVisitors`, `outcomes`, `sales`, `revenue`, `costOfGoods`, `profit`,
`summary`, `isFinished`, `openingBalance` and `inventoryCashFlow`.

Twelve arrivals occur between 09:00 and 17:00 with deterministic irregular gaps
of 16–64 simulated minutes. Visits last 96–115 minutes, shortened when necessary
to leave by 18:00. These windows overlap, with at most four customers present.
Profiles use a fixed integer generator and stored seed; the default seed depends
on day number, never Swift Hasher, wall time or an external random source.

Each `LivingVisitor` has a stable `VisitID`, arrival/departure/decision minutes,
preferred and optional secondary product, budget, buying intent and price roll.
It visits two or three different reachable displays when enough displays exist,
or the one available display in a small shop. A `LivingBrowseStop` stores
`fixtureID`, arrival/departure minutes and its cardinal BFS path. The exit path
returns to the entrance. Paths use the same saved hitmap, blockers and walking
rules as commerce/placement, including annexes and passable decorations.

World reads `visitor.position(at: Double) -> LivingPosition` containing
`from`, `to` and `progress`, and `status(at: Int)`:
`notArrived`, `arriving`, `browsing`, `comparing`, `leaving`, `departed`.
Fractional interpolation is presentation-only. The app must not advance financial
state from SpriteKit positions.

At its final comparison, a visitor can select at most one interested, affordable
item from displays it visited and can reach. It compares price against market
value and prefers its primary interest. Empty displays, insufficient budget,
weak price appeal or a visitor who only browses produce an outcome without a
sale. Visitors competing at the same minute are processed in stable ID-index
order against the already-updated stock. A unit cannot be sold twice.

## Prices and active shop management

Market prices remain $25/$45/$70. The allowed ranges are $10–75 for Glow Potion,
$20–135 for Lucky Charm and $30–210 for Pocket Spellbook. Minimum price is
acquisition cost: the owner's requested below-market pricing does not imply
deliberately selling at a loss. This keeps normal trading recoverable.

`PricingQuote` exposes `price`, `marketPrice`, `cost`, `minimumPrice`,
`maximumPrice`, `estimatedDemandPercent` and `isBelowCost`. Invalid UI previews
are safe to quote but cannot be applied. The estimated percentage is price
appeal **among interested visitors**, before budget, route, stock competition
and browsing-only intent. It is not guaranteed demand or sell-through. It is
75% at market price and decreases as price rises. Secondary interests have
lower willingness. UI must preserve this qualification.

Preparing and a living open day permit stock purchase, stock return, price
changes and cleaning. Legacy open days and either summary block those changes.
Furniture purchase, movement, resale, expansion and flooring remain preparing
only. Existing draft cancellation never spends money or moves a fixture.

Current prices affect future decisions only; historical receipts retain their
actual selling price and stock acquisition cost. `inventoryCashFlow` records
purchases as negative and stock returns as positive. Living balance reconciles
as opening balance + revenue + inventory cash flow; legacy balance rules remain
unchanged. Aggregated historical costs and future candidate additions are
checked for integer overflow before any money/stock mutation.

## Cleaning and flooring

Dirt is a sparse persisted dictionary with levels 1–3; missing means zero.
At most 64 floor cells can be dirty. Customers generate capped footfall marks
while present; no absence or elapsed device time creates dirt. Cleaning one
cell reduces its level by one for free. Clean cells produce no change.

The three initial repair groups now also support three manual strokes each.
Progress values 1/2 persist; the third clears the complete group's blockers,
marks the existing restoration goal complete and removes transient progress.
The legacy paid `repair` command remains for old integrations/tests, but the
new UI uses manual gestures. Nonrepairable columns and outside cells reject
cleaning. Root limits one action per cell per stroke; three passes are distinct
player actions. `GameState.repairProgress(for:)` returns 0–3 for rendering.

`CleaningResult` exposes point, removedDirt, repairGroup, repairProgress,
completedRepair and didChange.

The existing `ShopFloorState` is retained. Paintable styles:

| FloorStyleID | Display name | Cost per changed cell | Texture asset |
| --- | --- | ---: | --- |
| terracotta | Terracotta | $1 | FloorTerracotta |
| warmOak | Warm Oak | $2 | FloorWarmOak |
| checkerStone | Checker Stone | $3 | FloorCheckerStone |

`FloorStyleCatalog.paintable` and `ShopCare.paintableStyles` provide UI choices.
The original `wornTerracotta` and arbitrary legacy floor IDs are preserved.
Painting requires preparing, an inside cell without a static blocker, sufficient
cash and a valid new style. Repainting the same style costs zero. Painting is
allowed beneath furniture; it does not move or remove it.

A cosmetic paint transaction preserves at least $60 of recoverable capital
(cash + furniture resale + recorded stock refunds), enough for one table and
potion. An excessive paint request throws `workingCapitalRequired`. No loan or
reset is introduced. Left expansion translates painted tiles and dirt by the
same five-cell x offset as existing furniture; IDs and levels stay intact.

## Integrity and verification boundary

Decoding validates pricing, sparse dirt/progress, exclusive day modes, global
day/stock identities, history order, visitor timeline and outcome cursors,
walkable/cardinal paths, display references, budgets, concurrency, cash flow and
safe totals. Raw malformed geometry is rejected before coordinate arithmetic.

`LivingShopTests.swift` adds 17 domain tests: seeded plans and overlap, paths,
chunk/relaunch equivalence, competing stock, active prices/restocking/refunds,
conditional demand, failed-save retry, manual repairs, bounded dirt, painting
and batch rollback, capital reserve, phase locks, schema-4 midday migration,
corrupt schema-5 rejection, living restoration-to-sandbox completion, imported
cost overflow, and left-expansion preservation.

Windows verification is static only. Native compilation and XCTest execution
belong to the coordinator's macOS CI on the exact integrated commit.
