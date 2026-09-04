# Magic Shop — smallest complete game
Updated: 2026-09-04

## Promise
Turn a forgotten little room into your own magic shop. Choose where things go,
stock a few curious objects, watch people buy them, and use the earnings to make
the next day better. Short, intentional sessions; no timers outside the app,
punishment for absence, accounts, ads, IAP or other services.

The owner authorized autonomous development beyond the original Build slice.
That supersedes the old "Stock/Open future scope" restriction. It does not
approve any new screen or the final appearance of new world states.

## Smallest commerce vertical (target 0.2)
One existing square room, the approved two furniture types, three products,
six automatic visitors per player-started day, an honest day summary, and
reinvestment in furniture and stock. One physical product per slot (table 1,
shelf 2); no hidden stacks. Each visitor requests a product, walks to a
reachable compatible stocked fixture and buys at most one unit. Unserved
visitors leave without penalties. Unsold stock remains for tomorrow.

| Product | Cost | Sale | Placement |
| --- | ---: | ---: | --- |
| Glow Potion | $10 | $25 | Table or shelf |
| Lucky Charm | $20 | $45 | Table |
| Pocket Spellbook | $30 | $70 | Shelf |

No bargaining, crafting, employees, energy, loans or deep simulation. Six
deterministic visitors (two requests per product per day) keep initial behavior
explainable. Presentation pacing is short and pauses in background; the engine
does not use real time. Later balance changes need playtest evidence.

Move a fixture for no charge; return unsold stock for its recorded purchase
cost; resell an empty fixture for its purchase price. These deliberate actions
make experimentation reversible and prevent a $0 furniture-only dead end.
They are domain operations first; their final controls need visual approval.

## Small complete restoration arc after the vertical
Once the commerce loop is proven on iPhone, add one finite, visible improvement
sequence: clear the three removable debris groups, choose one modest decorative
set, and fund one compact neighboring room module. These changes must be
represented by approved complete images and reproducible assets. The existing
plate cannot silently show a repaired or expanded room that is only a counter
in the model. Expansion must stay modular and allow left/right/rear choices,
not force a long corridor. Do not add more product systems during closure.

## Verifiable milestones
1. **M1 — reliable commerce domain and existing-shell fixes (0.1.1 / 1).**
   Migrate saves, validate stock/placement, simulate and resume days without
   duplicate income, retain summaries, protect failed saves, correct pan speed.
   Windows verifier + independent audit + Release simulator build + XCTest.
   New commerce UI remains gated. A device artifact here is technical QA, not
   the complete playable loop.
2. **M2 — approved commerce vertical (0.2 / 1).**
   Approve Stock, Open and Day complete images; prepare merchandise/customer
   assets; integrate the full loop, recovery controls, accessible equivalents,
   background/resume handling. Calibrate invisible map to the actual plate and
   fix shelf orientation art. Capture approved old and new screens on the same
   iPhone canvas, correct differences, test three successive days and relaunch
   during purchase/day/summary. Deliver verified Sideloadly IPA.
3. **M3 — finite restoration arc.**
   Approve repair/decor/one-module images, then implement only the defined arc.
   Test purchases, collisions, access, persistence and completion. Deliver IPA
   with an achievable ending and continued sandbox play.
4. **M4 — close the candidate.**
   Human balance/touch review, Dynamic Type, VoiceOver, Reduce Motion, smaller
   iPhones, offline/relaunch/repeated-day soak, exact archive/version checks.
   No known high-severity issues and a short manual checklist with evidence.

## Screen inventory / approval boundary
- Current approved: onboarding/name, starter overview, Build catalog v3,
  Basic Display Table placement v2 (immutable images and hashes).
- Proposed M2: Stock selection/confirmation; open trading day; day summary.
- Required M2 variations: empty/incompatible/full/unaffordable/unreachable
  stock, move/return/resell, confirmation/retry errors, paused/resumed day.
  Reuse approved family only after the owner approves the complete proposal.
- Required M3: repaired/decorated/expanded world and associated choices.
- No Settings or support subscription screen in the current slice.

## Acceptance truth
Source code, static checks, executed tests, runtime capture, device installation
and visual approval are separate evidence. Never call the domain-only M1 a
complete playable game. Do not substitute a generated mockup for an app capture.
TestFlight/App Store, secrets, accounts, dependencies and monetization are closed.

## Ownership
Repository integration and Brain record: operational director task
01a06e62-e12c-7a60-ba8d-3a361779e36e, delegated by project brain
01a0434a-6ead-75e0-af3b-c052b292fcd0.
Bounded subagents: commerce_core (Domain + CommerceTests/GameStateTests),
commerce_visuals (design/proposals/commerce-v1 only),
audit_runtime (read-only analysis + its audit report). Each returns to the
director; only the director commits, pushes and dispatches CI.