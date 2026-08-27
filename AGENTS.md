# Magic Shop repository guide

Magic Shop is an English-first iPhone game built with SwiftUI, SpriteKit and
Foundation. Preserve the approved visual references in `design/approved/` and
their hashes in `design/APPROVALS.md`; never overwrite approved images.

The current first slice includes onboarding, shop naming, a $500 starting
balance, Build with Tables/Shelves, a $50 one-cell Basic Display Table, a $150
two-cell wall-adjacent Simple Shelf, a modular 11x11 floor and a persistent
hitmap. Stock, Open and monetization are intentionally future scope.

Before changing code, read `README.md`, `docs/TECHNICAL-FOUNDATION.md`,
`design/APPROVALS.md` and `design/ASSET-INVENTORY.md`. Keep domain logic under
`MagicShop/Core` free of SwiftUI, SpriteKit and UIKit.

Validation:

- On Windows, run `powershell -ExecutionPolicy Bypass -File scripts/verify-static.ps1`.
- On macOS, run `bash scripts/build-macos.sh` and `bash scripts/test-macos.sh`.
- GitHub Actions is the authoritative macOS compile/XCTest check when working
  from Codex Cloud or another non-macOS environment.

Do not add accounts, analytics, ads, tracking, StoreKit, external dependencies,
TestFlight upload or App Store deployment unless the owner explicitly opens
that phase.
