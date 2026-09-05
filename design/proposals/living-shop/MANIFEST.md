# Living Shop 0.3 screen masters

Selected by the project director on 2026-09-05 under the owner's explicit delegation of visual decisions. These are generated full-screen specifications, not app captures and not separately owner-reviewed approvals. Existing approved masters and 0.2 runtime screenshots remain untouched.

## Current screen inventory

| Screen/state | Selected image | Actual canvas | SHA-256 |
|---|---|---|---|
| Open, three concurrent browsers | 01-open-living-v2.png | 852×1846 RGB | A7E9A8EFECA4C9D8471828D4BCDC8100603B23D09E62F7676FDA323B1C793EE0 |
| Pricing, Glow Potion edited | 02-pricing-v1.png | 851×1849 RGB | 37D47B6112A67FF8FEEA4737685DD528D69ADD9EF45FC0849B5ACB6D0E1951BC |
| Care / Floor, Oak drag preview | 03-care-floors-v1.png | 851×1849 RGB | D6330129292EE8CC00DBAAFEA72B91F115D079353ED7A65DB2DFC06339707144 |

All are portrait English iPhone screens. Requested canvas1206×2622; built-in ImageGen returned the sizes above. Each exact prompt is stored beside its image as NAME-prompt.txt. Open v1 is preserved history, superseded by v2 because it showed extra shelf/hand potions: 851×1849, SHA64F0FE8B6ED843217DBD8CEDFE24205D4B7564965F5D7DF9388563170B45B4A5.

## Governing references and fidelity

Input1: ../../runtime/0.2/77cbc09/stock-runtime.png, native0.2 HUD, typography, safe areas, gold/teal panel and navigation.
Input2: ../../runtime/0.2/4087139/restored-right-runtime.png, restored square11×11 room and right5×5 annex, painted cream/teal/terracotta architecture and small furniture.

Keep the existing runtime plate, projections, geometry, sprite assets and native statusbar; these new images are never flattened runtime backgrounds. The generated art slightly restages furniture, product scale, lighting and camera framing. Native runtime landmarks and existing sprites remain authoritative for world geometry; the new interaction layout/copy/state inventory is the addition being specified. Preserve safe areas on actual device, even where generation omits the Dynamic Island cutout. No new customer artwork is needed: reuse existing green/plum front/back sprites, mirror where appropriate.

Open: three concurrent miniature customers facing or approaching fixtures, two small parchment response bubbles, a few tiny dust marks, weekday/time and shallow activity panel. V2 now has exactly1potion per shelf slot/2total,1charm on table,1book on table; browsing hands are empty. Its faint dust is a visibility limitation: runtime should show the DustPatch source at restrained but perceptible opacity. Bubble wording/icons and displayed sale count are example visitor states governed by Core; the "$30?" thought need not imply the current default Lucky Charm price. The $355/Day5 balances are illustrative independent saved-state scenes, not a new economy rule.

Pricing: product picker, stock cost$10, market$25, edited own price$30, +/- controls,20%above market, interest meter, Apply Price. Exactly3products total; Lucky Charm$45 and Pocket Spellbook$70 remain defaults. The pictured70%interest is illustrative: runtime must display the real Core estimate, not hardcode70. Changes are pending until Apply Price. Disabled insufficient/invalid states reuse the same controls, retain readable labels and explain the actual Core validation.

Care: compact lower panel, Clean/Floor tabs, material cards Terracotta$1/tile, Oak$2/tile, Checkered$3/tile. Oak selected, four-cell preview and$8sum, Apply Floor. The cost comes from unique eligible cells in the pending preview; no full-room grid. Cleaning uses the same compact panel geometry with Clean selected, a broom cue, "Drag to sweep" instruction and remaining dirt/progress. Recurrent dirt is free to sweep; initial repair groups require3passes according to Core. Gesture dirt specks are transient runtime effects. Do not show an active broom stroke while Floor is selected. Pending floor gesture can be cancelled without purchase. Empty selection/insufficient funds disable Apply and explain the valid state. No forced cleaning penalty, ads, settings, IAP or additional systems are specified here.

## Runtime inventory

Reuse OrnatePanel, original background/repaired plates, furniture, six decorations, GlowPotion/LuckyCharm/PocketSpellbook, existing customers and native icon drawing. New sources and imagesets:
- FloorWarmOak — full-bleed opaque top-down painted planks.
- FloorCheckerStone — full-bleed opaque top-down2×2cream/teal stone pattern.
- DustPatch — byte-identical reuse of the archived first-slice terracotta stain decal with actual alpha.
- FloorTerracotta — subsequently authorized alias of the original WornTerracottaTile, preserved byte-for-byte.

See ../../assets/living-shop/MANIFEST.md and manifest.json for asset hashes, dimensions, prompts and QA. No App/Core/World/code/project/Git edits were made by the art lane.
