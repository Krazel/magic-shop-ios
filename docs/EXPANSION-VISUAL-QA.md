# Expansion visual QA

## Current decision — visual pass, 2026-09-22

Source `8d58a2d0e969ba6b69c20c4e454dd56f367e751f`, capture run `35661013271`, passes this independent review of all nine occupied-annex states: left/right/rear at normal, compact and accessibility text sizes. The integration director independently reviewed all fifteen delivered PNGs and accepted the current framing. The earlier source remains rejected and its evidence is retained below.

The painted-source repair resolves the previous material and volume failures. Caps now have comparable thickness, bevels and rounded corner treatment; walls and floor belong to the same warm painted family; end posts have cream framed shafts and teal caps/bases. The rear painting now stays inside the surviving right wall. The passage and flush threshold remain clear in all nine states, with no residual wall or lamp across the opening.

References are [left v2](../design/approved/expansion-left-v2.png), [right v2](../design/approved/expansion-right-v2.png) and [rear v3](../design/approved/expansion-rear-v3.png), subject to the [documented native adaptations](../design/APPROVALS.md). This acceptance does not require copying generated main-room resynthesis: the original painted plate/projection, factual furnishings and native UI remain authoritative.

### Accepted native evidence

All links now point to the durable archive [design/runtime/0.4.1/8d58a2d](../design/runtime/0.4.1/8d58a2d/), with its [capture provenance](../design/runtime/0.4.1/8d58a2d/capture-manifest.txt) and [artifact manifest](../design/runtime/0.4.1/8d58a2d/manifest.json). Every archived PNG reviewed here was hash-matched to the exact downloaded image inspected.

Normal and accessibility PNGs are 1206×2622; compact PNGs are 750×1334. All are English portrait screenshots from the real simulator with deterministic native game-state fixtures.

| State | Capture | Decision | SHA-256 |
| --- | --- | --- | --- |
| left / normal | [annex-left-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-left-runtime.png) | PASS | 095ADAAB10D32C07042802ACE21221305034CEA96CCD6F8180E3160EBFADB09D |
| left / compact | [annex-left-compact-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-left-compact-runtime.png) | PASS | 3CE0D8072292019966C555C78D9E61410BFE23DC1598406A11698004EABFC072 |
| left / large-text | [annex-left-large-text-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-left-large-text-runtime.png) | PASS | 356B17F81545151231AD8F491CD4AC47B2840BC775171F0DB3950BDE7374F1E6 |
| right / normal | [annex-right-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-right-runtime.png) | PASS | ADB5BB1BE9EAA01F185F8AF50262A74EED42FB4657A42D93EAF2E58515524A43 |
| right / compact | [annex-right-compact-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-right-compact-runtime.png) | PASS | 950B554F8D802829E1347B6934ABE21DC113D85024361E934D7E671235C3E324 |
| right / large-text | [annex-right-large-text-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-right-large-text-runtime.png) | PASS | 8D3322AD65C42866BF7A89AB1F9A911908DCFAF72366E34DE1520202CF55494E |
| rear / normal | [annex-rear-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-rear-runtime.png) | PASS | 3B3244A39CE88184FEF661BCB385EA7E0979C986967E37066E308C9ADE724143 |
| rear / compact | [annex-rear-compact-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-rear-compact-runtime.png) | PASS | E345766DD5AB571A89A6654BEB971CCEFA39A863DF7C406471C1D475578FE0DD |
| rear / large-text | [annex-rear-large-text-runtime.png](../design/runtime/0.4.1/8d58a2d/annex-rear-large-text-runtime.png) | PASS | D01B4B16E2521E4643034AA87852128848814C753F12E66173E6B5934DAAD5A9 |

I also inspected the three normal empty-annex states: [restored left](../design/runtime/0.4.1/8d58a2d/restored-runtime.png), [restored right](../design/runtime/0.4.1/8d58a2d/restored-right-runtime.png) and [restored rear](../design/runtime/0.4.1/8d58a2d/restored-rear-runtime.png). Their exposed floors and junctions reveal no additional defect; all three pass. Their hashes are in the archive manifest. The three compact restored images were reviewed by the integration director, not independently inspected in this pass.

### Checks and accepted limits

- **Architecture and materials:** painted cap/body/rail details now remain coherent across rooms. End posts sit outside the visible open passage; there is no added step, central obstruction or bridge over plaster. The oak override and stocked tables remain visible in the occupied fixtures.
- **Painting:** the rear moon painting fits on the surviving wall segment without crossing the opening jamb at normal, compact or accessibility sizes.
- **Framing:** the rear cap remains below Calendar in all three sizes, including a small clear gap at accessibility text size. The compact rear room uses a smaller uniform view to fit the taller plan; it is still visually legible and does not require changing the original room proportions.
- **Native controls:** HUD, Calendar, primary CTA, secondary actions and BUILD/STOCK/OPEN labels remain visible and legible. At accessibility size the initial screenshot shows only part of the scrolling explanatory copy while retaining the primary action. That matches the allowed native scroll adaptation; this image review does not independently retest scrolling or touch interaction.
- **Non-blocking border limit:** left/right outer front corners sit very close to the viewport edge, particularly normal/accessibility and around a pixel-scale gap on compact. No usable floor, end post or control is visibly lost. A 6–8 point framing inset would provide more breathing room, but the integration director explicitly accepts the existing framing and free panning; no additional source change is required for this candidate.
- **Scope:** this is a visual decision based on twelve independently inspected images. Build, native interaction results and exact IPA verification remain separate integration evidence. The screenshots do not by themselves prove traversability, hit testing or arbitrary user pan/zoom positions.

No code, asset or screenshot was changed during QA. Only this report was updated. The following rejected review is historical and is not the current candidate decision.


## Historical first decision — rejected, 2026-09-21

Native evidence from app source `1cac2194d640986ae0c7ac113c1207f42cd063c0`, run `35657369361`, fails the selected visual direction. The annex opening, camera and native controls are usable in the three inspected normal-size states, but the annex still reads as a flat, separately attached cardboard model beside the original painted room.

The integration owner reports 131 passing native tests. That functional result does not establish visual fidelity. This review independently inspected three real XCTest attachments; the full normal/compact/accessibility capture matrix was not yet available at this decision.

## Evidence inspected

Device: iPhone 16 Pro. Each source PNG is 1206×2622. The durable [rejected-evidence archive](../design/runtime/0.4.1/1cac219-rejected/README.md) and [test summary](../design/runtime/0.4.1/1cac219-rejected/test-summary.json) preserve the original attachment provenance. The original attachment manifest associated all three with `ShopJourneyUITests/testDisplaysInEveryAnnexRemainSelectableAndStocked()`, before interaction, and records no associated test failure.

| Direction | Native attachment | SHA-256 | Decision |
| --- | --- | --- | --- |
| Left | [Rejected left](../design/runtime/0.4.1/1cac219-rejected/annex-left-runtime.png) | `C8A98D2A497CE546E1D6F534C510687FA06D501D3FA911915A99166BD950BB7C` | Reject visual finish |
| Right | [Rejected right](../design/runtime/0.4.1/1cac219-rejected/annex-right-runtime.png) | `B3F02CE48AD7B0F9A1C33ADC4F75C4CD8C810D3F56ACA060C23A4F52FBF9DC7A` | Reject visual finish |
| Rear | [Rejected rear](../design/runtime/0.4.1/1cac219-rejected/annex-rear-runtime.png) | `C9A95947AA041DAB765B05B07182050EFC805C20521A297E32588D46460C05A8` | Reject visual finish and painting overlap |

Governing references: [left v2](../design/approved/expansion-left-v2.png), [right v2](../design/approved/expansion-right-v2.png), [rear v3](../design/approved/expansion-rear-v3.png), with the original-projection and native-UI adaptations explicitly recorded in [APPROVALS.md](../design/APPROVALS.md). Original material comparison: [RepairedShopBackground.png](../design/assets/complete-game/RepairedShopBackground.png).

## Concrete findings

1. **All three: caps and corners lose the original painted volume.** Annex teal caps appear roughly one-third as thick as the starter's substantial rounded caps at the same scene scale. Sharp polygon mitres, a thin edge line and almost no bevel/front face replace the selected broad painted cap, rounded corners and contact shade. Simply matching the teal color or increasing a flat polygon's width will not satisfy the reference.

2. **All three: wall and floor surfaces look like an unlit separate asset.** Annex plaster is much lighter and more uniform than the warm original room. The teal wainscoting lacks the starter's dimensional rail and shared shaded treatment. Its brown floor/grout language is noticeably simpler and harsher than the main floor. The correct rectangular opening does not disguise the material discontinuity.

3. **All three: the architectural jambs lack the selected end-post treatment.** Left/right end junctions do not visibly articulate a substantial framed post; rear jambs resemble plain strips of paper. The reference has teal cap/base, a cream framed shaft and readable depth, outside the passage.

4. **Rear: MoonPainting overlaps the right opening jamb.** The painting projects left of the surviving right plaster segment into the jamb/passage. The saved decoration should remain on the surviving wall segment through a visual attachment clamp; no save migration or cell change is required by this finding.

The five-cell opening is visibly clear, the rear cap sits below Calendar, the same-level stone threshold is present, existing custom oak cells and occupied tables are visible, and the native HUD/preparation panel remain legible. These are passes for the inspected normal-size screenshots only. A still image does not independently prove hit testing or traversability; native interaction tests supply that separate evidence.

## Agreed repair direction

Keep the working map, opening mask, camera and UI. World owns the implementation. No new ImageGen output or bitmap edit was commissioned during this review.

Use native SKTexture crops of the preserved painted background for visible wall faces, caps and curved corners, so the new room shares the original material, bevels and local shading. Suggested source regions in the 853×1844 background, to verify during implementation:

- Horizontal cap approximately x150…690, y405…445, preserving its full bevel/front/shadow rather than a thin top sliver.
- Rear wall without the hanging lamp approximately x145…390, y444…630. Sample with care near the lamp glow and avoid repeating the lamp or transplanting a complete lighting field.
- Left rounded corner approximately x83…153, y405…483; mask its true silhouette natively to avoid a pasted rectangle of the brown backdrop. Mirror the corner's local geometry for the opposite side where appropriate.
- Reuse existing [FacadeCornerPost](../MagicShop/Resources/Assets.xcassets/FacadeCornerPost.imageset/corner-post.png) for the painted jamb shaft/cap/base. Its real alpha and relief already match the family. Preserve sensible proportions and place its feet outside passable cells.
- Sample the original floor at matching tile frequency with controlled warm shading, retaining persisted floor overrides and the flush threshold.

The old modular SideWallLeft cream sprite is not recommended for this repair: it lacks the required matching wainscoting and would retain the flat bright-face problem. New expansion-v2 materials remain preserved; the failed native use is recorded rather than passed as final.

## Acceptance criteria defined at the first review

The next native candidate must supply left/right/rear normal, compact iPhone and accessibility-text captures. Each of the nine states receives its own accept/reject result.

- Opening: no residual plaster, cap, hanging lamp, brown gap or raised floor strip crossing the five-cell passage.
- Architecture: matching physical wall height, broad painted cap thickness, rounded/beveled corners, readable jamb depth and a thin flush threshold.
- Material continuity: common warm plaster/teal/floor language and convincing contact shade; no light cardboard annex against a dark painted main room.
- Geometry: preserve the original main plate/projection, five-by-five annex and saved object/floor positions. Do not copy the generated rear master's wider main-room shape.
- Framing and usability: rear cap below Calendar, useful annex floor visible, native controls unchanged, labels and primary CTA reachable; scrolling at large text is permitted.
- Decoration: paintings/clocks stay visually on surviving wall segments and do not bridge the opening.

At this first review, status remained rejected pending corrected native images. The corrected source is reviewed separately above. The three initial attachments are preserved as failure evidence; no existing acceptance, artifact or reference was overwritten.
