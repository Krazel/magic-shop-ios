# Expansion verification — 0.4.1 (1)

Status: verified local iPhone testing candidate; native visual and package review passed.
Date: 2026-09-22. English, offline iPhone candidate; save schema 5 unchanged.

## Scope

The owner confirmed that the shop expansion looked awkward and requested a
different solution under standing delegated visual authority. The same 5×5
annex is now constructed as a connected room: floor and upright walls have
separate projection, the entire five-cell opening is clear, and its pale stone
threshold sits at floor level. Main-room art and all saved state are preserved.

The expanded camera keeps the complete building in view and corrects Stock
panel lift for the selected annex display. Starting a drag retains the same
camera anchor. Painted finishes reuse the original room's warm plaster,
wainscot, broad caps, curved corners and floor, with existing painted jambs.
Rear wall decorations fit the surviving wall segments without moving saved cells.

## Executed regression coverage

Source: `1cac2194d640986ae0c7ac113c1207f42cd063c0`.
[Full native run](https://github.com/Krazel/magic-shop-ios/actions/runs/35657369361)
succeeded: Release simulator build plus **131 tests passed, zero failures or
skips** (118 domain/model and 13 native UI cases), iPhone 16 Pro / iOS 18.5.
The run also produced all 15 requested normal, compact and large-text captures.

Expanded domain coverage checks each of the three orientations, preserved dirt,
fixtures, stock, custom floor and save round trips, all five seam connections,
outer walls and the 146-cell traversable footprint. The new native UI case taps
an occupied annex display, returns and replaces stock, then holds the display
and verifies that returning to preparation does not jump its overview position.
It executes left, right and rear directions independently.

The existing suite continues to cover manual cleaning, draggable furniture,
floors, prices, overlapping visitors, time/pause and multi-day saved progression.
Its inherited coverage is documented in `SHOPKEEPER-VERIFICATION.md`.

The first finish was visually rejected despite passing functional tests.
Screenshots and the exact test summary are permanently retained in
`design/runtime/0.4.1/1cac219-rejected/`; see `EXPANSION-VISUAL-QA.md`.
The intermediate IPA from run `35659391617` passed package validation but is
not the accepted deliverable.

## Painted finish validation boundary

Revised source: `8d58a2d0e969ba6b69c20c4e454dd56f367e751f`.
Only World painting/material assembly and the rear wall decoration's visual
mount changed after the 131-test run. Domain, persistence, camera, gestures,
App controls and test source are unchanged. Windows static verification passes.
Independent mathematical review checked 30,603 projected floor samples and all
75 annex cell centers: no uncovered points or inverted warp triangles.

[Focused build and captures](https://github.com/Krazel/magic-shop-ios/actions/runs/35661013271)
succeeded. Root inspected all 15 actual PNGs; independent art review passed the
nine occupied annex states across normal, compact and accessibility text layouts.
XCTest is intentionally not repeated for the painting-only finish;
131 describes distinct passing cases on the integrated functional source, not
a claimed rerun on every subsequent visual snapshot.

## Visual evidence and limits

The corrected rooms share the original warm plaster, shaded rail, teal wainscot,
painted cap thickness, rounded corners and terracotta tile language. Their full
openings and flush thresholds remain clear; the rear painting stays on its wall.
Existing custom oak cells, stocked tables and unchanged native controls are visible.
No background rectangle, original rear lamp or residual wall crosses an opening.

All 15 source PNGs are archived in `design/runtime/0.4.1/8d58a2d/`, with dimensions,
SHA-256, source and CI provenance in `manifest.json`. Nine show occupied annexes
(three directions × three layouts); six show the empty restored annexes in normal
and compact layouts. Normal/large-text images are 1206×2622; compact images are
750×1334. Native UI adaptations and original main-room projection are recorded
in `design/APPROVALS.md`; generated references are not claimed as app screenshots.

Lateral front corners have a tight outer viewport margin (about 0.15 pt normal,
1 pt compact). Inspection found no loss of floor, post or usable opening; root
accepts this as a nonblocking framing limitation, with manual pan still available.
At accessibility text sizes, supporting guidance scrolls while actions stay fixed.
Simulator review does not establish physical-device rendering/performance,
auditory VoiceOver behavior or pixel identity with resynthesized reference art.

## Device package

[Unsigned device build](https://github.com/Krazel/magic-shop-ios/actions/runs/35661029804)
succeeded on `8d58a2d0e969ba6b69c20c4e454dd56f367e751f`. The downloaded IPA passed
`scripts/verify-ipa.py`: version 0.4.1, build 1, exact source manifest, iPhoneOS
arm64, minimum iOS 16.0, matching checksum.

SHA-256: `c58fead57f27d9faf938f7560670a468a0acabda06c4fd197e85f38b4055c98a`.

Local file relative to repository:
`outputs/ci/35661029804/MagicShop-0.4.1-build-1-8d58a2d0e969ba6b69c20c4e454dd56f367e751f-Sideloadly/MagicShop-0.4.1-build-1-unsigned.ipa`.

Visual acceptance passed. Sideloadly re-signing and installation on a
physical iPhone are separate from simulator/package verification.

No TestFlight upload, App Store submission or production publication is included.

The private project library `PR-011` was updated through its UI and verified at
revision 4 (`2026-09-21T22:26:17.366Z`). Reference version is 0.4.1 (1), distribution
remains a test IPA, and existing publication/tracking fields and historical notes
are preserved. The next step is physical installation, not another design decision.
