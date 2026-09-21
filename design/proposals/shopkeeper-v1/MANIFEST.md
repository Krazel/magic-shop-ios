# Shopkeeper 0.4 visual direction

Selected on 2026-09-21 by the project director under the owner's explicit authorization for autonomous design. The owner did not individually review these images; this record does not claim otherwise. Built-in ImageGen produced three full-screen files across two states. No app code, runtime image or imageset was changed by this work.

## Current complete-screen specifications

| State | Selected proposal | Canonical master | Canvas | SHA-256 |
| --- | --- | --- | --- | --- |
| Preparing; restore one more worn area | [Preparation v1](preparation-v1.png) | [Shopkeeper preparation v1](../../approved/shopkeeper-preparation-v1.png) | 851×1849 | `9DBA62373730D37263D2E3527DDDEEA50003D030D1DEFF083738DB747E537EBF` |
| Day 3 closed; six sales and product margins | [Summary v2](summary-v2.png) | [Shopkeeper summary v1](../../approved/shopkeeper-summary-v1.png) | 851×1848 | `C01884FE990F4FFC3CFDE3AA926834C074E97B2997CBC42AA44256D7D9345F8A` |

English iPhone portrait. Requested reference canvas: 1206×2622; actual built-in output sizes appear above. [Summary v1](summary-v1.png) is a historical proposal, superseded before selection by v2's explicit margin captions and factual interest copy. It is not the current reference.

Exact prompts are preserved in [preparation-v1-prompt.txt](preparation-v1-prompt.txt), [summary-v1-prompt.txt](summary-v1-prompt.txt), and [summary-v2-prompt.txt](summary-v2-prompt.txt). See [manifest.json](manifest.json) for hashes and provenance.

## Scope and native rendering

The masters add a next-objective hint and useful daily sales breakdown to the existing 0.3 game. They do not authorize restaging the room, enlarging sprites, replacing world geometry or flattening a mockup into the app. The existing floor, walls, facade, fixtures, ornamented surfaces, shop-name/balance HUD and BUILD/STOCK/OPEN navigation govern.

Preparation is an edit of [0.3 drag runtime](../../runtime/0.3/0b99f37/drag-runtime.png). The example removes the left rubble pile to illustrate one completed repair; boards and papers remain. The small panel sits immediately above navigation, covers part of the facade and leaves the playable floor visible. Heading: “Next little step”; progress: “Restore the room · 1/3”; instruction: “Clear another worn area to make space for displays.”; CTA: “Care for the shop”. Secondary actions: Arrange, Prices, Care. Copy and counts are driven by the next actual objective. Completed restoration must lead to useful freeplay guidance, never a false incomplete checklist.

Summary builds on [0.2 native summary](../../runtime/0.2/4087139/summary-runtime.png); 0.3 retained that panel family. Title/day sit above scrollable financial and product content; “Prepare Day 4” remains outside the scroll area and fully visible. Product rows use icon, name and “N sold · $M margin”. Margin means total sale revenue minus cost of those units, in dollars, not a percentage. Inventory purchases for unsold goods, fixture costs and repair costs are not included in product margin.

The example is arithmetically coherent: three $25/$10 potions yield $45 margin; two $45/$20 charms yield $50; one $70/$30 book yields $40. Units 6, revenue $235, cost of goods $100, profit $135. Balances and the separate preparation example are illustrative, not a transaction fixture or hardcoded UI.

Tomorrow uses the director's evidence-based copy: “5 visitors came looking for Glow Potion. Try keeping some on display tomorrow.” This refers to recorded requestedProduct observations. It does not mean five lost sales, unmet orders, or a proven price/stock cause. Runtime numbers, days and advice come from persisted Core data. Empty/legacy records must not manufacture this evidence; use a neutral useful message instead.

## Existing asset inventory

No new runtime bitmap is required.

- World: existing StarterShopBackground, RepairedShopBackground and local repair patches. Existing room projection and camera remain authoritative.
- Main panel: existing [OrnatePanel.png](../../assets/complete-game/OrnatePanel.png), bounded by the native helper; preparation and HUD use the already established contained teal surfaces and thin gold outlines.
- Products: existing [GlowPotion.png](../../assets/complete-game/GlowPotion.png), [LuckyCharm.png](../../assets/complete-game/LuckyCharm.png), [PocketSpellbook.png](../../assets/complete-game/PocketSpellbook.png).
- SF Symbols/native text supply sparkle, moon, journal, navigation and controls. Preserve existing GoldButtonStyle and native safe areas.

## Accessibility and verification targets

- Preparation: current objective, current progress and main CTA remain discoverable at compact size and accessibility text. Supporting copy may wrap; secondary actions may adapt, without compressing touch targets below 44 points. Do not shrink all text to preserve the exact raster line breaks.
- Summary: one bounded panel; content scrolls, footer stays fixed. At compact/AX sizes, product names and margin captions can wrap. All totals and rows remain reachable; neither half-circles nor half-rows are accidental fixed clipping. Prepare next day remains fully visible. Gold decoration never overlaps text or intercepts input.
- Calendar: preserve the current HUD. The separate authorized open-state pause control belongs in CalendarBar and remains available while managing the shop; it is not drawn on these preparing/closed masters because time is already stopped.
- Existing Care accessibility correction: show repair progress cards before long gesture instructions. In [Care large type](../../runtime/0.3/0b99f37/care-large-text-runtime.png), the instruction consumes the initial viewport and hides all three counters. Target: current group and n/3 visible without scrolling after a sweep.
- Existing Pricing compact correction: move the whole minus/value/plus stepper to the fixed footer above Apply, leaving cost/market/interest scrollable. [Current compact Pricing](../../runtime/0.3/0b99f37/pricing-compact-runtime.png) clips the lower part of the stepper at rest. Target: complete 44-point or larger controls visible after opening and saving.
- Verify a normal iPhone, compact iPhone SE and accessibility Dynamic Type using actual runtime captures. Validate text/CTA reachability and VoiceOver order separately; images are not evidence of runtime behavior.

## Fidelity assessment and known differences

The output retains the approved palette, shop silhouette, camera family, small furniture, native-style HUD and navigation, and bounded gold/teal panel. Text and totals were visually inspected. ImageGen subtly resamples wood/stone details and typography; summary v2 shifts the bottom navigation lower and has a tighter home-indicator margin than native safe areas. These are raster synthesis differences, not instructions to change assets or violate safe areas. The native engine, exact existing sprites, real calendar/time and safe-area constraints take precedence over those incidental changes. There is no pixel-equality claim.

The preparation panel occupies about 16% of its generated canvas. The summary frame occupies about 52%; it must adapt with scrolling instead of growing indefinitely. Do not copy this height literally on an SE or accessibility device.

Runtime comparison remains pending implementation. The director should append actual 0.4 screenshot links and measured remaining differences when the candidate exists.

### Director-confirmed native preparation adaptation — 2026-09-21

The director reviewed the preparation master and retained Improve as a fourth secondary action beside Arrange, Prices and Care so expansion/planning stays directly reachable. The runtime may add a short two-line explanation of the three sweeping passes. This is a useful native adaptation of the selected direction, not another visual direction or owner review. At standard sizes, the four actions may share a row; their Dynamic Type ceiling follows the existing navigation's xxxLarge policy. Keep the primary objective and CTA readable, keep touch areas at least 44 points, and expose full accessibility labels. The room interaction area remains visible.
