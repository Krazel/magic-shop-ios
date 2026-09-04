# Complete-game verification — 0.2 (1)

## Acceptance scope
A complete small offline game: onboarding; Build/Stock/Open; one unit per slot;
six paced visitors with 09:00–18:00 calendar; pause/speed/background handling;
summary/history; reversible stock/furniture; three repairs; six decorations;
one 5×5 expansion left/right/rear; restoration completion and continued play.
English iPhone UI with native accessible controls and reduced-motion behavior.

## Checks already executed
- Windows static verifier PASS after integration: source references, approved
  image hashes, original plate and dormant asset preservation, version 0.2/1.
- First Xcode compile exposed a schema-migration initializer closure reading
  self before restoration initialized. Fixed by capturing local calibrated
  cells. This failed run is diagnostic history, not acceptance evidence.
- Next Release simulator build passed. XCTest and captures are in progress.

## Final evidence to record
- Exact source commit, public CI run and executed test count.
- Native control journey: name, build, stock, open, pause, speed, next day.
- Restoration completion journal via a real playable economy fixture.
- Runtime screenshots and comparison against current masters; no mockup may
  stand in for a runtime screenshot.
- Large text screenshot, VoiceOver control inventory and Reduce Motion review.
- Unsigned iphoneos IPA checksum, version/build, commit manifest and architecture.

## Honest boundaries
This Windows host cannot run Xcode or a physical iPhone locally. GitHub Actions
provides simulator execution and device compilation. Physical installation,
real-device touch comfort and hardware performance must not be claimed as
executed without evidence. No TestFlight, App Store or production action is part
of this local candidate. No external service or personal data was introduced.