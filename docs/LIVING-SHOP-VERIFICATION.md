# Living shop 0.3 (1) — verified local candidate

Completed on 2026-09-05. Final app source: `6474cab768d53a6deac669a123a2da689933c21f`.
The owner requested direct furniture manipulation, floor choices, manual cleaning,
recurring dirt, naturally overlapping visitors and player prices versus the market.
The previous 0.2 candidate, references and evidence remain preserved.

## Playable behavior

- Hold a fixture for 0.18 seconds, drag and release to move it without cost or lost
  stock. Invalid/cancelled drops restore its saved placement. New furniture remains
  an unpaid preview until Place is pressed.
- Sweep each initial worn area in three separate gestures. Footfall produces
  persistent dirt during opening hours, which can be cleaned manually while open.
  There is no absence penalty or offline dirt generation.
- Terracotta, Oak and Checkered floors cost $1/$2/$3 per changed tile. Drag stages
  a preview; Apply Floor commits the batch atomically. The same material is free
  to retain. Cosmetic spending preserves recoverable table-and-stock capital.
- Twelve irregular arrivals overlap, with at most four visitors present. Each
  browses two or three available displays (one if only one exists), with individual
  preferences, budgets and buying intent. Visitors may leave empty-handed; two
  visitors cannot buy the same physical item.
- Prices range from stock cost to three times market price. Estimated interest
  reflects price appeal conditional on product interest, budget and available stock;
  it does not promise that percentage of all arrivals will buy. For a potion at
  $30 versus $25 market, the comparison is +20% and estimated interest is 65%.
  Restocking, returning stock, pricing and sweeping remain available while open.
- Days run 09:00–18:00, about 60 seconds at 1× or 30 at 2×. Pausing/backgrounding
  stops progression. Schema 5 preserves earlier saves; an active legacy day ends
  under its original six-visitor rules before the next day uses the new simulation.
- Six decorations, three initial repairs, the chosen 5×5 neighboring room,
  restoration objectives and free play after completion remain available.

## Executed verification

| Evidence | Result and scope |
| --- | --- |
| [Domain/model CI](https://github.com/Krazel/magic-shop-ios/actions/runs/33979280414) | Release simulator PASS; all 109 domain/model tests PASS. The original run had 114 total passes and three UI accessibility-target failures. |
| [Native interaction CI](https://github.com/Krazel/magic-shop-ios/actions/runs/33980579266) | SUCCESS; Release simulator and all eight UI tests PASS, zero failures or skips, after exposing the projected world elements through a UIView host containing SKView. |
| [Final floor presentation](https://github.com/Krazel/magic-shop-ios/actions/runs/33981373681) | SUCCESS on final source; Release simulator and three normal/compact/accessibility captures. Tests intentionally not repeated for this isolated presentation adjustment. |
| [Final iPhoneOS IPA](https://github.com/Krazel/magic-shop-ios/actions/runs/33981375796) | SUCCESS on exact final source; unsigned arm64 IPA, version 0.3, build 1, minimum iOS 16.0. |
| Windows static verification | PASS: 17 Core sources, 109 domain/model methods declared, original asset hashes preserved and four living-shop assets identical to their archived sources. |

`git diff --exit-code dcfb4498cd10e7bfa5ee973df221472be5c28161 6474cab768d53a6deac669a123a2da689933c21f -- MagicShop/Core MagicShop/App/AppModel.swift MagicShopTests`
passes: the domain/model code and tests did not change after their successful run.
Only accessibility floor-card layout and focused capture configuration changed
after the eight passing UI tests. This is 117 distinct passing cases across the
two test runs, not a claim that all 117 ran on the final source.
Original summaries and precise coverage boundaries are archived in
`design/runtime/0.3/coverage.json` and its companion summaries.

Native UI tests exercise onboarding/build/stock/open/pause/2×/next day; large-text
stock purchase and price saving; restoration journal; actual furniture long-press
drag; floor preview with no charge followed by exactly $4 for two Oak tiles; three
separate cleaning strokes; and overlapping visitors with stocking/cleaning available.

## Visual review

The director selected three complete references before implementing the new UI,
under the owner's explicit delegation. This does not claim that the owner
individually reviewed these new images. Canonical masters, hashes and provenance
are retained in `design/APPROVALS.md` and `design/proposals/living-shop/`.

Real iPhone 16 Pro and compact iPhone SE simulator screenshots show bounded
teal/gold panels, existing room art, product sprites and projected floor materials.
The Open capture visibly contains three independent visitors. Manual repair
attachments show rubble disappearing after three strokes while other targets remain.
Floor previews retain the gold boundary; applied tiles follow the room projection.
Pricing preserves the actual pending/saved price in a fixed footer when large text
requires scrolling. The final accessibility floor carousel shows full material
names/prices; normal and compact layouts retain three cards. Camera space remains
visible above Care, and Apply controls stay within the panel.

`design/runtime/0.3/current-manifest.json` records 20 current images and 23 preserved
images with hashes, canvases, devices, source commits and runs. The three earlier
floor captures remain historical; final floor captures supersede them. Seven
native test attachments are included. The 0.2 archive remains separate and intact.
Review is qualitative against the masters: native safe areas, scrollable large text,
real inventory and the computed interest percentage adapt the illustrated layout.
No pixel-identical claim is made.

## IPA delivery

- App source: `6474cab768d53a6deac669a123a2da689933c21f`.
- Version/build: `0.3 (1)`; iPhoneOS arm64, minimum iOS `16.0`.
- File: `outputs/ci/33981375796/MagicShop-0.3-build-1-6474cab768d53a6deac669a123a2da689933c21f-Sideloadly/MagicShop-0.3-build-1-unsigned.ipa`.
- Size: `37918980` bytes.
- SHA-256: `dcabdefbed8960e07507e2c0838795faa64c6c0924a55260d3cec16474a4a2a5`.
- `scripts/verify-ipa.py` PASS: checksum, manifest commit, version/build, platform,
  deployment target and Mach-O architecture. Record: `design/runtime/0.3/ipa-verification.json`.

The IPA is unsigned and must be re-signed by Sideloadly before installation.
No physical-device installation, hardware performance measurement or auditory
VoiceOver session is claimed. The app remains offline and English-only, without
new SDKs, accounts, tracking, payments or a TestFlight/App Store submission.
