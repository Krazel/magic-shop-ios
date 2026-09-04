# Magic Shop — Commerce v1 visual proposals

Prepared: 2026-09-04.
Status: **PROPOSED — NOT APPROVED**.
Scope: three complete English iPhone portrait mockups extending the existing visual family. These are generated design images, not app screenshots, final sprites, runtime assets or a fidelity pass.
Tool: built-in ImageGen only; no CLI/API fallback.
Working boundary: only this proposal directory was written. No approved images, runtime assets, app code, shared project docs, Git state or Brain record was changed by the visual subtask.

## Selected deliverables

All three selected files are RGB PNG, 853 × 1844 pixels, portrait, English.

| Screen and represented state | Selected image | SHA-256 | Prompt record |
| --- | --- | --- | --- |
| STOCK; one empty table slot; Glow Potion selected before confirmation | [01-stock-v1.png](01-stock-v1.png) | `1A8B322FB60558034866E76A72E502423DFA29355D2D1B02670149F643922ACF` | [01-stock-prompt.txt](01-stock-prompt.txt) |
| OPEN; Day 1 after the first of three automatic sales | [02-open-v1.png](02-open-v1.png) | `68C77294B3F31E5B396E1535049DD6E03283403DF82B35EE9730C52D459FC9C4` | [02-open-prompt.txt](02-open-prompt.txt) |
| Day complete; Day 1 sold out, ready to prepare Day 2 | [03-day-complete-v1.png](03-day-complete-v1.png) | `1EF68E66FEE8787BC8EDD541A3C20C2F865D83001BF0B1FAB92AF2D136E65617` | [03-day-complete-prompt.txt](03-day-complete-prompt.txt) |

Approval date: none. Runtime comparison: none. The project brain must present these proposals to the owner before final UI or new final sprite production.

## Product intent and boundary

The commerce extension closes BUILD → STOCK → OPEN: place compatible furniture, deliberately buy one unit into each chosen slot, watch customers purchase automatically, then reinvest. The minimum presentation keeps the shop itself visible and uses the approved dark teal, gold and parchment overlay language. No new location or meta screen is introduced.

No ads, IAP, account, tracking, analytics, settings, repair/expansion UI or commercial prompt appears. Future repair, decor and expansion are outside this visual package.

## Exact example states

### STOCK is an independent early tutorial example

- Starting cash $500; one Basic Display Table purchased for $50; HUD cash is $450.
- Selected fixture: Basic Display Table, slot 1 of 1, empty.
- Glow Potion selection is a preview. The table remains empty and cash stays $450 until successful confirmation.
- Primary copy: `Stock for $10`. Successful confirmation would leave $440, not $425.
- Cancel spends nothing.
- This image is not the immediately preceding frame of the pictured OPEN example.

### OPEN and Day complete share one coherent Day 1

- Initial cash: $500.
- Buy one $50 Basic Display Table and one $150 Simple Shelf: $300 remains; three total stock slots.
- Buy two Glow Potions at $10 each into the two shelf slots, and one Lucky Charm at $20 into the table: $40 stock cost, $260 remains.
- OPEN frame: the first Glow Potion has sold for $25. Cash $285; `1 of 3 items sold`; upper shelf compartment empty; one potion remains in the lower compartment; charm remains on the table.
- End frame: both potions and the charm sold. Sales $25 + $25 + $45 = $95; stock cost $10 + $10 + $20 = $40; profit $55; cash $260 + $95 = $355.
- The shelf and table remain owned and empty after the day.
- `Prepare Day 2` returns to preparation rather than opening a new day automatically.
- This sold-out example has equal purchased-stock cost and cost of goods sold; it does not decide accounting for unsold items in other scenarios.

## Merchandise and compatibility

| Product | Buy | Sell | Compatible furniture | Proposed appearance |
| --- | ---: | ---: | --- | --- |
| Glow Potion | $10 | $25 | Table or shelf | Corked round bottle, softly glowing cyan contents |
| Lucky Charm | $20 | $45 | Table only | Gold round clover amulet with green ribbon |
| Pocket Spellbook | $30 | $70 | Shelf only | Small purple leather book with restrained gold detail |

One unit occupies one slot. The Basic Display Table has one slot; Simple Shelf has two independently selected slots. The proposed STOCK image includes the incompatible book row in a subdued state with `Shelf only`, to explain the other furniture's role. It must be unselectable while a table is selected. A native accessibility label must explain the incompatibility; color alone cannot carry it.

## Screen and state inventory

The three PNGs cover the normal selection, running day and sold-out summary. The following are content/behavior specifications, not additional approved layouts:

| State | Minimal text / behavior | Visual handling proposed for later approval |
| --- | --- | --- |
| No fixtures | `Build a table or shelf to stock your shop.` / `Go to Build` | Same Stock panel; no empty product purchase action |
| No selected fixture | `Choose a table or shelf.` | Keep panel legible and invite tapping a fixture; no charge |
| Table empty | `Slot 1 of 1 · Empty` | Represented in selected Stock PNG |
| Shelf slot selection | `Slot 1 of 2`, `Slot 2 of 2` | Two distinct touch targets with text and occupancy; no final layout yet |
| Occupied slot | Product name; `Already stocked` | Cannot buy a duplicate into that slot; no implied refund/removal UI |
| All slots full | `Ready to open` | Clear path to OPEN; no additional store or queue |
| Insufficient cash | `You need $10 to stock this item.` for a $10 item | Inline reason near the disabled confirm button; balance unchanged |
| Incompatible product | `Table only` or `Shelf only` | Disabled row, explanatory label and VoiceOver state |
| No stock when opening | `Stock at least one item before opening.` / `Go to Stock` | Reuse the established panel family; final state image still required |
| Day running | `Day 1`, `Shop open`, `1 of 3 items sold` | Represented in OPEN PNG; preparation controls disabled |
| Sold out / day complete | Sales, stock cost, profit, `Prepare Day 2` | Represented in Day complete PNG |
| Persistence failure | Explain save failure without spending or losing inventory | Native error presentation needs explicit visual coverage if materially new |

Any materially different layout or state remains subject to the owner's visual gate. Naming a state here does not authorize its final UI.

## Source references and preservation

These existing files were inspected and used as local ImageGen inputs, never modified:

| Role | Existing file | SHA-256 |
| --- | --- | --- |
| Governing runtime environment plate | `design/assets/first-slice/starter-shop-background.png` | `CBB8A68B876CF8B1EBF9D0FD64A3672195594B6271BD9DA342FC29A7DDF073B3` |
| Approved UI family, furniture and catalog treatment | `design/approved/first-slice-build-catalog-v3.png` | `49E25DEA9F007151C559C450BDD0994ECBCE61D7683C658DF753433F1F42964E` |
| Approved overview, HUD and navigation | `design/approved/starter-shop-overview.png` | `F109DED9C96B1DDFD5B64039A86526AD7593ABC8F874C7385FD211FCE09F3006` |

The approved runtime plate remains the exact runtime environment. None of these flattened proposal images may replace it. The invisible persistent 11×11 hitmap is unchanged and must never be drawn over these scenes.

## Visual assessment and honest deviations

Accepted as proposals for review:

- All three retain the elevated 2D cutaway, compact square shop, teal/cream/terracotta materials, original worn atmosphere, central lamp, debris, symmetrical front windows and centered door.
- HUD names/balances and the BUILD/STOCK/OPEN navigation remain present.
- Critical English strings and prices were visually inspected. The represented accounting is correct.
- A first Stock output made the table too large; the selected revision reduces it to approximately one tile width.
- A first OPEN output made customers and the table too large; the selected revision reduces customers to approximately 60 pixels tall and the table to approximately one tile wide. The two-cell shelf remains against the back wall.
- The OPEN correction also replaced an incorrect horseshoe with the proposed round Lucky Charm.

Remaining differences and limitations:

- ImageGen reproduced the environment from references; it did **not** preserve identical pixels. Some floor, crack, debris and material microdetails drift. This is not a 1:1 comparison pass and does not authorize redrawing the runtime scene.
- The Stock composition raises the visible room to make space for its bottom panel. Approximate back-wall top y: 60 px in Stock versus 405 px in the source plate. This is a proposed framing change, not a new floor geometry.
- OPEN keeps a near-overview framing; approximate back-wall top y: 375 px, about 30 px above the source plate. The horizontal room span is visually similar, but no exact zoom calibration was performed.
- The selected Day complete image raises the room relative to OPEN; approximate back-wall top y: 204 px, around 171 px above OPEN. This difference must be handled as a documented camera offset or corrected with native overlays over the exact runtime plate if the owner approves the UI.
- Those offsets are approximate visual observations on the 853×1844 image, not recovered SpriteKit camera parameters. The implementation must retain the current approved camera angle and map geometry; it must not infer a new hitmap or rescale furniture footprints from generated floor tiles.
- Product illustrations and customers are concepts. They are not separately extracted, approved, rigged or animated assets.
- The subdued incompatible book row still needs strong native disabled semantics and sufficient contrast.
- The PNGs do not prove safe areas, native text wrapping, Dynamic Type, VoiceOver, reduced motion, gestures or accessibility tap sizes.
- Attempting to shift the Day complete world back to the OPEN position caused the generator to move UI and crop the bottom navigation. That experiment was rejected. The selected file is the earlier complete screenshot; the failed output remains only in ImageGen provenance, never a current proposal.

## Assets to prepare only after approval

Reuse the exact existing environment plate, table and shelf assets. Keep HUD, panel frames, prices, product text, tabs, progress and selection rendering native, in the approved family.

New source artwork needed for faithful implementation after approval:

1. Glow Potion icon and tiny world sprite with transparent alpha.
2. Lucky Charm icon and tiny world sprite with transparent alpha.
3. Pocket Spellbook icon and tiny world sprite with transparent alpha.
4. Two restrained adult customer appearances at world scale, with the minimum directional/walking states needed by the agreed automatic-day behavior.
5. Small stock anchors for the existing table and each existing shelf compartment, kept separate from fixture appearance.
6. Native short sale feedback and day-progress state, with reduced-motion behavior and accessible status text.

Do not package these flattened PNGs as app UI or store screenshots. Final comparison requires a real app capture at the same device/canvas and an explicit list of remaining differences.

## Generation provenance

Built-in ImageGen output folder:
`C:/Users/dmkra/.codex/generated_images/01a06e65-3852-7053-a87d-2c481f877daf/`

| Pass | Generated file | Selection |
| --- | --- | --- |
| Stock initial | `exec-75501f11-64d0-4507-ab1f-c0db6801a83d.png` | Replaced by scale correction; original remains preserved |
| Stock correction | `exec-3566ff12-11ac-4db6-a1f7-885776ba2708.png` | Selected as 01-stock-v1.png |
| OPEN initial | `exec-cf096a56-4d41-4690-94a5-404d5b3902c5.png` | Replaced by scale/stock correction; original remains preserved |
| OPEN correction | `exec-bdb67693-15d6-4a52-a67c-aa902d3870b4.png` | Selected as 02-open-v1.png |
| Day complete initial | `exec-ad3aa71f-abda-4750-b1ab-f1a3e95d8ed2.png` | Selected as 03-day-complete-v1.png |
| Day complete registration experiment | `exec-af8b1ef6-6ce8-48a1-a097-988d1c58f068.png` | Rejected because navigation was cropped; not copied as a proposal |

All selected deliverables are copied into this repository, independent of the default ImageGen folder. The prompt files preserve the full generation prompts and correction instructions.

## Next action

Project brain reviews the three selected images and presents one concrete approval gate to the owner: approve this Stock/Open/Day complete family, or request a focused visual correction. Until explicit approval, continue domain, persistence, tests and architecture only. Do not promote these proposals to `design/approved/` or implement their final UI.
