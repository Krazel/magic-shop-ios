# Rectangular expansion — native visual QA

Date: 2026-09-22. Target: Magic Shop 0.5 (1).

## First native candidate: REJECTED

Source: `67eb7dacaaee3cd6fedebec919f3a4e8f4d5a7d1`; CI run `35666931133`.
An independent art review inspected all nine available normal/accessibility PNGs against the three owner-approved references. The rectangular room concept is present, but the visible wall assembly and default framing do not yet reproduce the approved finish. This candidate is **not visually accepted**. Functional test results are separate and cannot clear these visual defects.

Evidence is preserved in [67eb7da-rejected](../design/runtime/0.5/67eb7da-rejected/), with exact source/run, dimensions and SHA-256 values in its [manifest](../design/runtime/0.5/67eb7da-rejected/manifest.json). All nine archived PNG hashes were checked against both that manifest and the original downloaded files in `outputs/ci/35666931133/regular/`; they match. Each is a real 1206×2622 portrait simulator screenshot. The approved references are 851×1848 portrait compositions; comparison used equivalent full-screen proportions without treating generated furniture spacing or exact tile counts as domain coordinates.

References: [left v1](../design/approved/rectangular-left-v1.png), [right v1](../design/approved/rectangular-right-v1.png), [rear v2](../design/approved/rectangular-rear-v2.png). Their exact owner approval and permitted native adaptations are documented in [RECTANGULAR-ART](RECTANGULAR-ART.md) and [APPROVALS](../design/APPROVALS.md).

## Observed defects and required corrections

| ID | Finding | Evidence and correction criterion |
| --- | --- | --- |
| V1 | Abrupt vertical joins in rear-wall lighting | All nine frames show distinct rectangular bands through both cream plaster and teal wainscot. In the right composition the clearest seams are around 27% and 48% of screen width; in rear around 39% and 60%. Light restarts at strip boundaries instead of reading as one shared warm source. Preserve a continuous wall texture/UV field and the single lamp detail; no hard brightness step may remain at an assembly boundary. |
| V2 | Repeated dark sawtooth shapes down the side walls | All directions show alternating triangular dark/cream sections, especially conspicuous on the long rear-expanded walls. These are baked rear-wall/shadow fragments repeated on a different architectural plane. Use the original continuous lateral wall material and its projected contour; retain one coherent plaster face and narrow teal edge rather than repeating the rear wainscot across the side. |
| V3 | Rear corner caps do not join the side caps | Both rear corners protrude as cut-off curved elbows. The side rail starts inward/below the elbow instead of continuing its silhouette, making the exterior trim look broken. The approved corner is a connected rounded bend of consistent thickness. Join each straight rail tangentially under the painted curve; there must be no detached-looking endpoint or protruding cut-off tail. |
| V4 | Default overview loses the front of the building beneath preparation UI | Rear normal, restored-rear and rear accessibility hide the complete facade/door and some front floor. Left/right normal retain only the upper facade; their accessibility views cover almost all of it. This fails the complete-room composition even though panning may recover hidden content. Fit the architecture including facade base within the usable Calendar-to-panel interval, using uniform camera scale/translation and the actual panel height. Preserve native UI size and factual object coordinates. The rear reference's lower panel placement is a documented generation difference, not authorization to move the native panel. |

These are assembly/framing corrections within the approved direction. They do not call for another room concept, newly positioned furniture, a different UI, a visible placement grid, or a return to the rejected annex.

## Nine-frame review matrix

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

## What is already visually coherent

- The plan reads as one continuous rectangular shop. No small attached wing, internal jambs, threshold or dividing wall remains.
- Terracotta continues through the removed-wall positions; occupied fixtures and the Oak demonstration patch appear in the added strip. These images show placement, not proof of touch behavior or save migration.
- The visible left/right entrance offset follows the approved orientation. The rear entrance is hidden, so this review does not claim its framing passed.
- Furniture/product sprites retain recognizable proportions; the blue potion is visible in all three occupied normal/accessibility states. The rear shelf is on the moved back wall.
- HUD, Calendar, preparation CTA, secondary actions and BUILD/STOCK/OPEN labels remain legible and bounded. Accessibility advice is in the existing scrollable content region with CTA retained; a screenshot of its initial clipped scroll viewport is not by itself an overflow defect. This review did not exercise scrolling or VoiceOver.
- Factual fixture differences are intentional: restored captures have $45 and empty stock; occupied variants have $27 after potion and four Oak cells. Their different advice and table locations are not master-fidelity failures.

## Implementation handoff and next evidence

The findings were sent to root and World. World proposed a continuous original rear-wall UV mapping, an original side-wall quadrilateral, connected painted corner caps, and camera fitting that includes the facade. These are planned corrections, not verified outcomes.

Inspection of [RepairedShopBackground](../design/assets/complete-game/RepairedShopBackground.png), 853×1844, supports the approximate left-wall source quad: floor front `(106,1172)`, floor rear `(143,629)`, top rear `(114,446)`, top front `(61,1141)`. Preserve the narrow teal inner edge and map the continuous source without repeating its lighting gradient. Coordinates remain a sampling guide; the next actual native capture must prove the resulting silhouette and material continuity.

Compact screenshots were not yet included in this review. After corrections, inspect the three directions at normal, compact and accessibility sizes, plus restored views where useful. Verify V1–V4 against the same approved references; confirm the full front and connected corners are visible with comfortable UI clearance, without nonuniform sprite scaling. Retain this rejected round when appending the next result. No final visual PASS is granted by this document.