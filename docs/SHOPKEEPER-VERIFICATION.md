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
The post-correction native attachment must verify the actual changed product and
camera position. Initial passing tests alone do not close this visual finding.

Final source, focused regression, screenshots and device IPA: pending.

## Honest limits

A simulator capture is not a physical-device installation or an auditory VoiceOver
session. The unsigned arm64 IPA needs Sideloadly re-signing before installation.
No TestFlight, App Store submission, public release or hardware performance claim.
Visual comparison is qualitative against archived masters, with native safe areas,
actual game values and scrollable Dynamic Type; no pixel-identical claim.
Existing already-stranded old saves are not granted money by the preventive rule.
