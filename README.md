# Magic Shop

A small offline iPhone game about bringing a forgotten magic shop back to life.
English only. SwiftUI, SpriteKit and Foundation; no external dependencies.

## Play

Name your shop and start with $500. Build a display, put one physical item in
each slot, and open the doors. Each day runs from 09:00 to 18:00 with six visitors,
two looking for each product. Preparation is untimed. Pause or use 2× speed;
leaving the app pauses the game rather than skipping hours or earning money.

Sell potions, charms and spellbooks, then reinvest in repairs and decorations.
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
- Floor: pinch to zoom and drag to explore; placement also has directional
  buttons. VoiceOver offers camera actions and named native controls.
- Journal: restoration goals, calendar rules and recent trading results.
- Dynamic Type and Reduce Motion use the device's accessibility preferences.

## Candidate 0.2 (build 1)

The current delivery joins commerce, the simulated calendar, restoration,
decoration and expansion. The full candidate still requires final CI and visual
verification; see `docs/COMPLETE-GAME-VERIFICATION.md` for recorded evidence.
This is a local testing build, not a public store release.

Approved masters and the director's delegated visual choices are retained in
`design/approved/` with hashes and authority in `design/APPROVALS.md`.
Runtime captures remain separate. New asset provenance is recorded in
`docs/COMPLETE-GAME-ART.md` and `docs/DECOR-ART.md`.

## Architecture and saves

`MagicShop/Core` contains platform-neutral rules, a versioned save model and
atomic persistence. `GameSession` commits a copied engine only after the save
succeeds. Sales use visitor tokens; retries and relaunches cannot award the same
sale twice. Schema 1–3 saves migrate to schema 4 while preserving the shop.
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