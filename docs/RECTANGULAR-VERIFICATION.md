# Rectangular shop verification — 0.5 (1)

Date: 2026-09-22. Status: verified local candidate; physical installation pending.
Final candidate source: `aed5e1abc3ef67080332a83abf994e8b9277bce0`.
Domain run: https://github.com/Krazel/magic-shop-ios/actions/runs/35666931133.
Corrected run: https://github.com/Krazel/magic-shop-ios/actions/runs/35669017850.

Release build passed. All nine initial normal/large-text captures were acquired
and independently reviewed, but the finish was rejected: abrupt rear-wall light
joins, repeating side-wall shadows, detached rear cap corners and a facade/front
floor hidden by preparation controls. Original PNGs and hashes are retained in
`design/runtime/0.5/67eb7da-rejected/`. World has corrected painting and fit for
a new native run; see `RECTANGULAR-VISUAL-QA.md`. All 15 first-pass captures
are archived.

The first run executed all 140 cases: 126 domain/model and 13 UI passed;
one UI failed when Care did not open. Video and synthesized-event coordinates
confirm a tap at the label center (335.17,742.17), with the panel unchanged.
The accessible button was only 27.7 by 14.3 points despite its outer 44-point
layout. State and overlay review found no other blocker. Preparation shortcuts
now put their full 44-point rectangular hit area inside the plain button label.
The floor test asserts this size and waits for the actual panel after one tap;
it does not retry, skip the gesture or bypass controls. The corrected native run
passed all fourteen UI tests, zero failures/skips, including this single-tap
opening and the complete floor stroke. The first run remains a failed full suite.

## Change and authority

The owner requested one larger building with the whole selected wall moved to
its new outer edge. The earlier 0.4.1 adjoining-room direction is superseded.
The owner explicitly authorized saved-state adaptation and separately approved
all three complete images with “Sí, aplica las tres”. Their archived hashes and
authority appear in `design/APPROVALS.md`; historical images and IPAs remain.

A new $250 expansion adds five complete columns or rows: 16×11 left/right or
11×16 rear. The 176-cell room has no internal wall, post, threshold or doorway.
Schema 6 fills the 30 former outside cells in old annex saves without translating
their existing coordinates again. Only wall-dependent fixtures that lose every
mounting wall move. Money, fixture/stock identities, floors, dirt and trading
records remain. Invalid source data fails before migration or file replacement.

Existing visitor paths remain unchanged when valid. Where a relocated fixture
invalidates a stop/path, the same visitor visits the same display IDs using a
recalculated route: no new profile, schedule, purchase decision or repeated sale.
The first rendered position after loading an affected save can therefore differ.

## Preflight results

- Windows static verifier PASS, version 0.5/build 1 and approved hashes pinned.
- 126 domain/model XCTest and 14 native UI cases declared; declaration is not
  execution evidence. Eight domain/model cases and one UI case added.
- Independent World review found no blocking Swift/API/gesture issue; 14,256
  projection/inverse combinations produced zero wrong cells. The renderer's
  own 1,056-center check also passed. These do not establish native rendering.
- App/fixture/UI-test review confirms stable display IDs, free drag destination,
  and the expected floor transaction: balance $27 to $23 for two new oak tiles.
- CI captures normal/large-text views before XCTest for early visual inspection;
  a failed capture/upload cannot silently skip the test suite after a good build.

## Native functional evidence

All 140 distinct cases now have passing native evidence across the two runs:
126 domain/model on `67eb7da` and all fourteen UI repeated on `aed5e1a`. Core,
AppModel and their test sources are unchanged between them. Coverage includes
all expansion directions and source schemas 4/5; densely furnished walls;
round trips; active living-day and legacy-day resume without replay; malformed
source rejection; and file bytes unchanged until a valid transaction commits.

The passing expanded-display UI case selects, returns and replaces stock in each
direction. In the right room it drags a stocked display from (12,5) through
the removed boundary to (9,5), retaining its product and expected screen position.
The passing floor case previews and applies oak across (10,7) to (11,7), checking
there is no preview charge and exactly two tiles are charged on confirmation.
Actual attached screenshots show the product after moving and the two-tile
preview/applied result with balance $27/$23. Nine PNGs and their test identifiers
are archived in `design/runtime/0.5/aed5e1a/gestures.json`; UI summary is beside it.

Fifteen actual simulator captures passed direction and independent review: restored and occupied rooms in
all three directions, normal and compact, plus occupied rooms with large text.
Review inspected continuous floor, painted wall/facade joints, external-only
perimeter, furniture scale, wall decor mounting, camera fit and readable controls.
The rear overview uses a more distant uniform camera to fit its real 11×16
projection and whole facade. It is not pixel-identical to the generated reference.
The painted source assets, native UI and saved positions are preserved.

## Delivery boundary

Corrected Release and fourteen UI tests passed. All fifteen normal/large-text/
compact captures passed direction and independent visual review. The current
archive contains 24 PNGs: fifteen preparation views and nine gesture captures.
The rejected first pass retains fifteen separate PNGs and its failed summary.
The device build passed in run `35669876068`; its exact-source IPA passed
`scripts/verify-ipa.py` against checksum, manifest, embedded version/build,
iPhoneOS platform, arm64 executable and iOS 16.0 minimum.

- Version: 0.5, build 1; 45,607,720 bytes.
- SHA-256: `c8b2c8bd4a80f9a1f9ba39ae56da9eb26656c91e0db51bcb8b17838aaee7b3db`.
- Artifact: `outputs/ci/35669876068/MagicShop-0.5-build-1-aed5e1abc3ef67080332a83abf994e8b9277bce0-Sideloadly/MagicShop-0.5-build-1-unsigned.ipa`.
- Permanent package evidence: `design/runtime/0.5/aed5e1a/ipa-verification.json`,
  `ipa-build-manifest.txt` and `ipa-SHA256SUMS.txt`.

The fourteen UI cases ran on iPhone 16 Pro simulator, iOS 18.5; compact iPhone SE
evidence is visual only. No physical installation, hardware performance, auditory
VoiceOver check or compact-device gesture execution is claimed. Tool panels
retain a lifted camera; panning reaches areas underneath the HUD. Preparation
overview shows the complete building. Sideloadly must re-sign the unsigned IPA.
The app remains offline, English, iPhone/iOS 16+, without new dependencies,
tracking or accounts. TestFlight and App Store are outside this delivery.
