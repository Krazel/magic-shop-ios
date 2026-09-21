# Expansion architecture art — 2026-09-21

The existing five-by-five annex looked attached to the shop as a low platform. The selected replacement is a contiguous exhibition room: full-height cream plaster and teal walls, an unobstructed five-cell opening, end jambs and a thin pale-stone threshold on the same floor level. The main painted room, its eleven-by-eleven domain, saved object positions and existing flooring choices remain authoritative.

The project director selected the three references under the owner's explicit delegated design authority. This records director selection, not a new individual owner review. Canonical copies and the governing adaptations are in [design/APPROVALS.md](../design/APPROVALS.md).

## Selected complete references

All three are 851×1848 opaque RGB, English, portrait iPhone compositions. The original generation outputs and every rejected iteration are preserved.

| State | Source proposal | Canonical reference | SHA-256 |
| --- | --- | --- | --- |
| Left annex | [left-alcove-v2.png](../design/proposals/expansion-v2/left-alcove-v2.png) | [expansion-left-v2.png](../design/approved/expansion-left-v2.png) | `39FA3296B7EC3164823860153121F7FA58202193A6C08EAE190D3B684D98FA07` |
| Right annex | [right-alcove-v2.png](../design/proposals/expansion-v2/right-alcove-v2.png) | [expansion-right-v2.png](../design/approved/expansion-right-v2.png) | `1DAB158AE993CEE419FD7A140D4A01577AE1D51C0681EFF186AB0C71673D17B9` |
| Rear annex | [rear-alcove-v3.png](../design/proposals/expansion-v2/rear-alcove-v3.png) | [expansion-rear-v3.png](../design/approved/expansion-rear-v3.png) | `CC55FD083BEDCD9D2D5C3AF4CEE940D381B8291DE7DBA699C15BDFD4A97E7DE8` |

The left reference edits the real [0.4 freeplay capture](../design/runtime/0.4/a701788/freeplay-runtime.png). The right and rear references use the corresponding preserved 0.2 runtime geometry as input plus the selected current left reference for UI and art. Their exact prompts are adjacent `.prompt.txt` files; the [machine-readable provenance](../design/proposals/expansion-v2/manifest.json) records every input and source generation filename.

## Runtime material inventory

Each source is 1254×1254, opaque 24-bit RGB, full-bleed, without alpha or perspective. ImageGen was asked for square 1024 output and returned 1254; the originals are retained without resampling. These are independent flat surfaces; World projects them onto separate floor, vertical face, cap and threshold planes.

| Imageset / source filename | Material and use | SHA-256 |
| --- | --- | --- |
| AnnexFloorTerracotta | Top-down field of exactly 5×5 terracotta tiles, narrow grout and small pressed corner details. Map the entire image across the entire annex, not one image per cell. | `60A929821F1839EEF6331F33ACBF9DBBF73B08CD8A16C68D44BD630756AC7D39` |
| AnnexWallPlasterTeal | Front-facing cream plaster above teal vertical wood wainscoting and a fine worn brass rail. Map onto vertical wall faces independently of the floor. | `51A6F982CC17C3568474D16800FA320EA8129FF64CCA9F1781F0C608EC4AAC00` |
| AnnexWallCapTeal | Top-down mottled teal painted stone, restrained wear, no baked side faces. Use for thick wall caps and matching jamb caps. | `40ED2DB096C327434ABB849023D8C25AAEDAD3598B67E1CB5517A7438E880999` |
| AnnexThresholdStone | Top-down warm ivory stone with six understated strips. Use for a narrow, flush threshold across the full opening. | `F0653DC1F3992AC8C5CCD1C1AB37C873151AAEB1EB7415352137A384151DF486` |

Sources and exact prompts: [design/assets/expansion-v2](../design/assets/expansion-v2/). Matching PNG copies ship in new `MagicShop/Resources/Assets.xcassets/<Name>.imageset/` directories with universal Contents.json entries. Existing annex sprites and background plates remain preserved.

Visual QA of the material sources found no UI, object, perspective, outer frame, transparency fringe or directional cast shadow. The floor contains exactly twenty-five physical tiles; its grout is part of the material, not a placement grid. The wall output's upper rail begins around source y790/1254, so teal occupies approximately 37% including rails, rather than the prompted 30%. World may remap the two vertical bands to align the original main room's wainscoting; no source bitmap edit was made. Uniform diffuse base textures rely on native scene shading for the shared warm light. Pixel-perfect seamless repetition is not asserted; the whole floor field is used once per annex.

## Geometry agreement with World

| Direction | Annex origin in expanded map | Starter origin | Full opening |
| --- | --- | --- | --- |
| Left | (0,3) | (5,0) | x=5, y=3…8 |
| Right | (11,3) | (0,0) | x=11, y=3…8 |
| Rear | (3,11) | (0,0) | y=11, x=3…8 |

The floor footprint, cells and save data do not change. All five passage cells remain traversable. Jamb feet sit at the two endpoints outside usable floor; there is no center pillar, narrow door, lintel, step or raised platform. Remove the old shared wall over its entire vertical height within the opening. A horizontal floor patch must not cover an unremoved vertical plaster wall.

Keep the main plate source intact. Its rear wall height is approximately 224 source pixels, from floor y629 to cap y405 in the 853×1844 background, approximately 4.5 projected tile heights. Extrude annex walls independently to match this physical height instead of warping a complete room raster as floor. Preserve the starter's near/front cutaway and use a low matching rim there. Persisted selected floor tiles remain above the annex base material.

## Fidelity limits and native adaptations

Left v1 was rejected for a half-height annex wall; v2 raises the cap about 90 pixels while retaining its floor. Right v1 required a further 36–40 pixel rise; v2 supplies that full-height wall. Rear v1 established the clean opening but shrank and lowered the native panel; v2 failed to correct that. Rear v3 restores the current panel and navigation composition.

ImageGen resynthesizes some unchanged scene detail. In particular rear v3 widens the main room compared with the existing projection. That widening is explicitly not an implementation instruction: preserve the main room's original eleven-by-eleven projection, geometry and painted source. The selected references govern architectural material, height, clean connection and atmosphere. Existing shopkeeper references continue to govern native UI, safe areas, typography, truthful state, accessibility and panel proportions.

A uniform camera zoom/translation may fit each orientation below Calendar, especially the rear wall. Do not nonuniformly stretch the room or alter cells to match a generated image. World may extend behind the preparation panel; shrinking native controls to expose the facade is not allowed.

## Verification and remaining evidence

Four material PNGs were visually inspected. All are opaque RGB and 1254 square; every runtime PNG has the same SHA-256 as its source, and each imageset JSON resolves to its PNG. All eleven generated outputs have exact prompt files and recorded provenance. No existing art was overwritten, no image was edited through code, and this lane changed no App/Core/World source.

Native build and screenshot verification belongs to integration. At this art handoff comparable new runtime captures are pending; source preparation does not establish final visual parity. Compare normal and compact left/right/rear states: floor and main furniture fixed, no ghost wall across the opening, equal apparent physical wall height, continuous warm material treatment, unobstructed five-cell passage, rear cap below Calendar, current native panels unchanged, and saved custom floors visible.
