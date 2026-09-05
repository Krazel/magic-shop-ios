# Magic Shop

A small offline iPhone game about bringing a forgotten magic shop back to life.
English only. SwiftUI, SpriteKit and Foundation; no external dependencies.

## Play

Name your shop and start with $500. Build a display, put one physical item in
each slot, set your prices and open the doors. Each day runs from 09:00 to 18:00.
Twelve visitors arrive irregularly, browse several displays together and decide
using their interests, budgets, available stock and your prices. Preparation is
untimed. Pause or use 2× speed;
leaving the app pauses the game rather than skipping hours or earning money.

Sell potions, charms and spellbooks. Compare your asking prices with the market
and estimated interest; pricing below market attracts more interested visitors,
while higher prices trade purchase likelihood for margin. Stock can be refilled
and prices adjusted while open. No visitor is guaranteed to buy.

Sweep worn areas by hand and clean the persistent dust left by visits. Preview
terracotta, oak or checkered floors by dragging, then apply the whole batch.
Repairs are free; floor changes cost $1, $2 or $3 per tile. Reinvest in decorations.
Clear three worn areas, place three different decorations, complete three days
with sales and add a compact neighboring room to finish the restoration.
Afterward the shop stays playable. Six decorations and three expansion
positions let you make it your own. The room expands once, by a 5×5 module.

Furniture and decoration can be moved for free. Return unsold stock for its
recorded cost; sell empty furniture at its purchase price. No absence penalties,
loans, crafting, accounts, ads, tracking, purchases or network calls.

## Controls and accessibility

- BUILD: tables, shelves, six decorations, or shop improvements.
- STOCK: choose a display and slot; confirm to buy one item.
- OPEN: start a trading day; pause or change presentation speed.
- Arrange: choose any furniture or decoration from a list to move or sell it.
- Hold existing furniture and drag to move it for free; an invalid drop reverts.
- New furniture is a preview until Place is pressed.
- Care: drag to sweep, or preview floor tiles and confirm the total cost.
- Prices: choose a product, compare cost/market/interest and apply an asking price.
- Pinch to zoom; use two fingers to pan with a tool active. Directional placement
  buttons, named fixtures/tiles and camera actions also support VoiceOver.
- Journal: restoration goals, calendar rules and recent trading results.
- Dynamic Type and Reduce Motion use the device's accessibility preferences.

## Candidate 0.3 (build 1) — verified

Direct manipulation, floor materials, manual cleaning, overlapping visitors and
player pricing are implemented and verified. Domain/model coverage passed 109
tests; all eight native UI tests passed in the subsequent focused run. The final
floor accessibility adjustment passed a Release build and normal/compact/large-text
capture review. The exact-source unsigned arm64 IPA passed checksum and package
verification. See `docs/LIVING-SHOP-VERIFICATION.md` for source commits, CI runs,
coverage boundaries and delivery path. This is a local testing candidate for
Sideloadly; physical installation and store release are separate checks.
The previous 0.2 evidence and IPA remain intact in
`docs/COMPLETE-GAME-VERIFICATION.md` and `design/runtime/0.2/`.

Approved masters and the director's delegated visual choices are retained in
`design/approved/` with hashes and authority in `design/APPROVALS.md`.
Runtime captures remain separate. New asset provenance is recorded in
`docs/COMPLETE-GAME-ART.md` and `docs/DECOR-ART.md`.

## Architecture and saves

`MagicShop/Core` contains platform-neutral rules, a versioned save model and
atomic persistence. `GameSession` commits a copied engine only after the save
succeeds. Sales use visitor tokens; retries and relaunches cannot award the same
sale twice. Schema 1–4 saves migrate to schema 5 while preserving the shop. A saved legacy
trading day finishes under its original rules; the following day uses the living
simulation. Prices, dirt, manual repair progress, floor choices and visitor routes
are persisted. Floor batches commit atomically, and the simulation uses exact
day/minute tokens to reject duplicate advances.
Unreadable or inconsistent saves are kept intact and surfaced as a retry error.

`MagicShop/App` owns native controls and presentation pacing. `MagicShop/World`
projects the invisible hitmap onto the painted room and renders independent
furniture, stock, customers and decoration. No visible placement grid is drawn.
The original starter background and historical approved art are preserved.

## Verification and local iPhone artifact

On Windows: `powershell -ExecutionPolicy Bypass -File scripts/verify-static.ps1`.
On macOS: `bash scripts/build-macos.sh` and `bash scripts/test-macos.sh`.
The public GitHub iOS CI is the authoritative Xcode check from Windows: Release
simulator build, domain/model/UI XCTest, and real simulator state captures.
Simulator-only fixtures use in-memory saves and are absent from device builds.

The manual `iOS Sideloadly IPA` workflow builds unsigned arm64 iphoneos and
packages `Payload/MagicShop.app`, checksum and source manifest. It has no Apple
credentials and cannot upload to TestFlight or App Store. The IPA must be
re-signed by Sideloadly to install on a physical iPhone. `scripts/verify-ipa.py`
checks the exact version, build, commit, checksum and device architecture.