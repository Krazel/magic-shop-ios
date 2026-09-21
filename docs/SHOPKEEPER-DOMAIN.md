# Shopkeeper domain — 0.4

Date: 2026-09-21. Scope: economical recovery and truthful existing-day feedback.
Save schema remains 5. No new stored field, dependencies, day model, reward or
price/revenue tuning is introduced.

## Irreversible spending and recovery

Floor paint, room expansion and the retained legacy paid-repair API now use the
same rule: after spending, cash plus refundable fixtures plus stock acquisition
cost must retain at least $60, the cost of a basic table and one glow potion.
ShopCare.minimumRecoverableCapital publishes that common threshold.

This is recoverable capital, not a mandatory cash reserve. A shop with a table
and potion may expand with exactly $250 cash and retain $0 cash: it can trade,
or explicitly return the potion and sell the empty table for $60. Manual
three-stroke repairs remain free. Reapplying an unchanged floor remains free.
Failures occur before mutation; insufficient cash retains its specific error
and insufficient recovery capital uses LivingShopError.workingCapitalRequired.

The check starts at post-spend cash, capped to $60, and caps each added asset
contribution to the missing amount. It never totals arbitrary historic purchase
costs or adds a reserve onto a potentially huge balance. Existing nonnegative
save validation runs before this check. Catalog prices remain fixed and valid.

Regression: starting at $500, paint 80 checker-stone cells for $240, clear the
three repair groups manually, then request the $250 expansion. Previously this
left $10, no furniture or stock, and no way to earn. All three directions now
reject the expansion without changing the $260 state, which can still buy a
table and stock. Paid repairs test the same $59/$60 residual-capital boundary.

The policy does not grant funds to already stranded old saves. It prevents
new irreversible spending from causing that state. Refundable furniture and
inventory purchases retain the existing explicit recovery operations.

## Public product results

DaySummary.productResults: [ProductDayResult] is computed from persisted
outcomes. The value type is Identifiable, Equatable and Sendable, declared
in CommerceModels.swift, and exposes:

- id and product: ProductKind, in the stable three-product catalog order.
- unitsSold, revenue, costOfGoods and computed profit: actual receipts,
  grouped by the product bought, using its historical sale and acquisition costs.
- requestedCount: initial requested product, counting every visitor outcome.

Products with zero sales or requests still receive a row. UI label for the last
metric is **Asked for**. A customer can request a potion and buy a charm, so
requests are not missed sales and must not be subtracted from sold units to
claim a lost opportunity. Existing summaries cannot establish whether a
non-purchase was due to price, budget, stock, routing or browsing-only intent.
Open-day price/restock edits are not retroactive receipt edits.

No computed metrics are encoded; existing legacy and living summaries continue
to decode unchanged. Subgroup sums are bounded by the existing validated,
nonnegative whole-day totals.

## Deterministic restoration journey

testNormalDailySeedsReachRestorationFromFiveHundredAndContinueAfterDiskRelaunch
starts with a genuinely empty $500 shop and uses this ordinary strategy:

1. Clear all three repair groups with three free strokes apiece.
2. Buy one basic table at (4,4), then one shelf at (4,10). Fixture IDs are fixed.
3. Keep market prices. Refill empty slots with one charm on the table and one
   potion plus one spellbook on the shelf. Do not restock during trading.
4. Run three normal days using the default seed for each actual day number,
   with no searched or repeated favorable seed.
5. Buy the right room for $250, then fern/rug/lantern for $35/$45/$55.
6. Run the next normal day in free play.

Every day saves at noon to FileGameStateStore, recreates GameSession, finishes
at 18:00 and compares all state with an uninterrupted run. It reloads the pending
summary before acknowledgement and reloads the completed restoration. It checks
successful days, completion, continued play, 12 outcomes per day, product totals,
schema 5, and both daily and whole-run accounting identities.

The test prints SHOPKEEPER rows containing observed day, units, revenue, stock
cost, profit and cash, plus cash at restoration. Exact visitor receipts and
cash amounts are deliberately not golden assertions; conservation, playable
completion and persistence behavior are the contract.

An independent arithmetic replay of the current deterministic generator predicts:

| Stage | Units sold | Revenue | Cost of sold stock | Profit | Cash |
| --- | ---: | ---: | ---: | ---: | ---: |
| Day 1 | 3 | $140 | $60 | $80 | $380 |
| Day 2 | 3 | $140 | $60 | $80 | $460 |
| Day 3 | 3 | $140 | $60 | $80 | $540 |
| Expansion and three decorations | — | — | — | — | $155 |
| Day 4, continued play | 2 | $70 | $30 | $40 | $165 |

Day 4 is predicted to retain the $30 spellbook. These are arithmetic
expectations, not executed Swift results; the authoritative observations are
the XCTest log from macOS CI. No balance change is justified by this path.

## Verification and limits

Added six meaningful XCTest methods across RestorationTests.swift,
CommerceTests.swift and LivingShopTests.swift: floor/expansion regression,
paid-repair boundary and free fallback, exactly recoverable assets, huge imported
cost overflow safety, honest product grouping and history roundtrip, and the
four-day disk-backed journey.

Windows verification checks source structure and whitespace only. Swift/XCTest
execution and iOS build remain the root task's macOS CI responsibility. UI
presentation, hints, rendering, gestures and AppModel are owned by other lanes.
