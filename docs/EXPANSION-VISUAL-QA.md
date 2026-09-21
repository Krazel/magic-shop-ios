# Expansion visual QA

## Current decision — rejected, 2026-09-21

Native evidence from app source `1cac2194d640986ae0c7ac113c1207f42cd063c0`, run `35657369361`, fails the selected visual direction. The annex opening, camera and native controls are usable in the three inspected normal-size states, but the annex still reads as a flat, separately attached cardboard model beside the original painted room.

The integration owner reports 131 passing native tests. That functional result does not establish visual fidelity. This review independently inspected three real XCTest attachments; the full normal/compact/accessibility capture matrix was not yet available at this decision.

## Evidence inspected

Device: iPhone 16 Pro. Each source PNG is 1206×2622. The attachment [manifest](../outputs/ci/35657369361/diagnostics/attachments/manifest.json) associates all three with `ShopJourneyUITests/testDisplaysInEveryAnnexRemainSelectableAndStocked()`, before interaction, and records no associated test failure.

| Direction | Native attachment | SHA-256 | Decision |
| --- | --- | --- | --- |
| Left | [C6D60484-1197-4AFC-A9F1-F41A09CDDAB9.png](../outputs/ci/35657369361/diagnostics/attachments/C6D60484-1197-4AFC-A9F1-F41A09CDDAB9.png) | `C8A98D2A497CE546E1D6F534C510687FA06D501D3FA911915A99166BD950BB7C` | Reject visual finish |
| Right | [12EBBFE6-633E-4C6B-9F7E-E72C52A236A8.png](../outputs/ci/35657369361/diagnostics/attachments/12EBBFE6-633E-4C6B-9F7E-E72C52A236A8.png) | `B3F02CE48AD7B0F9A1C33ADC4F75C4CD8C810D3F56ACA060C23A4F52FBF9DC7A` | Reject visual finish |
| Rear | [2852223E-FF47-4C3B-862D-AE8BC559223D.png](../outputs/ci/35657369361/diagnostics/attachments/2852223E-FF47-4C3B-862D-AE8BC559223D.png) | `C9A95947AA041DAB765B05B07182050EFC805C20521A297E32588D46460C05A8` | Reject visual finish and painting overlap |

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

## Next acceptance matrix

The next native candidate must supply left/right/rear normal, compact iPhone and accessibility-text captures. Each of the nine states receives its own accept/reject result.

- Opening: no residual plaster, cap, hanging lamp, brown gap or raised floor strip crossing the five-cell passage.
- Architecture: matching physical wall height, broad painted cap thickness, rounded/beveled corners, readable jamb depth and a thin flush threshold.
- Material continuity: common warm plaster/teal/floor language and convincing contact shade; no light cardboard annex against a dark painted main room.
- Geometry: preserve the original main plate/projection, five-by-five annex and saved object/floor positions. Do not copy the generated rear master's wider main-room shape.
- Framing and usability: rear cap below Calendar, useful annex floor visible, native controls unchanged, labels and primary CTA reachable; scrolling at large text is permitted.
- Decoration: paintings/clocks stay visually on surviving wall segments and do not bridge the opening.

Status remains rejected until corrected native images pass. The three initial attachments are preserved as failure evidence; no existing acceptance, artifact or reference was overwritten.
