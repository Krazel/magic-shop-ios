# M1 technical milestone — 2026-09-05

## Result
Commerce domain integrated; existing approved shell hardened. This is a technical
milestone, not the complete playable game or a final visual candidate.
Stock/Open UI remains disabled pending the owner's explicit approval.

## Verified source and builds
- App source / device artifact commit: `518e720b74f80910da52e39f4e3ec0870bcaf63f`.
- Integrated CI commit: `77aaa8e0da345b8942897edc537996410fcb057f`.
  The latter only changes workflow capture boot and Local-QA manifest wording;
  the application source and version are identical.
- Version `0.1.1`, build `1`: grouped first-slice persistence/pan fixes.
  The commerce UI milestone is planned as `0.2 (1)`; no public release.
- Windows static verification PASS: 38 required files, 12 Core source files,
  71 declared tests, unchanged approved images/runtime asset hashes.
- [Main iOS CI 33925351640](https://github.com/Krazel/magic-shop-ios/actions/runs/33925351640):
  **SUCCESS**. Release simulator build, 71 XCTest passed, actual onboarding
  capture, simulator app and xcresult artifacts retained.
- [iPhone IPA 33924300152](https://github.com/Krazel/magic-shop-ios/actions/runs/33924300152):
  **SUCCESS**. Unsigned device IPA for Sideloadly.
- IPA SHA-256:
  `8E79F724505CDCD82748586435B0F82805D1AA8CC7BF0EC1D91D4CE653F8C21F`.
- Local `scripts/verify-ipa.py` PASS: checksum, commit manifest, version/build,
  iPhoneOS arm64 Mach-O, required Payload structure and iOS 16 minimum.
- IPA and verification manifest remain under ignored
  `outputs/ci/33924300152/MagicShop-0.1.1-build-1-518e720b74f80910da52e39f4e3ec0870bcaf63f-Sideloadly/`.
- Device installation has not been performed. Sideloadly must re-sign the IPA.

## Audited behavior
One unit per compatible slot; confirmation-only spending; deterministic
six-customer days; path access; unsold stock retained; historical stock costs;
profit and summary history; transaction/save failures leave the live game
unchanged; visitor replay and summary acknowledgement cannot duplicate income;
relocation/returns/resale prevent economic dead ends; schema 1/2 migration and
rejection of future, incomplete or inconsistent schema 3 saves.

The first candidate exposed a Swift type-checking timeout in entrance routing,
fixed by splitting typed expressions. The next run passed all tests but found
the simulator was shut down before capture. The final main run verifies the
explicit post-XCTest boot. Failed/cancelled earlier runs are history, not the
validation evidence for the delivered milestone.

## Actual visual evidence — NOT A FIDELITY PASS
- [Onboarding runtime PNG](../design/runtime/0.1.1/onboarding-runtime.png)
- Canvas: 1206 x 2622, iPhone 16 Pro simulator, portrait, English.
- Source: main CI 33925351640, commit 77aaa8e.
- SHA-256:
  `607E6F635A3F759C7C2E9DE85E63E909E49FA08F50561660272B407C51CDBC64`.
- [Approved reference](../design/approved/first-slice-onboarding-name.png)
  remains immutable, 853 x 1844.

Qualitative inspection confirms substantial differences: the native panel is
too dominant and hides most of the shop, the title wraps rather than matching
the approved hierarchy, textured framing/door/key ornaments have been replaced
with simple shapes, and the name placeholder has insufficient contrast.
Native safe areas and accessibility adaptations do not justify those artistic
differences. No numerical pixel-comparison pass is claimed.

M2 must fix these existing approved-screen differences alongside the new
commerce integration; it must also resolve the inherited plate/hitmap offsets
and shelf scale/orientation from the audit. Capture every approved screen on
matching canvas/device and correct visible differences before calling it final.

## Current visual gate and next action
Three proposals, not approved and never runtime backgrounds:
[Stock](../design/proposals/commerce-v1/01-stock-v1.png),
[Open](../design/proposals/commerce-v1/02-open-v1.png),
[Day complete](../design/proposals/commerce-v1/03-day-complete-v1.png).
[Manifest, hashes and prompts](../design/proposals/commerce-v1/MANIFEST.md).

After explicit approval, archive the masters, prepare their actual assets,
integrate commerce UI/recovery/accessibility, fix the inherited visual issues,
capture and compare, then deliver the playable 0.2 IPA. Do not treat approval of
these three images as approval of materially new repair/decor/expansion states.