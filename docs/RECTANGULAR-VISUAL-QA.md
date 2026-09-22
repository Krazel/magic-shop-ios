# Rectangular expansion — native visual QA

Date: 2026-09-22. Target: Magic Shop 0.5 (1).

Current result: **visual PASS, 15/15 captures**, for `aed5e1abc3ef67080332a83abf994e8b9277bce0`, with the native adaptations and test limits below. All fourteen UI tests passed on the iPhone 16 Pro simulator. Compact touch comfort, physical-device testing and VoiceOver were not tested by this review. First candidate `67eb7da` remains rejected and preserved.

## First native candidate: REJECTED

Source: `67eb7dacaaee3cd6fedebec919f3a4e8f4d5a7d1`; CI run `35666931133`.
An independent art review inspected all fifteen PNGs: six normal, three accessibility and six compact, against the three owner-approved references. The rectangular room concept is present, but the visible wall assembly and default framing do not yet reproduce the approved finish. This candidate is **not visually accepted**. Functional test results are separate and cannot clear these visual defects.

Evidence is preserved in [67eb7da-rejected](../design/runtime/0.5/67eb7da-rejected/), with exact source/run, dimensions and SHA-256 values in its [manifest](../design/runtime/0.5/67eb7da-rejected/manifest.json). The initial nine normal/accessibility PNG hashes were checked against both that manifest and the original downloaded files in `outputs/ci/35666931133/regular/`; they match. All fifteen archived PNG hashes, including the six later compact captures, were then verified against the final manifest. Normal/accessibility captures are 1206×2622; compact captures are 750×1334. All are real portrait simulator screenshots. The approved references are 851×1848 portrait compositions; comparison used equivalent full-screen proportions without treating generated furniture spacing or exact tile counts as domain coordinates.

References: [left v1](../design/approved/rectangular-left-v1.png), [right v1](../design/approved/rectangular-right-v1.png), [rear v2](../design/approved/rectangular-rear-v2.png). Their exact owner approval and permitted native adaptations are documented in [RECTANGULAR-ART](RECTANGULAR-ART.md) and [APPROVALS](../design/APPROVALS.md).

## Observed defects and required corrections

| ID | Finding | Evidence and correction criterion |
| --- | --- | --- |
| V1 | Abrupt vertical joins in rear-wall lighting | All fifteen frames show distinct rectangular bands through both cream plaster and teal wainscot. In the right composition the clearest seams are around 27% and 48% of screen width; in rear around 39% and 60%. Light restarts at strip boundaries instead of reading as one shared warm source. Preserve a continuous wall texture/UV field and the single lamp detail; no hard brightness step may remain at an assembly boundary. |
| V2 | Repeated dark sawtooth shapes down the side walls | All directions show alternating triangular dark/cream sections, especially conspicuous on the long rear-expanded walls. These are baked rear-wall/shadow fragments repeated on a different architectural plane. Use the original continuous lateral wall material and its projected contour; retain one coherent plaster face and narrow teal edge rather than repeating the rear wainscot across the side. |
| V3 | Rear corner caps do not join the side caps | Both rear corners protrude as cut-off curved elbows. The side rail starts inward/below the elbow instead of continuing its silhouette, making the exterior trim look broken. The approved corner is a connected rounded bend of consistent thickness. Join each straight rail tangentially under the painted curve; there must be no detached-looking endpoint or protruding cut-off tail. |
| V4 | Default overview loses the front of the building beneath preparation UI | Rear normal, restored-rear and rear accessibility hide the complete facade/door and some front floor. Left/right normal retain only the upper facade; their accessibility views cover almost all of it. All six compact captures hide the complete facade, with the rear pair also losing front floor. This fails the complete-room composition even though panning may recover hidden content. Fit the architecture including facade base within the usable Calendar-to-panel interval, using uniform camera scale/translation and the actual panel height. Preserve native UI size and factual object coordinates. The rear reference's lower panel placement is a documented generation difference, not authorization to move the native panel. |

These are assembly/framing corrections within the approved direction. They do not call for another room concept, newly positioned furniture, a different UI, a visible placement grid, or a return to the rejected annex.

## Fifteen-frame review matrix

V1–V3 are present in every inspected frame. V4 distinguishes the extent of front occlusion.

| Capture | State/layout | Verdict | Framing observation |
| --- | --- | --- | --- |
| [restored](../design/runtime/0.5/67eb7da-rejected/restored-runtime.png) | Left, normal, original furnishing positions | Reject | Base of facade and entrance hidden by the panel. |
| [restored-right](../design/runtime/0.5/67eb7da-rejected/restored-right-runtime.png) | Right, normal, original furnishing positions | Reject | Base of facade and entrance hidden by the panel. |
| [restored-rear](../design/runtime/0.5/67eb7da-rejected/restored-rear-runtime.png) | Rear, normal, original furnishing positions | Reject | Facade and front floor hidden; centered entrance cannot be assessed visually. |
| [expanded-left](../design/runtime/0.5/67eb7da-rejected/expanded-left-runtime.png) | Left, normal, occupied addition/floor patch | Reject | Front facade partially hidden; occupied added floor remains visible. |
| [expanded-right](../design/runtime/0.5/67eb7da-rejected/expanded-right-runtime.png) | Right, normal, occupied addition/floor patch | Reject | Front facade partially hidden; occupied added floor remains visible. |
| [expanded-rear](../design/runtime/0.5/67eb7da-rejected/expanded-rear-runtime.png) | Rear, normal, occupied addition/floor patch | Reject | Complete facade and front floor hidden. |
| [left accessibility](../design/runtime/0.5/67eb7da-rejected/expanded-left-large-text-runtime.png) | Left, large text | Reject | Facade almost entirely behind the taller preparation panel. |
| [right accessibility](../design/runtime/0.5/67eb7da-rejected/expanded-right-large-text-runtime.png) | Right, large text | Reject | Facade almost entirely behind the taller preparation panel. |
| [rear accessibility](../design/runtime/0.5/67eb7da-rejected/expanded-rear-large-text-runtime.png) | Rear, large text | Reject | Complete facade/front floor hidden; rear cap sits close below Calendar. |
| [restored compact](../design/runtime/0.5/67eb7da-rejected/restored-compact-runtime.png) | Left, compact, original furnishing positions | Reject | Complete facade and some front floor hidden. |
| [restored-right compact](../design/runtime/0.5/67eb7da-rejected/restored-right-compact-runtime.png) | Right, compact, original furnishing positions | Reject | Complete facade and some front floor hidden. |
| [restored-rear compact](../design/runtime/0.5/67eb7da-rejected/restored-rear-compact-runtime.png) | Rear, compact, original furnishing positions | Reject | Complete facade/front floor hidden; front displays sit immediately above the panel. |
| [expanded-left compact](../design/runtime/0.5/67eb7da-rejected/expanded-left-compact-runtime.png) | Left, compact, occupied addition/floor patch | Reject | Complete facade and some front floor hidden; added displays/potion visible. |
| [expanded-right compact](../design/runtime/0.5/67eb7da-rejected/expanded-right-compact-runtime.png) | Right, compact, occupied addition/floor patch | Reject | Complete facade and some front floor hidden; added displays/potion visible. |
| [expanded-rear compact](../design/runtime/0.5/67eb7da-rejected/expanded-rear-compact-runtime.png) | Rear, compact, occupied addition/floor patch | Reject | Complete facade/front floor hidden; a front table is immediately above the panel. |

## What is already visually coherent

- The plan reads as one continuous rectangular shop. No small attached wing, internal jambs, threshold or dividing wall remains.
- Terracotta continues through the removed-wall positions; occupied fixtures and the Oak demonstration patch appear in the added strip. These images show placement, not proof of touch behavior or save migration.
- The visible left/right entrance offset follows the approved orientation. The rear entrance is hidden, so this review does not claim its framing passed.
- Furniture/product sprites retain recognizable proportions; the blue potion is visible in all three occupied directions at normal, accessibility and compact sizes. The rear shelf is on the moved back wall.
- HUD, Calendar, preparation CTA, secondary actions and BUILD/STOCK/OPEN labels remain legible and bounded. Accessibility advice is in the existing scrollable content region with CTA retained; a screenshot of its initial clipped scroll viewport is not by itself an overflow defect. This review did not exercise scrolling or VoiceOver.
- Factual fixture differences are intentional: restored captures have $45 and empty stock; occupied variants have $27 after potion and four Oak cells. Their different advice and table locations are not master-fidelity failures.

## Implementation handoff and next evidence

The findings were sent to root and World. World proposed a continuous original rear-wall UV mapping, an original side-wall quadrilateral, connected painted corner caps, and camera fitting that includes the facade. These are planned corrections, not verified outcomes.

Inspection of [RepairedShopBackground](../design/assets/complete-game/RepairedShopBackground.png), 853×1844, supports the approximate left-wall source quad: floor front `(106,1172)`, floor rear `(143,629)`, top rear `(114,446)`, top front `(61,1141)`. Preserve the narrow teal inner edge and map the continuous source without repeating its lighting gradient. Coordinates remain a sampling guide; the next actual native capture must prove the resulting silhouette and material continuity.

The six compact captures confirm the same V1–V4 rejection; no new art direction is needed. Their HUD, Calendar, preparation text/CTA and navigation labels remain visually legible, but this does not certify their touch areas. After corrections, inspect the three directions at normal, compact and accessibility sizes, plus restored views where useful. Verify V1–V4 against the same approved references; confirm the full front and connected corners are visible with comfortable UI clearance, without nonuniform sprite scaling. Retain this rejected round when appending the next result. No final visual PASS is granted by this document.
## Functional evidence and candidate separation

The first source has [139/140 XCTest passes](../design/runtime/0.5/67eb7da-rejected/test-summary.json): 126 domain/model and 13 UI passed; one UI test failed opening Care before the floor-crossing gesture. The archived failure is `testFloorPaintingCrossesTheRemovedRightWall`, which could not find `care-floor` while the preparation panel was still present. This is not evidence that painting across the former wall failed, because the test did not reach that gesture. It is also not a full functional PASS.

Root reports the next source `aed5e1abc3ef67080332a83abf994e8b9277bce0` includes paint/framing corrections and 44-point shortcut targets, with run `35669017850` repeating fourteen UI tests and fifteen captures. At that handoff, those changes were unverified; the second-round inspection below now records the nine available normal/accessibility results. The first source stays rejected, and all fifteen captures remain preserved.
## Second candidate: initial normal/accessibility review

Source: `aed5e1abc3ef67080332a83abf994e8b9277bce0`; CI run `35669017850`. Independently inspected 9/9 available captures: six normal and three large-text, all 1206×2622. **Visual PASS for this inspected subset, with recorded native adaptations; compact and functional completion pending.** No new blocking finish defect was found in these nine frames.

The [durable archive](../design/runtime/0.5/aed5e1a/) and its [hash manifest](../design/runtime/0.5/aed5e1a/manifest.json) preserve this exact source. All nine SHA-256 values match the original files in `outputs/ci/35669017850/regular/` and the archive. This evidence does not replace the first rejected round.

### V1–V4 reassessment

| Finding | New visible result | Subset verdict |
| --- | --- | --- |
| V1, rear lighting joins | One continuous warm rear plaster surface with a single lamp. The rectangular light/dark restarts through plaster and wainscot are gone in all three directions. | Corrected |
| V2, lateral zigzags | Side plaster now forms a continuous perspective face with a narrow inner teal boundary. The repeated triangular shadow bands are absent, including the long rear-extension sides. | Corrected |
| V3, rear cap joins | Both rounded back corners meet the side rails. The protruding broken-elbow endpoints are gone; the complete perimeter reads as connected painted trim. | Corrected |
| V4, lost facade | The complete facade, entrance and stone base are visible in every normal and large-text frame. No front row disappears behind preparation UI. Calendar and panel remain separate from the architectural silhouette, including rear accessibility. | Corrected |

### Nine-frame second-round matrix

| Capture | Inspection result |
| --- | --- |
| [restored left](../design/runtime/0.5/aed5e1a/restored-runtime.png) | Pass: full continuous room, original furnishing group retained, right-offset door visible, complete front base. |
| [restored right](../design/runtime/0.5/aed5e1a/restored-right-runtime.png) | Pass: left-offset door and added facade bays visible; wall finish continuous. |
| [restored rear](../design/runtime/0.5/aed5e1a/restored-rear-runtime.png) | Pass with smaller uniform overview: centered original-width facade and complete depth visible. |
| [expanded left](../design/runtime/0.5/aed5e1a/expanded-left-runtime.png) | Pass: stocked added display, second display and Oak patch visible; no former-wall boundary. |
| [expanded right](../design/runtime/0.5/aed5e1a/expanded-right-runtime.png) | Pass: stocked added display, second display and Oak patch visible; no former-wall boundary. |
| [expanded rear](../design/runtime/0.5/aed5e1a/expanded-rear-runtime.png) | Pass with smaller uniform overview: potion, shelf and patch remain identifiable, front fully visible. |
| [left large text](../design/runtime/0.5/aed5e1a/expanded-left-large-text-runtime.png) | Pass: complete architecture fits between Calendar and the larger panel, with visible separation. |
| [right large text](../design/runtime/0.5/aed5e1a/expanded-right-large-text-runtime.png) | Pass: complete architecture and entrance remain unobscured; controls are bounded. |
| [rear large text](../design/runtime/0.5/aed5e1a/expanded-rear-large-text-runtime.png) | Pass with smaller uniform overview: Calendar, rear cap, front base and preparation panel do not overlap. |

### General fidelity and remaining limits

The corrected room is recognizably the same painted teal/cream/terracotta shop as the approved references, now with one exterior rectangular perimeter. Warm plaster, wood furnishings, rounded teal trim, the original door/windows and continuous floor remain coherent. The stronger defects were not replaced by a flat-color generic room. There is no reintroduced annex, internal threshold or visible placement grid.

This is not pixel identity with the generated masters. The native rear projection is appreciably narrower and the uniform overview is smaller than rear v2, with correspondingly smaller furniture. The facade and all floor now remain visible while the established UI stays at its native size. That is consistent with the documented priority of real 11×16 coordinates, calibrated projection and uniform camera fitting over accidental image resynthesis. Products remain visually identifiable at normal/large-text capture size; the screenshots alone do not prove comfortable tapping, particularly on the forthcoming compact version.

The floor's repeated source detail and illumination are more uniform than the master's broad painted highlights. Subtle trim/material junctions remain visible on close inspection, but no detached corner, abrupt rear light stripe or repeated lateral sawtooth survives at the normal full-screen reading size. These are recorded finish differences, not a claim of 1:1 raster reconstruction or grounds to reopen the selected architecture.

Normal UI copy and actions remain legible. Large-text preparation advice uses its existing scroll viewport, while the CTA and Improve/Arrange/Prices/Care row remain visible; Calendar wraps without covering the scene. A static screenshot cannot verify the new 44-point touch targets or the pending Care gesture regression. No conclusion about VoiceOver, motion, save migration or all UI tests is inferred here.

Next gate: review the six compact PNGs from this same source, especially rear sprite readability and the Calendar-to-facade-to-panel clearances, then append the final visual result without erasing either round. The pending fourteen UI tests must be assessed separately before functional closure.
## Second candidate: completed compact review and visual closure

The final six compact PNGs from run `35669017850` were independently inspected at 750×1334 and compared with the same approved references. **All six pass visual review; combined result is 15/15 visual PASS for the exact second source.** The four blocking finish/framing defects do not recur. No code, World, assets or approved images were changed by this QA lane.

All fifteen archived capture hashes match both the final [manifest](../design/runtime/0.5/aed5e1a/manifest.json) and their original files in `outputs/ci/35669017850/captures/`. All nine gesture-image hashes match [gestures.json](../design/runtime/0.5/aed5e1a/gestures.json). The earlier subset's pending statements above describe the review sequence; this section is the final evidence status.

| Compact capture | Final visual result |
| --- | --- |
| [restored left](../design/runtime/0.5/aed5e1a/restored-compact-runtime.png) | Pass: continuous room, all four tables/decor group, correct offset entrance and complete stone base; no panel overlap. |
| [restored right](../design/runtime/0.5/aed5e1a/restored-right-compact-runtime.png) | Pass: complete perimeter/front, coherent wall paint and window bays; no cap separation. |
| [restored rear](../design/runtime/0.5/aed5e1a/restored-rear-compact-runtime.png) | Pass with overview-size limitation: full depth and centered original facade visible; small furniture remains distinguishable. |
| [expanded left](../design/runtime/0.5/aed5e1a/expanded-left-compact-runtime.png) | Pass: added displays, blue potion and Oak patch visible; full facade and margins retained. |
| [expanded right](../design/runtime/0.5/aed5e1a/expanded-right-compact-runtime.png) | Pass: added displays/product and painted cells visible across the former boundary; no interior partition. |
| [expanded rear](../design/runtime/0.5/aed5e1a/expanded-rear-compact-runtime.png) | Pass with overview-size limitation: shelf, potion/table, decor and patch distinguishable; complete front and base fit above the panel. |

Compact Calendar-to-cap and facade-base-to-panel gaps remain visible. All displayed English HUD, Calendar, guidance, CTA, secondary shortcuts and BUILD/STOCK/OPEN text is legible without visible truncation. The narrower rear room is intentionally shown as a uniform overview; its small furniture is not a claim of a 44-point direct sprite target or proven comfortable touch interaction. The recorded camera/projection adaptation remains applicable. This is a nonblocking visual limitation, not permission to distort the room or enlarge individual sprites independently.

### Native interaction evidence and precise scope

The archived [XCTest summary](../design/runtime/0.5/aed5e1a/test-summary.json) records fourteen passed UI tests, zero failed, zero skipped, on **iPhone 16 Pro, iOS Simulator 18.5**. This repeat resolves the earlier Care-opening test failure. It is not a compact-device UI test run, a physical iPhone result, or VoiceOver verification. The 126 Core/model passes belong to the preceding full-domain run and were not rerun as part of this UI-only job.

Three gesture attachments were also inspected visually in this closing review:

- [Floor preview](../design/runtime/0.5/aed5e1a/gesture-floor-preview-crosses-the-removed-wall.png) shows two preview cells across the old right-wall location, `2 tiles / $4`, Oak selected and balance `$27` before confirmation.
- [Applied floor](../design/runtime/0.5/aed5e1a/gesture-continuous-floor-applied-across-the-old-wall.png) shows the contiguous extension, `2 tiles laid`, cleared preview, disabled Apply Floor and balance `$23`.
- [Stocked furniture drag](../design/runtime/0.5/aed5e1a/gesture-stocked-furniture-dragged-through-the-removed-right-wall.png) shows the moved table on the original-room side of the former wall with its blue potion retained. The passing UI assertions supply the movement/stock check; the still image alone does not prove the gesture trajectory.

The gesture manifest additionally archives before/restock images for all three expansion directions. Their hashes were verified, but those six attachments were not separately visually reinspected in this closing pass. Care mode lifts the world to expose working floor; its back wall can continue under fixed HUD/Calendar while the selected cells remain visible. This intentional working view is distinct from the fully fitted preparation overview assessed by V4.

Root's [IPA verification](../design/runtime/0.5/aed5e1a/ipa-verification.json) reports PASS for 0.5 (1), iPhoneOS arm64, iOS 16.0 minimum, exact source `aed5e1a`, SHA-256 `c8b2c8bd4a80f9a1f9ba39ae56da9eb26656c91e0db51bcb8b17838aaee7b3db`. This QA lane read that report; it did not install or independently repackage the IPA. The file remains unsigned and requires re-signing for device installation.

**Visual disposition: accepted for the approved rectangular-room correction at the fifteen inspected states, with the documented native fit and overview-size limits.** No remaining blocker was found in this bounded review. All previous rejected evidence, references and source hashes remain preserved.