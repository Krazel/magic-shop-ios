# Shopkeeper 0.4 — World audit and corrections

Date: 2026-09-21. Baseline: app 6474cab (0.3), documentation HEAD 2ec2464.
Owner: delegated World lane. Scope: MagicShop/World and this document only.
Root owns App, Core, tests, versioning, CI, screenshots and IPA integration.

## Audit scope and evidence

Read the actual World/Container, AppModel callbacks, SwiftUI panels and native
journey tests. Reviewed the archived 0.3 living-runtime, ui-drag-after,
ui-floor-preview and care-compact-runtime screenshots under
[design/runtime/0.3/0b99f37](../design/runtime/0.3/0b99f37/).
The actual captures confirm the existing art, projected floor, fixture movement,
concurrent visitors and compact Care layout. No new assets or visual redesign
are needed for these corrections. They do not change persistence or the offline,
English-only iPhone scope.

Three bounded findings were selected. No additional feature work was introduced.

## W1 — Outside-room drops can snap to a valid edge (P2)

Baseline cause: ShopScene.dragGridPoint intentionally returns an unbounded origin,
but Container.onDragMove calls AppModel.setPlacementOrigin, whose updateDraft
clamps coordinates into layout bounds before validation. Dropping beyond a free
edge can therefore commit a different location instead of restoring the original.
The existing regression checks a static blocker, but not an outside-bounds drop.

Owned by root: preserve raw coordinates during a captured world drag while
retaining bounded directional controls. Check negative coordinates, coordinates
at/beyond width/depth, and expanded-room void cells. Invalid existing moves must
leave saved origin, stock and money unchanged; new drafts must remain unpaid.
This World lane has not edited the App correction or its tests.

World inspection confirms raw preview geometry uses finite projection rather than
array indices, including rotated shelves. Wall decorations safely stop mounting
when no adjacent wall exists. A fully offscreen preview now omits its accessibility
element instead of assigning CGRect.null as its frame; returning into view restores
the same placement identifier. No clipping is applied to the raw placement origin.

## W2 — Restocking while paused leaves stale pixels (P2, corrected in source; recapture pending)

Baseline cause: ShopScene.makeFixture sets an inserted product to alpha 0 and
scale 0.65, then runs a 0.20-second insertion action. The Container pauses SKView
while the trading day is paused. Stock purchases remain available in this state,
so their new sprite never becomes visible until the shop resumes. Pausing during
an insertion can likewise leave its appearance partly completed.

Correction:

- Container forwards its existing pause input as Scene.presentationPaused. Its
  external initializer and App callbacks do not change.
- Newly inserted stock, furniture and decorations settle immediately while
  presentation is paused, just as they already do for Reduce Motion.
- Entering pause rebuilds furniture once to finish any insertion in flight.
  Customer time, sale logic and scene actions remain paused. SKView continues
  drawing direct changes to product nodes, cleaning and camera position.
- Ordinary unpaused insertion animation retains its existing duration and art.
- Named stock nodes provide live accessibility values on their existing fixture
  element. This reads actual node opacity/scale, not just saved inventory.

Native verification for root:

1. Open a living day, pause, choose an empty display in Stock and buy a Glow Potion.
2. Keep the game paused. The fixture-world-UUID element must report
   `Glow Potion displayed` in its value immediately and the product must appear
   in the runtime capture. Before restocking the same display says `Empty display`.
3. Wait while paused: clock, sales and visitor positions remain unchanged. Resume
   and verify there is no second purchase or stock insertion charge.
4. Also pause during a normal insertion and check the sprite is fully present.
   Reduce Motion must show the same immediate result without scale/fade.

A live accessibility value uses `Product name arriving` only while an ordinary
insertion has not settled; it becomes `Product name displayed` after the actual
node reaches full appearance, even between App model updates. This describes
the node tree and does not prove a refreshed framebuffer. This is a useful
VoiceOver inventory description and a presentation assertion, not a test-only
flag. It does not prove freedom from overlap/occlusion; screenshot review remains
necessary for that.

## W3 — Camera accessibility announces stale zoom (P2, corrected)

Baseline cause: the complete accessibility description, including zoom, was
updated only by SwiftUI updateUIView and after child elements were refreshed.
Pinch and camera custom actions change Coordinator.cameraState directly, so an
otherwise idle preparing shop continued announcing the previous percentage.

Correction: inventory description is assigned before accessibility refresh;
applyCamera updates cameraZoomPercent from the live camera scale on every pinch,
zoom action, reset and render. The camera element combines that percentage with
the inventory description. No new controls or navigation pattern were added.

Verification for root:

- Query `world-camera` value in an idle preparing shop: `Zoom 100 percent.`
- Apply a zoom gesture without changing game state, then query again. Its value
  must change immediately and match the resulting camera scale; do not require a
  transaction or ticking day to refresh it.
- A direct Coordinator.zoom(1.15) produces 115 percent from the default state.
  Zoom out by its inverse and Reset camera return to 100 percent. Existing zoom
  limits correspond to approximately 80–154 percent.
- Existing fixture/cell IDs and their projected frames remain available after
  camera changes. Re-run the existing native drag, floor and clean cases.

## Verification status

- Source and static validation after the two World fixes: PASS on Windows,
  38 required files, 17 Core sources and 109 declared domain/model test methods.
  This early working tree still advertised 0.3 (1); root owns the grouped 0.4 bump.
- No Swift/Xcode runtime is available on this Windows host. These checks do not
  claim an executed iOS test, a new successful compile or final screenshot QA.
- Root will run the integrated tests, capture paused restocking and verify the
  final exact-source IPA. Existing 0.3 evidence remains historical and intact.

## W2 runtime follow-up — frozen framebuffer in cb6532c

CI 35632416755 passed all 130 tests, but the paused-restocking attachment exposed
an additional rendering failure. The Stock card contained a Glow Potion while
the central table still showed its previous Lucky Charm; Stock's camera lift
was also absent. The earlier node-alpha fix and accessibility value were correct
in memory, but did not refresh the pixels. The test pass was insufficient to close
this visual defect.

Evidence: [paused restock attachment](../outputs/ci/35632416755/diagnostics/attachments/852E2BFB-BAB3-4D65-8CF8-7E1EF222DD87.png).
Root owns its permanent archive and the comparable new capture.

The cause is the Container forwarding player pause to SKView.isPaused. Apple's
[SKView pause documentation](https://developer.apple.com/documentation/spritekit/skview/ispaused)
explains that this holds the scene content fixed onscreen. In contrast,
[SKNode pause](https://developer.apple.com/documentation/spritekit/sknode/ispaused)
controls action processing through the node tree.

The World follow-up removes the host's SKView pause proxy. ShopScene.render sets
its inherited isPaused flag instead, keeping action processing paused while the
view continues drawing camera and node changes. The update callback explicitly
returns while presentationPaused, and pause transitions clear lastFrameTime so
resume cannot interpolate elapsed paused time. The existing App timer pause,
Reduce Motion and immediate insertion policy remain intact. No Core, App, test,
asset, project or workflow file changed in this World follow-up.

Required runtime verification on the new integrated source:

- Repeat paused Stock return/refill and compare the actual table pixels with the
  product card. Glow Potion must replace Lucky Charm without resuming the day.
- Open/close management panels and pan/zoom while paused: the camera must draw its
  current projection, including Stock's lift. AX geometry alone is not proof.
- Compare clock, sales and visitor locations before/after waiting paused. They
  must remain stable. Resume should continue once without a time catch-up jump.
- Clean a dirty cell during paused trading and check that its dust actually fades
  with the saved level. Recheck Reduce Motion with paused restocking.

Local static validation after this follow-up: PASS, 38 required files, 17 Core
sources, 118 declared domain/model test methods, version 0.4 (1), and original
asset hashes preserved. Compilation, runtime captures and final IPA are still
integration checks owned by root; the prior 130-test pass does not establish
success for the new source.
