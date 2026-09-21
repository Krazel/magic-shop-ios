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
with sales and expand the shop to finish the restoration.
Afterward the shop stays playable. Six decorations and three expansion
directions let you make it your own. A single $250 expansion moves an entire
wall outward, adding 55 floor spaces to form one 16×11 or 11×16 room.

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

## Current work 0.5 (build 1) — native verification pending

The owner approved three complete rectangular references on 2026-09-22. The
selected exterior wall moves outward; the floor and building become one larger
room, with no annex opening, internal posts or threshold. Wall-mounted fixtures
follow the new perimeter while their stock and identities remain intact.

Schema 6 fills the former outside corners of saved annexes and preserves money,
floor styles, dirt and trading progress. Active visitor routes are repaired only
where needed, keeping their schedules and completed purchases. Implementation
and regression coverage are in progress; this section does not claim a native
build, successful XCTest run or finished IPA. See `docs/RECTANGULAR-EXPANSION.md`.

## Previous candidate 0.4.1 (build 1) — verified, geometry superseded

Annexes now join the shop through a full-width, level opening, with upright
painted walls, matching rounded caps and endpoint posts. The expanded camera
keeps annex stock controls usable without jumping when a drag begins. Saved
rooms, furniture, stock, floors, dirt and schema 5 remain intact.

All 131 native regression cases passed (118 domain/model plus 13 UI), including
stocking and holding a display in each annex direction. The subsequent painted
finish passed a Release build and review of 15 real normal/compact/large-text
captures; the exact-source unsigned arm64 IPA is verified. Physical installation
remains separate. See `docs/EXPANSION-VERIFICATION.md` for evidence and limits.

## Previous candidate 0.4 (build 1) — verified

Adds contextual restoration guidance and a product-by-product closing report;
protects trading capital during permanent improvements; fixes outside drops,
paused restocking and camera accessibility. Pricing and cleaning controls stay
clear on smaller layouts, and the calendar retains pause while panels are open.
The existing save schema 5 and artwork remain. See `docs/SHOPKEEPER-PLAN.md`,
`docs/SHOPKEEPER-DOMAIN.md` and `docs/SHOPKEEPER-WORLD.md` for scope and evidence.
Native verification passed 118 domain/model cases and all 12 UI cases, with a
second 12-case UI run after the final rendering correction. Real normal, compact
and large-text captures were reviewed; the exact-source arm64 IPA is verified.
See `docs/SHOPKEEPER-VERIFICATION.md` for runs, coverage boundaries, screenshots
and the local Sideloadly file. Physical installation remains a separate check.
The previous delivery stays recoverable.

## Previous candidate 0.3 (build 1) — verified

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
sale twice. Schema 1–5 saves migrate to schema 6 while preserving the shop. A saved legacy
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
