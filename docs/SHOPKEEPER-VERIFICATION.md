# Shopkeeper verification — 0.4 (1)

Date: 2026-09-21. Local iPhone testing candidate; English, offline, schema 5.
The owner delegated the reversible design and implementation decisions. Prior
0.2/0.3 masters, saves and delivery artifacts remain preserved.

## Changes

- Contextual next-step guidance leads to a display, stocking, manual care,
  decoration, trading or expansion. Restored shops retain free play and records.
- The closing report groups actual sold units and margin by product and suggests
  stocking the most requested product. It does not invent why a visitor declined.
- Irreversible floor/expansion/legacy-repair spending preserves $60 in recoverable
  cash, fixtures and stock, preventing a newly stranded shop without income.
- Outside furniture drops revert at their actual coordinates, preserving placement,
  inventory and money. Directional buttons remain bounded.
- Pause stays available while managing stock, prices and care. New stock settles
  immediately; camera zoom accessibility reflects the current camera.
- Pricing keeps the product selector, stepper and Apply action reachable. Manual
  care shows progress first. New preparation/summary references preserve room art.

This builds on draggable furniture, three chosen floors, recurrent/manual dust,
up to four overlapping browsers, player prices relative to market, six decorations,
one neighboring room, and the 09:00–18:00 weekday/day schedule already delivered.
No production dependency, save migration, commercial system or service was added.

## Native evidence

Initial integrated source: cb6532cbc2f7e46eda71b508dae7fb6087b1217a.
[Full native run](https://github.com/Krazel/magic-shop-ios/actions/runs/35632416755):
Release simulator build and 130 XCTest cases passed, zero failures or skips:
118 domain/model cases plus 12 UI cases, iPhone 16 Pro / iOS 18.5 simulator.

Coverage includes a normal $500 start through three selling days, restoration,
and a fourth free-play day, with noon and closing disk-backed relaunches; capital
boundaries and overflow safety; honest per-product receipt grouping; four outside
drag boundaries; pause while pricing/cleaning; native long-press furniture drag;
three separate cleaning strokes; floor preview/apply charges; overlapping visitors;
large-text stock/prices/summary; next-step care routing; native pinch accessibility;
and returning/replacing stock while paused.

Visual inspection caught a limitation the first automated paused-stock assertion
missed: the updated SpriteKit node and accessibility value existed while SKView
still displayed its frozen prior framebuffer. The final correction keeps view
rendering active and pauses scene simulation/actions, so UI changes can be drawn.
The post-correction native attachment was inspected by root and the visual
reviewer: the selected table displays the blue potion, the camera lift is drawn
and the clock remains at 10:39. This closes the observed framebuffer defect.

UI regression source: `a7017884307c3beeafc00167716fde5dde8db6f6`.
[Final UI and capture run](https://github.com/Krazel/magic-shop-ios/actions/runs/35635145547):
SUCCESS; Release simulator build, all 12 UI cases passed again with zero failures
or skips, and 18 final captures. The Core and all test source is unchanged from
cb6532c; AppModel only changed the wording of its shared working-capital error.
The final changes are World pause/rendering, preparation button styling and
closing-report layout. This is 130 distinct passing cases across the coverage,
not 142 different cases or 130 rerun on the final source. Precise summaries and
boundaries are in `design/runtime/0.4/coverage.json`.

Final app source is `5e4a4998ecbb8e5b5e4f3f40b91a6e71c0feaf11`.
After that UI regression, a single presentation expression lowers Stock camera
lift from 180 to 120 points when viewport height is under 700 points. Core,
World, AppModel and all tests remain byte-identical to a701788. The
[targeted final capture run](https://github.com/Krazel/magic-shop-ios/actions/runs/35637669014)
succeeded with a Release build. The compact and accessibility captures pass:
the selected table and potion remain visible below the calendar. XCTest was
intentionally not repeated for this isolated camera offset.

## Visual review

The initial normal closing report hid its third product and Tomorrow advice.
The final closed-day panel uses up to 70% of the viewport and closer section
spacing: all three products, advice and the fixed next-day action now fit on the
normal iPhone capture. Compact and accessibility sizes retain scrolling and a
fixed complete action. Product values are actual sales, not mockup examples.

Preparation uses the selected teal/gold action, live restoration progress and
four direct secondary controls. Free play shows existing records and a product-
mix action; longer explanatory text scrolls at accessibility sizes. Pricing keeps
the product selector, price stepper and Apply action visible, with market/interest
details scrollable. Care places all three repair counters before instructions.
Paused restocking renders the new product and current camera without advancing
the game. The approved painted room, six decorations and product sprites remain.

`design/runtime/0.4/current-manifest.json` records 32 current images and 38
preserved images, with SHA-256, dimensions, source commit, run and provenance.
This includes 18 final state captures, ten final native test attachments, four
unchanged companion states from the full run and five historical comparisons and one rejected capture.
Normal screenshots are 1206×2622; compact iPhone SE screenshots are 750×1334.
The last run's normal-size capture contains only a white launch frame and is
excluded from current UI evidence, with its file and rejection preserved. The
normal-size camera expression is unchanged; its valid a701788 capture remains
current, while compact/accessibility Stock use the final-source captures.
This does not establish physical-device cold-start timing.
The 0.2/0.3 archives remain separate and untouched. Comparable references are
linked from `design/APPROVALS.md`.

## Honest limits

A simulator capture is not a physical-device installation or an auditory VoiceOver
session. The unsigned arm64 IPA needs Sideloadly re-signing before installation.
No TestFlight, App Store submission, public release or hardware performance claim.
Visual comparison is qualitative against archived masters, with native safe areas,
actual game values and scrollable Dynamic Type; no pixel-identical claim.
Existing already-stranded old saves are not granted money by the preventive rule.

## Exact-source iPhone package

- App source: `5e4a4998ecbb8e5b5e4f3f40b91a6e71c0feaf11`.
- [Device build](https://github.com/Krazel/magic-shop-ios/actions/runs/35637673069): SUCCESS.
- Version/build: `0.4 (1)`, unsigned iPhoneOS arm64, minimum iOS `16.0`.
- File: `outputs/ci/35637673069/MagicShop-0.4-build-1-5e4a4998ecbb8e5b5e4f3f40b91a6e71c0feaf11-Sideloadly/MagicShop-0.4-build-1-unsigned.ipa`.
- Size: `37945144` bytes.
- SHA-256: `32e9498e319305cb6e0910babac139b88641c7609b984cdb8aafea0543b7288d`.
- `scripts/verify-ipa.py`: PASS for checksum, manifest source, version/build,
  supported platform, deployment target and Mach-O architecture. The saved result
  is `design/runtime/0.4/ipa-verification.json`.

Intermediate 6ce2d93 and a701788 device builds succeeded but are not the delivered
IPA. The earlier a701788 verification is preserved separately. All changes
belong to the same previously undelivered 0.4 iteration, build 1.
