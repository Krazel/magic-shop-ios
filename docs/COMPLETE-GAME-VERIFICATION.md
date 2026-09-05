# Complete-game verification — 0.2 (1)

## Delivered scope

Complete small offline English iPhone game: name the shop; Build/Stock/Open;
one physical item per slot; six paced visitors; calendar from 09:00 to 18:00;
weekday cycle; pause and 2x speed; background pause; summary and history;
reversible stock/furniture; three repairs; six decorations; one 5x5 expansion
left/right/rear; restoration completion and continued play. Native named controls,
Dynamic Type and Reduce Motion are supported. Preparation is untimed.

## Source and execution

- Full tested source: `4087139c0ff262efa82295c5e531dd6d5e5a4aca`.
- Public CI: https://github.com/Krazel/magic-shop-ios/actions/runs/33931440266 — SUCCESS.
- Release simulator build PASS and 90 executed XCTest PASS: 87 domain/model,
  three native UI journeys. Zero failures, expected failures or skipped tests.
- XCTest ran on iPhone 16 Pro arm64 simulator, iOS 18.5 (22F77), macOS 15.7.9.
  Its UI journeys create/name a shop, build, stock, open, pause, change speed,
  resume, acknowledge the summary and confirm Day 2 Tuesday; buy with large
  text; and open the completed restoration journal.
- Final application source: `77cbc09488072736c1fcee95c4581252f78da8f2`.
  Its only app change after the full test pass raises the Stock camera lift
  from 105 to 180 points; all game rules, transactions and World code are
  unchanged. The new opt-in capture_only CI mode checks that presentation
  change without claiming another 90-test execution. Normal CI still runs tests.
- Focused Release capture run: https://github.com/Krazel/magic-shop-ios/actions/runs/33932562250.
  SUCCESS; all three final Stock captures were reviewed. The selected table is visible above the panel on regular/compact iPhone and with large type; controls remain readable and contained. Files and hashes are archived in `design/runtime/0.2/77cbc09/`.
- Static verifier and git diff checks PASS after the final app change. Original
  masters, archived artwork and source/runtime asset hashes remain intact.

## Actual visual evidence

Twenty native screenshots from the full run are archived under
`design/runtime/0.2/4087139/`, with per-file SHA-256, canvas, source commit and
run in `manifest.json`. They include the regular iPhone, compact iPhone,
large type, each repair independently, and all three expansion positions.

Root reviewed Stock normal/compact/large, placement and trading. Independent
read-only visual lanes reviewed onboarding normal/compact, Build, Decor,
Improvements, Summary, Journal, restoration in all three directions, the
three individual repairs, trading and placement. The oversized decorative
backgrounds are fixed; frames no longer obscure labels or controls. Placement
and restoration props are visible; wall decor is mounted on plaster; annexes
have an open connecting passage and matching terracotta. The three repairs
remove their own authored worn areas. Scroll panels retain their fixed actions.

Minor presentation limits retained: the rear-wing painting can touch its
cutaway edge, and joins retain a small lighting/grout transition. These do not
block placement, access, reading or progression. The reference artwork is
preserved; native calendar/controls and accessible layouts follow the owner's
delegated direction, with actual runtime evidence linked in APPROVALS.md.

## Exact iPhone artifact

- Device run: https://github.com/Krazel/magic-shop-ios/actions/runs/33932563815 — SUCCESS.
- App source: `77cbc09488072736c1fcee95c4581252f78da8f2`.
- Filename: `MagicShop-0.2-build-1-unsigned.ipa` under local `outputs/ci/33932563815/`.
- SHA-256: `da396c2889e9e394f4aac967662bd6bb458d9f885d811b7511ef07a81cc3e91e`.
- Local `verify-ipa.py` PASS: checksum, source manifest, 0.2 build 1, iPhoneOS
  arm64 Mach-O, minimum iOS 16.0. Verification JSON is saved beside the IPA.
- This grouped development delivery remains 0.2 (1); earlier intermediate IPAs
  were never delivered as a new version and remain preserved for diagnosis.

## Boundaries

This Windows host cannot run Xcode or install onto a physical iPhone locally.
GitHub Actions supplies native simulator execution and device compilation.
Physical installation, real-device touch comfort, hardware frame rate and
VoiceOver listening have not been claimed as executed. The unsigned IPA needs
Sideloadly re-signing to install. No TestFlight/App Store submission or production
service is included, and no external SDK, account or data collection was added.

Earlier failed compiler/test snapshots and the initially flawed visual capture
remain diagnostic history. They are not the accepted source or final artifact.
