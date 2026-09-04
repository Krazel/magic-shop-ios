# Restoration domain — playable completion arc

Owner direction: 2026-09-05. This extends the approved commerce loop with a small,
finite restoration objective and continued sandbox play. All rules remain in
Foundation; no accounts, real-world clock, monetization or dependencies are used.

## Integration contract

- `GameState.calendar` exposes `dayNumber`, `weekday`, `weekdayName`,
  `minutesSinceMidnight` and `timeText`.
- `GameState.restoration` contains `repairedGroups`, optional `expansion`
  and optional permanent `completion`.
- `GameState.restorationProgress` reports repaired-group count, placed decoration
  variety, successful trading days, expansion status and `isComplete`.
- `GameState.hasCompletedRestoration` indicates the permanently earned ending,
  even after decorations are moved or sold.
- `GameEngine.validateRepair(_:)` is a side-effect-free quote check.
  `repair(_:)` confirms, deducts the price and clears that blocker group.
- `GameEngine.validateExpansion(toward:)` checks the proposed direction.
  `expandShop(toward:)` confirms one room and charges $250.
- Decorations use the existing placement draft, confirmation, movement and
  empty-fixture resale commands. They have no stock slots.
- Every command is still committed through `GameSession`; failed validation or
  failed disk persistence must leave the live state untouched.

## Fictional shop hours

Day 1 is Monday. Preparation remains at 09:00 and has no timer. Opening preserves
09:00; the six existing visitor transactions advance time by 90 minutes each.
Visit arrival labels are 09:00, 10:30, 12:00, 13:30, 15:00 and 16:30. After the
sixth visitor, the summary shows 18:00. Acknowledging it starts the next weekday
at 09:00. The calendar is derived from the persisted day and visitor cursor,
so relaunching cannot skip time, replay sales or create offline earnings.

## Repairs and sustainable capital

| Group | Confirmation cost | Effect |
| --- | ---: | --- |
| Clear Rubble | $40 | Clears every repairable rubble cell. |
| Repair Floorboards | $60 | Clears every broken-boards cell. |
| Tidy Papers | $25 | Clears every discarded-papers cell. |

The two permanent front columns are never cleared. Repairing twice fails without
spending. Repairs and expansion are available only while preparing.

The irreversible total is $375: $125 repairs plus $250 expansion. From the
original $500 this leaves $125 of recoverable capital even if the player makes
all permanent improvements before trading. Furniture and decorations resell for
their fixed catalog purchase price; stock returns its recorded acquisition
cost. This supports buying a $50 table and $10 unit without resetting or gifts.

## Decoration catalog

Each object reserves one 1x1 placement cell and has zero stock capacity. All can
be moved without spending or resold for their purchase price. A passable object
still reserves its placement cell: furniture cannot overlap it.

| Kind | Runtime asset | Price | Placement | Customer walking |
| --- | --- | ---: | --- | --- |
| `pottedFern` | `PottedFern` | $35 | Floor | Blocks |
| `starRug` | `StarRug` | $45 | Floor | Passable |
| `crystalDisplay` | `CrystalDisplay` | $60 | Floor | Blocks |
| `wallClock` | `WallClock` | $100 | Wall-adjacent | Passable |
| `moonPainting` | `MoonPainting` | $75 | Wall-adjacent | Passable |
| `brassLantern` | `BrassLantern` | $55 | Floor | Blocks |

`FixtureCatalog.decor` holds these six; `FixtureCatalog.all` combines displays
and decor. `FixtureCategory.isAvailable` enables decor while preserving the
historical `isAvailableInFirstSlice` API for the original two-category cut.

## One compact expansion

All three repairs must be finished. Only one expansion can be bought. Its
five-cell connection must be clear of fixtures and reachable from the entrance.
A blocked connection fails without charging; moving furniture resolves it.

| Direction | Bounding layout | Original-shop origin | New 5x5-room origin |
| --- | --- | --- | --- |
| Left | 16x11 | (5,0) | (0,3) |
| Right | 16x11 | (0,0) | (11,3) |
| Rear | 11x16 | (0,0) | (3,11) |

The actual floor is the union of the original 121 cells and 25 new cells.
The bounding rectangle also stores 30 `WorldCellZone.outside` cells, which
cannot be placed on or traversed. Exterior wall metadata follows the union;
the five-cell shared side becomes the open connection.

Only left expansion translates existing fixture origins, floor tiles, entrance
and hitmap by +5 on x. Fixture UUIDs, stock slots, sale receipts and floor styles
remain intact. `GameEngine.layout` reads the current persisted map so placement
does not retain the original bounds after expansion.

## Completion and continued play

The ending is earned when all three repairs are done, the expansion exists,
three distinct decoration kinds are placed, and three acknowledged trading days
have made at least one sale each. Completing the final requirement records
`RestorationCompletion.completedOnDay` exactly once. It gives no repeatable
money and never disables construction, stock, trading, movement or resale.

A tested route starts with $500, buys one table and one shelf, trades one charm,
one potion and one spellbook per day for three days, completes all permanent
work and places three inexpensive decorations. The route ends with $30 and
a permanent completion record. Reversible decoration investment allows further
stock purchases and sandbox trading.

## Persistence and migration

Schema 4 requires the restoration object in addition to all schema-3 fields.
Schemas 1–3 retain their shop name, balance, fixtures, stock, journal and history
where those fields existed. Schema 1 receives its historical starter world;
schema 2 and later require their persisted world. Future schemas are rejected.

The calibrated starter blockers are rubble (1,5), boards (9,5) and papers (9,2).
Legacy blockers at (1,4), (9,4) and (8,2) move only if their destination is free
of saved furniture and another blocker. Otherwise that legacy blocker remains
in its original cell until repaired. Repairs search by blocker group rather
than assuming one coordinate. No saved furniture is overwritten or displaced.

Legacy worlds with an already absent repair group infer that completed repair
without charging again. Current-schema validation rejects completed repairs
with remaining blockers, incorrect expansion shape, fixtures in outside cells
and impossible permanent completion records.

## Verification boundary

`MagicShopTests/RestorationTests.swift` covers simulated hours, weekday rollover,
repair confirmation and repeat rejection, six decorations and traversal, all
three expansion directions, stock and floor preservation, reachable customer
sales in the annex, the full $500 completion route, sandbox continuation and
legacy/corrupt-save behavior. Existing commerce and migration tests continue
to run. Windows static checks do not claim Swift compilation or executed XCTest;
the root coordinator runs authoritative macOS CI.
