# Commerce architecture
Updated: 2026-09-04. M1 is structural, pending macOS validation.

## Boundaries
- Core/Domain: Codable state, integer dollar economy, fixture/product catalog,
  placement and reachability, explicit commands, resumable deterministic day.
  Foundation only; no UI framework, wall clock, file system or network.
- Core/Persistence: atomic file store and GameSession transaction boundary.
  A command runs on a value copy; persistence succeeds before the live engine
  or published UI changes. Command/write failure discards the candidate.
- App: MainActor owner, route and native accessible controls. New commerce
  routes are integrated only after their visual references are approved.
- World: existing approved background plate, furniture, future approved stock
  and customer sprites; no visible grid and no assembled modular environment.

## Save contract
Schema 1/2 migrate preserving name, onboarding, money, fixtures and existing
floor/hitmap. Schema 3 adds stock, phase, current day and past summaries.
Unknown newer or malformed saves must fail closed rather than become a fresh
game. The current shell reports the load error inline and retries reading; it
never silently substitutes an in-memory game or overwrites the failed file.

Drafts are transient. Successful commands save before the UI acknowledges them.
Each visitor has a stable day ID + index. Repeating an already processed visit
cannot credit a sale again; a summary can only be acknowledged once.
A crash before commit replays the same uncommitted action; after commit it
resumes from the persisted cursor. No offline income.

## Integration contract
Call GameSession.commit for every durable command. Capture the expected visit
ID when scheduling presentation; do not read a newer ID in a stale callback.
Only animate a sale after commit succeeds. Stop scheduling on background or
save failure. Build/stock/rearrangement are preparing-phase actions only.
A previous summary must be acknowledged before starting the next day.

## Reachability
Breadth-first cardinal traversal starts at entrance cells and uses the same
persisted hitmap and derived furniture occupancy as placement. A display
requires a reachable neighboring floor cell. This logical test does not prove
visual calibration: the inherited obstacle coordinates and shelf projections
need plate-aligned verification in M2.

## Deferred boundaries
Repair/decor/module state and assets are M3. Do not mutate the baked plate by
drawing generic rectangles or using dormant modular assets. No backend, clock
rewards, ads, analytics, StoreKit, privacy prompts or third-party dependencies.