# Magic Shop repository guide

Magic Shop is an English-first iPhone game built with SwiftUI, SpriteKit and
Foundation. Preserve the approved visual references in `design/approved/` and
their hashes in `design/APPROVALS.md`; never overwrite approved images.

The current first slice includes onboarding, shop naming, a $500 starting
balance, Build with Tables/Shelves, a $50 one-cell Basic Display Table, a $150
two-cell wall-adjacent Simple Shelf, the approved clean shop image rendered
directly and a persistent invisible 11x11 hitmap. Do not draw a visible grid or
assemble the modular environment in the current slice. Stock/Open domain development is now authorized under docs/PRODUCT-ROADMAP.md. New commerce UI requires explicit visual approval. Monetization remains future scope.

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

## Current owner authority â€” 2026-09-05
The owner approved the three commerce masters and explicitly delegated all
remaining design/product decisions to finish the small game without further
questions: varied decorations, repair, compact expansion, enjoyable animation,
and a simulated schedule with days/hours. This supersedes earlier visual gates
and Coming soon exclusions within that scope. Preserve visual-first references
and compare runtime; autonomous selection is not a claim of a new owner review.
Version target 0.2 (1). External store publication remains a separate phase.

## Current owner expansion — 0.3
The owner explicitly requested draggable furniture, chosen flooring, manual cleaning and
recurring dirt, overlapping curious customers, and editable prices relative to market with
demand estimates. Execute docs/LIVING-SHOP-PLAN.md under the existing delegated visual
authority. This supersedes 0.2 mechanics and old no-floor-rendering exclusions within scope.
Preserve 0.2 saves/artifacts and masters. No store or external service phase is opened.
