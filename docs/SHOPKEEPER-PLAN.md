# Shopkeeper iteration — 0.4 (1)

Activated 2026-09-21 by the owner through the coordinating studio task.
Baseline: clean main 2ec2464, app 6474cab, verified local 0.3 candidate.
Current portfolio truth is D1, PR-011 in the Krazel Studio library; the historical
Brain file supplements evidence and does not replace that record.

## Concrete outcome

Make the existing shop easier to understand and safer to experiment with. Keep
the iPhone/English/offline game, approved room/art, existing saves and living-shop
rules. No new monetization, SDK, store submission or disconnected game system.

- Prevent irreversible floor/expansion/legacy-repair spending from consuming the
  recoverable $60 needed for a starter table and potion.
- Reject an outside furniture drag where the finger actually lands; preserve the
  original placement, stock and balance. Directional buttons keep bounded movement.
- Keep restocked products visible while paused and report current camera zoom to
  accessibility clients. Pausing becomes reachable in the calendar even with a
  management panel open.
- Replace generic preparation text with the next useful restoration step and a
  direct action. Completed shops show existing sales/profit records and invite a
  new product/price experiment; no new rewards or save schema are introduced.
- Show real units and margin by product in the closing report, plus an honest
  observation about requested products. Never infer lost-sale reasons from data
  that was not recorded. Keep the next-day button fixed outside scrolling content.
- Keep the price stepper visible and the cleaning progress ahead of explanatory
  copy on compact/large-text layouts. Preserve native 44-point actions and artwork.

## Ownership and visual authority

Root owns App/UI, AppModel tests, UI tests, visual fixtures, version/CI and integration.
commerce_core owns Core/domain tests and SHOPKEEPER-DOMAIN.md.
audit_runtime owns World and SHOPKEEPER-WORLD.md.
commerce_visuals owns the two new full-screen masters and approval/provenance archive.
These paths are disjoint. All prior work and 0.3 artifacts remain preserved.
The owner previously delegated reversible visual choices without more questions;
director selection is recorded honestly, not as individual owner image review.

## Definition of done

Native Release build and domain/model/UI tests on public GitHub Actions, including
a viable start-to-restoration-to-free-play journey and failure/relaunch boundaries.
Real regular/compact/large-text captures of preparation, closing report, pricing,
care and paused stock; compare to the new masters and unchanged room direction.
Produce and verify an unsigned iPhoneOS arm64 0.4 (1) IPA for existing Sideloadly
testing. Report source commit, runs, checksum and physical-device limits. Reconcile
PR-011 using its current revision and preserve unrelated tracking fields; do not
edit a seed or deploy the library. Physical installation is not simulator evidence.
