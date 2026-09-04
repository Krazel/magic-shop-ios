# Magic Shop — Complete-game art

Prepared and checked: 2026-09-05.
Production route: built-in ImageGen, with explicit ImageGen correction passes where needed.
Status: selected by the project director under the owner's delegated visual authority. This record does **not** claim the owner separately reviewed and approved the new master image.

## Direction and complete-screen specification

The owner approved the three commerce mockups and then delegated further visual decisions to the game director. This package extends their elevated painted 2D cutaway, worn teal/cream architecture, terracotta floor, gold-edged dark teal panels and native English text. New art was prepared after generating a complete restored/expanded/decorated iPhone composition.

Current director-selected master:
[complete-game-master-v2.png](../design/proposals/complete-game/complete-game-master-v2.png)

- Actual generated canvas: 863×1823, portrait, English.
- SHA-256: `B8BA06DDE38BDBCF65608F11E9B2660F52092A8348A895A6D697067B3E6B98D2`.
- Represents a repaired shop, a small adjoining side room, six decor concepts, miniature customers and a fixed `Day 8 / 14:20 / Shop open` strip.
- Selected autonomously by the director on 2026-09-05, under the owner's delegation. No new owner question is pending.
- v2 corrects a misplaced charm in the left shelf into a potion, so depicted merchandise obeys table/shelf compatibility.
- The generator changed the requested 853×1844 canvas slightly during that correction. Keep native iPhone safe areas and existing world geometry; do not stretch the master into runtime art.
- The prior [v1](../design/proposals/complete-game/complete-game-master-v1.png), 853×1844, SHA-256 `32100A1AB80E3B6A850B4325C05B848FF4840E0AD55FC5AF2858A77F7E9F61CB`, remains preserved as history.
- Full initial/geometry prompts: [complete-game-master-prompt.txt](../design/proposals/complete-game/complete-game-master-prompt.txt).
- Final compatibility correction: [complete-game-master-v2-prompt.txt](../design/proposals/complete-game/complete-game-master-v2-prompt.txt).

The master is a complete design specification, never a flattened runtime screen. Exact map coordinates come from Core and World, not from counting generated tiles in the master. Original commerce references still govern their own panels and states.

## Runtime package and verification

Sources and exact prompts are in `design/assets/complete-game/`; each listed asset has a matching NEW imageset under `MagicShop/Resources/Assets.xcassets/`. All source/runtime hashes matched at delivery. All isolated sprites and the panel have real RGBA transparency, not a baked white or checkerboard background. The two intentional opaque textures are the complete repaired plate and the floor patch.

[Machine-readable manifest](../design/assets/complete-game/manifest.json)

| Imageset / source name | Actual pixels | Format | SHA-256 |
| --- | ---: | --- | --- |
| `AnnexFloorPatch` | 1254×1254 | RGB; opaque | `9673B529323972DBF8ACACBF81EB6DC561CAC39653325D7128C0983AE1EBFEE1` |
| `AnnexRoomBackground` | 1254×1254 | RGBA; corner alpha 0 | `2764AF61C0E2EBB69A39C703F6CD1E1BE16A8D279F3115D37DC856151F16FAD4` |
| `AnnexRoomRearBackground` | 1292×1218 | RGBA; corner alpha 0 | `D6E7CA2239035BF264EAA4A8D5AC01941CE9AD02CCF768DDB306EE5D155E32E5` |
| `CustomerGreen` | 1254×1254 | RGBA; corner alpha 0 | `5DB673BA84935D2A0FFC9291E923A40794F8CBC3C5439D31FF7A2784F224CB2B` |
| `CustomerGreenFront` | 1254×1254 | RGBA; corner alpha 0 | `4945B103BC5D69B80D2DF03C4A9D04A8BAB5397F0BDF78F771E703494FD4046D` |
| `CustomerPlum` | 1254×1254 | RGBA; corner alpha 0 | `4C4387F1F56C6F881B4CC297EFCA10507E6F43C29CE163DF1DD2A995122C280B` |
| `CustomerPlumFront` | 1145×1374 | RGBA; corner alpha 0 | `299A5C49BE68FD08DA369DE5F0BD733A95FD9D459361AB0013F93BDBA78C68AF` |
| `GlowPotion` | 1254×1254 | RGBA; corner alpha 0 | `A4BD7B3E97FC25CB7345ECB0CAF3EAEBEB4D8E409C2D3CAAC5623780D7920B41` |
| `LuckyCharm` | 1254×1254 | RGBA; corner alpha 0 | `E55139E3590D8FCAFDCCC3FE302FB06AEE34786668185C32AD7EF9A7E15B473D` |
| `OrnatePanel` | 1536×1024 | RGBA; corner alpha 0 | `65261D88C8B18CEDD2DE4DB4FCAFB0F36B2B3E388246777E3BC2815EF6694C84` |
| `PocketSpellbook` | 1254×1254 | RGBA; corner alpha 0 | `30B0B25CD8986F75AE5D3F59814607CD02A32B99A3D82CE05CAEE99315A37E9F` |
| `RepairedShopBackground` | 853×1844 | RGB; opaque | `339A80AEFE38973615D3B99BF8D2296352930532470482A49A4346849CBA8EEE` |
| `SimpleShelfSide` | 1024×1536 | RGBA; corner alpha 0 | `4CBD98DB57773E12E60B8AC11C343210A57ACB2DA2B62561BAEF914C84FC08A6` |

For any name above, the source is `design/assets/complete-game/NAME.png`, the prompt is `design/assets/complete-game/NAME-prompt.txt`, and the runtime copy is `MagicShop/Resources/Assets.xcassets/NAME.imageset/NAME.png`.

## Asset roles and rendering

- **AnnexFloorPatch**: Opaque 5×5 terracotta texture for native connection patches; no architecture.
- **AnnexRoomBackground**: 5×5 annex with open left side; mirror horizontally for the opposite side.
- **AnnexRoomRearBackground**: 5×5 annex with open front; rear expansion without rotating wall artwork.
- **CustomerGreen**: Green customer, back three-quarter view for entering/browsing.
- **CustomerGreenFront**: Same green customer, front three-quarter view for leaving.
- **CustomerPlum**: Plum customer, back three-quarter view for entering/browsing.
- **CustomerPlumFront**: Same plum customer, front three-quarter view for leaving.
- **GlowPotion**: Cyan potion stock/catalog art; table or shelf; one unit per slot.
- **LuckyCharm**: Gold clover charm stock/catalog art; table only.
- **OrnatePanel**: Blank dark teal/gold panel; native text and controls overlay it.
- **PocketSpellbook**: Purple spellbook stock/catalog art; shelf only.
- **RepairedShopBackground**: Repaired original room; same source canvas and architectural landmarks.
- **SimpleShelfSide**: Upright two-compartment shelf viewed laterally for side walls.

The frame contains no baked title, price, button or currency. Native text remains the authority for localization scope, Dynamic Type, VoiceOver, wrapping and state. Preserve the frame's outer ornament when stretching; evaluate corner/top cap insets in the actual rendered panel rather than assuming any rectangular crop is final.

Products remain separate overlays at fixture stock anchors. Keep one product on a table and no more than one in each of the two shelf slots. Catalog illustration sizes and tiny world sizes must differ naturally.

Characters have complete bodies and independent front/back orientations. Use back views for entering/moving toward the rear, front views for approaching the facade, and horizontal mirroring only where appropriate. Do not rotate a body bitmap upside down. These are pose sprites, not baked animation strips: travel, gentle movement, sales feedback and reduced-motion behavior remain native SpriteKit work. Use proportional scaling by visible character height; the canvases are not all square. World selected approximately 1.38 floor-cell height for a tiny customer.

SimpleShelfSide keeps the furniture upright with its open compartments facing into the room. Mirror for the opposite wall. Its 1024×1536 canvas and its foreshortened front must not be mistaken for a new furniture capacity or footprint. Native stock anchors need perspective-specific placement.

## Repair and expansion geometry

The existing `StarterShopBackground` remains untouched and is still the starter room. New repair artwork is a separate plate; there is no replacement of the approved source.

The repaired 853×1844 plate preserves the starter's architectural registration:

- Far floor edge: approximately (143,629) to (701,629).
- Near floor edge: approximately (106,1172) to (749,1172).
- Back outer teal wall top: approximately y405.
- Facade, centered entrance, two windows and sidewalk remain in place.

These landmarks were visually inspected; the World owner also inspected the plate and reported that it fits the current projection. This is not a pixel-identity claim. Cleaning changes floor/plaster microtexture and removes the three debris groups. World may reveal repaired regions from the new plate during partial repair and use the complete plate once repair is complete.

Core fixes exactly ONE annex of 5×5 cells, attached to the preserved 11×11 starter:

| Direction | Bounding map | Starter origin | Annex origin |
| --- | --- | --- | --- |
| Left | 16×11 | (5,0) | (0,3) |
| Right | 16×11 | (0,0) | (11,3) |
| Rear | 11×16 | (0,0) | (3,11) |

The union remains open across five cells. No new narrow corridor, enclosed wall across the connection or forced expansion direction is introduced.

AnnexRoomBackground has a fully open left side and three remaining boundaries. It can be mirrored for a left-side annex. AnnexRoomRearBackground has a fully open front and three walls; it avoids rotating the lateral wall art. Neither has an extra facade or main entrance.

Useful approximate source floor corners for native warp calibration:

- Side annex, 1254×1254: far (158,355)–(1010,355); near (98,1108)–(1094,1108).
- Rear annex, 1292×1218: far (218,338)–(1070,338); near (142,1125)–(1140,1125).
- A coarse read-only color probe on the side texture found the first broad terracotta row at y360, x172–996, and its last at y1104, x100–1076. These color extents are inside the geometric floor perimeter and must not replace corner calibration.

World owns exact placement, masking and its native mesh warp to the five mapped cells. A floor connection patch must cover the old shared wall at the open union so the art does not visually block a traversable path. AnnexFloorPatch contains only a full-bleed 5×5 terracotta pattern, no architectural boundaries.

## Six decorations

The six decor assets were delegated as an isolated package to the Core/content agent while this visual lane completed plates, panel and sprites. Their source root is `design/assets/complete-game/decor/`; names match Core:

- `PottedFern`: lush fern in a terracotta pot.
- `StarRug`: circular teal/gold textile with star motif, laid flat on the floor.
- `CrystalDisplay`: small violet crystal cluster on a restrained brass base.
- `WallClock`: round walnut/cream clock, wall-adjacent.
- `MoonPainting`: framed crescent-moon art, wall-adjacent.
- `BrassLantern`: small warm brass lantern.

All have 1×1 logical footprint and no merchandise capacity. The rug is a traversable floor decoration; clock and painting attach to walls. These rules come from Core, not from asset silhouette size. Their prompts, individual hashes and alpha QA are recorded separately in [DECOR-ART.md](DECOR-ART.md). This lane did not write or overwrite their files.

## Preservation and provenance

Untouched existing sources verified at delivery:

- `design/assets/first-slice/starter-shop-background.png`: `CBB8A68B876CF8B1EBF9D0FD64A3672195594B6271BD9DA342FC29A7DDF073B3`.
- `design/assets/first-slice/simple-shelf.png`: `B232233FA16FF816B9C0C1AB3C9F0CAC91B65A4F61D6BDF9659E108516384D0E`.

All assets in this lane were generated or corrected with the built-in ImageGen tool. No local Python, CLI image generator, image drawing script, alpha conversion, crop, resize or pixel painting was used. Final outputs were copied unchanged into the repository; source/runtime duplicates are deliberate source archival plus Xcode packaging.

The default ImageGen output directory is `C:/Users/dmkra/.codex/generated_images/01a06e65-3852-7053-a87d-2c481f877daf/`. Each selected source filename is retained in the machine manifest for provenance. All necessary final PNGs and prompts live in the repository; runtime never depends on that external folder.

Early RGB/checkerboard outputs of the panel, customer and annex were rejected and corrected/regenerated through ImageGen. They were never shipped as final transparent sprites. The initial full-depth annex master was also superseded by the compact annex concept. Failed experiments remain at their original generation paths and are not current runtime sources.

## Honest visual limits and next verification

- No real device/simulator capture was produced by this art lane. It does not claim final UI fidelity or a passing gameplay build.
- ImageGen retains the approved visual family but changes some tiny tile, plaster and wood details. The repaired plate has appropriate landmark registration, not demonstrated identical unchanged pixels.
- Annex terracotta is somewhat brighter and more ornamented than the original plate. Native placement/light treatment and the join must be inspected together in a real capture.
- Some alpha edges on annexes contain small red/green fringes visible when magnified over transparency. The World owner has observed them. Open-floor joins should cover those perimeter pixels; evaluate outer edges at actual iPhone scale before considering the scene visually final.
- Transparent PNG RGB channels can retain background colors even at alpha zero; actual alpha, not a misleading preview background, determined format acceptance.
- Front and back character drawings vary slightly in pose and proportions; preserve proportional height and select the correct orientation during movement. There are no hand-animated walking frames in this package.
- Safe areas, Dynamic Type, contrast, VoiceOver, gestures and reduced motion must be verified in native UI. No money, time or state is baked into runtime assets.
- Final integration must compare original approved commerce references and this chosen complete-game family against actual iPhone captures, correcting visible scale, seam, asset and overlay differences.

This lane wrote only new art/proposal paths, new imagesets and this document. It did not edit App, Core, World, the Xcode project, approved image archive, Git history or the Brain project record.

## App icon — source artwork and packaging handoff

Director-selected icon: an arched teal shop door in cream stone, warm gold light and a single cyan Glow Potion. No text, external rounded-corner mask, logo border or transparency.

- Source: [AppIcon-source.png](../design/assets/complete-game/AppIcon-source.png).
- Actual ImageGen size: 1254×1254, RGB PNG, fully opaque; requested size was 1024×1024.
- Source SHA-256: `F8774B69B6B0255BB304175F221DCD516D28CE3754F1FC8B3B8C67229F80D12C`.
- Exact prompt: [AppIcon-prompt.txt](../design/assets/complete-game/AppIcon-prompt.txt).
- Generated source: `exec-6e355a5e-fd5d-46e5-832c-232a8ba5684f.png`.
- ios-app-launch skill applied for icon preparation; the owner's delegated visual authority governs this choice.
- The project root owns the final technical normalization to opaque 1024×1024 and installation into `AppIcon.appiconset`, plus its Xcode build-setting reference. This art lane handed over the unchanged high-resolution source rather than repeatedly regenerating the same design for a resolution-only issue.
- Final intended source name after packaging: `design/assets/complete-game/AppIcon.png`; intended catalog path: `MagicShop/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. At this handoff these two final files are owned by the root task, not yet claimed verified by this lane.
- Root should record the final 1024×1024 hash after packaging. Preserve the 1254×1254 source and prompt.


## Final AppIcon packaging
Root packaged the ImageGen artwork as an opaque1024x1024 PNG using the reproducible native System.Drawing resizing script scripts/prepare-app-icon.ps1. No design content was changed. Source preserved as AppIcon-source.png; final source/runtime AppIcon.png SHA-256: 8569B8CE7B5F1D43AF528D4C44F97FD98D5B7C631AC558F9F821C26FECF5486D. Xcode AppIcon is linked for both app configurations.

