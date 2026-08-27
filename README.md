# Magic Shop

Local iPhone-first implementation of the Magic Shop first slice.

## Current scope

- Version `0.1`, build `1`, iOS 16+.
- Approved first-run story, validated shop naming and persistent HUD name.
- SwiftUI fixed HUD, native Build controls and accessible placement actions.
- SpriteKit square 11×11 modular shop world with pinch zoom, vertical pan, fixture sprites and placement preview.
- Persistent per-cell floor styles and a testable hitmap for entrance, walls, static debris and dynamic fixture occupancy.
- Pure Swift/Foundation game state, fixture catalog, placement rules and JSON persistence.
- Starting balance: `$500`.
- `Basic Display Table`: `$50`, 1×1 footprint, stock capacity 1.
- `Simple Shelf`: `$150`, 2×1 footprint, stock capacity 2, wall-adjacent placement.
- No backend, accounts, ads, analytics, tracking or third-party dependencies.

Onboarding, Build catalog v3 and Basic Display Table placement v2 are approved
and implemented. The environment is assembled at runtime from the 19-piece
modular kit in `design/ASSET-INVENTORY.md`; the legacy starter background is
kept only as a design reference and is not shipped or referenced by runtime
code. Final 1:1 comparison still requires an iPhone simulator capture on macOS.

## Project layout

- `MagicShop/Core/`: platform-neutral domain and persistence.
- `MagicShop/App/`: SwiftUI onboarding, HUD, Build catalog and placement controls.
- `MagicShop/World/`: layered SpriteKit environment, square-grid hit testing, camera input and furniture rendering.
- `MagicShopTests/`: XCTest coverage shared by Xcode and SwiftPM.
- `MagicShop.xcodeproj/`: local iPhone app and unit-test targets.
- `Package.swift`: core-only package; it does not compile SwiftUI/SpriteKit.
- `scripts/`: reproducible verification commands.

## Verify on Windows

Windows cannot compile the iOS target. Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-static.ps1
```

This checks project references, the four current approval hashes, all modular
asset copies, floor/hitmap invariants, absence of the legacy runtime plate and
the corrected table economy. It is not a substitute for Xcode.

## Build and test on macOS

Requirements: Xcode 16 or a compatible Xcode with the iOS 16 SDK support and
an installed iPhone simulator.

```bash
bash scripts/build-macos.sh
bash scripts/test-macos.sh
```

`test-macos.sh` defaults to `platform=iOS Simulator,name=iPhone 16 Pro`. Override
that when necessary:

```bash
MAGIC_SHOP_DESTINATION='platform=iOS Simulator,name=iPhone 15' bash scripts/test-macos.sh
```

The app bundle identifier is the explicit local placeholder
`com.example.MagicShop`; replace it only when signing is authorized.

## GitHub CI and Codex Cloud

`.github/workflows/ios-ci.yml` runs on every push to `main`, on pull requests
and by manual dispatch. It selects an available iPhone simulator, builds the
Release simulator app without signing, runs the XCTest suite and retains both
the zipped `.app` and `.xcresult` evidence for 14 days.

This regular CI workflow contains no Apple credentials and cannot upload to
TestFlight or the App Store. Codex Cloud can work against the GitHub repository;
GitHub Actions remains the authoritative iOS compiler because Xcode requires a
macOS runner.

## Physical iPhone build for Sideloadly

Run the manual `iOS Sideloadly IPA` workflow in GitHub Actions to create an
unsigned device `.ipa`. It compiles the Release app against `iphoneos`, packages
the required `Payload/MagicShop.app` structure and uploads the IPA, checksum and
build manifest as a 14-day artifact. The workflow contains no Apple credentials
and does not upload to TestFlight or the App Store.

Download the artifact, extract it and drag the `.ipa` into Sideloadly. Sideloadly
re-signs it with the tester's Apple ID before installing it on the connected
iPhone. On iOS 16 or later, Developer Mode must be enabled on the device.
