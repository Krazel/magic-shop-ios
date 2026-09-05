# Living shop — 0.3 (1)

Owner-requested expansion, 2026-09-05. Prior 0.2 artifact and visual masters remain preserved.
The owner has delegated product and visual decisions without another approval pause.

## Product promise
A hands-on little shop: arrange by dragging, choose floor materials, clean by hand,
watch overlapping curious visitors, and adjust prices against a market reference.
The existing restoration arc and sandbox remain. Offline, English iPhone first.

## Bounded mechanics
- Hold and drag existing furniture; valid drops save a free move, invalid drops revert.
  Drag new placement previews, then explicitly Place to buy. Cancel/interruption preserves state.
- Care: scrub three original worn groups, three passes each; remove recurring dirt by strokes.
  Dust comes from real in-game visits, never elapsed absence. Cleaning is free and works while open.
- Floors: Terracotta/Oak/Checkered, per-cell paint costs 1/2/3, no charge for the current style;
  no painting outside or over unrepaired blockers. Reserve enough recoverable shop capital
  for a basic display and first stock. Architecture and saved fixtures stay intact.
- Pricing: per-product asking price, cost and market reference, percentage relative to market,
  estimated interest conditional on a relevant visitor. Estimates are not sales guarantees.
  Range wholesale cost to three times market protects the tiny game from unrecoverable losses.
- A living day has twelve irregular arrivals with overlapping stays, individual budgets and
  preferences, several browsing stops and deterministic price-sensitive decisions.
  Competing visitors cannot buy the same physical unit. Arrivals finish before closing.
- Preparation remains untimed; 09:00–18:00 day, pause/2x, no background catchup.
  Replenishment, prices and cleaning work during trading; building/flooring waits for preparation.
- Save schema 5 preserves all previous worlds, money, furniture, stock and histories.
  Legacy in-progress sequential days finish through the old path; the next day uses the new model.

## Screens and assets before implementation
Keep the current cutaway shop, teal/gold controls, native text and compact bottom navigation.
New full-screen references: living visitors, pricing panel, compact Care/Floors state.
New runtime textures: FloorWarmOak, FloorCheckerStone, reused translucent DustPatch.
Native gesture previews, status bubbles and stroke feedback extend existing code-based VFX.
Store selected references, prompts and hashes separately from native runtime captures.

## Ownership and acceptance
Core/domain tests: commerce_core. World/gestures: audit_runtime. Art/references: commerce_visuals.
App/UI, pacing, integration tests, versioning and CI: root. No shared-file concurrent ownership.
Complete when domain and UI journeys pass native XCTest, saved games migrate, dragging and
manual care are exercised with gestures, pricing affects real purchases, simultaneous visitors
are visible in native capture, floor textures render inside the room, and exact unsigned IPA
0.3 (1) is built/verified. Physical-device installation is a separate evidence boundary.
