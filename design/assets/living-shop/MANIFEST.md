# Living Shop 0.3 runtime art

Selected autonomously by project direction on2026-09-05 under the owner's visual delegation. This does not claim separate owner review. Built-in ImageGen only for new raster generation; no CLI fallback and no local pixel editing. The three full-screen masters were created first in ../../proposals/living-shop/.

| Runtime name/source | Size | Encoding | SHA-256 |
|---|---|---|---|
| FloorWarmOak.png |1254×1254|RGB opaque|8D876943117F60D1DB3A284FEEE7841F95913E6844544DAB4B0FCE250A3D3D59|
| FloorCheckerStone.png |1254×1254|RGB opaque|B06B3C4B6107B7B4DACC80A3A2BC561B0B47590C197BFA30DC25A51D55F7A4B5|
| DustPatch.png |256×229|RGBA real alpha|91D1205C5F5037EEC04EBDDDB74C0806455625C475DDBAF984BDF2F57516B329|
| FloorTerracotta.png |256×256|RGB opaque|CF0B041D3620395A8CAD82B87D85D5FAC84E3777C9484B543217795615158FF7|

Matching imagesets: ../../../MagicShop/Resources/Assets.xcassets/{FloorWarmOak,FloorCheckerStone,DustPatch,FloorTerracotta}.imageset/. Each PNG copy is byte-identical to its source. Universal images, no scale metadata imposed; World sets render size explicitly.

FloorWarmOak: exact prompt FloorWarmOak-prompt.txt. Built-in source exec-0e8ae2bd-802c-4fae-b3ec-e726e364530a.png. Full-bleed square overhead material with approximately6horizontal plank rows, soft grain, staggered joints, uniform lighting; generator returned1254square despite requested1024. Project onto a floor cell; no geometry or perspective baked into the source. Warm honey color is slightly stronger than the restrained initial prompt but harmonizes with terracotta.

FloorCheckerStone: exact prompt FloorCheckerStone-prompt.txt. Built-in source exec-c75a372e-9dda-4475-8d5b-1848cb4545df.png. Exactly2×2equal square subtiles: cream at top-left/bottom-right, muted teal in remaining corners. Use whole texture per game cell; it already alternates, no extra parity rule required. Fine physical grout and painterly stone; no UI, rubble, shadows, perspective or outside padding.

Both floor prompts request seamless repeat in both axes. Visual inspection confirms continuous flat material direction and repeatable plank/stone pattern. No claim of edge-pixel identity or final runtime seam QA is made: World will project and review them at actual cell size. Painted seams are intentional physical material joints, not a placement grid.

DustPatch is an authorized reuse, not newly generated. Source: ../first-slice/modular/floor/terracotta-stain-decal.png; original remains untouched. Provenance and pinned hash: ../../ASSET-INVENTORY.md. No new generation prompt applies. Original exact generation prompt is not newly reconstructed or invented. PNGcolorType6, alpha0at corners and255at center; visual inspection confirms soft irregular painted stain with transparent exterior, no checkerboard or white matte. Render as a small unobtrusive floor decal, about0.2–0.4opacity as a starting point; runtime scales/warps and uses native particle specks for sweep feedback. Do not overlay fully opaque broad stains on furniture or UI.

FloorTerracotta was subsequently authorized as a fourth alias in this lane: byte-identical copy of ../first-slice/modular/floor/terracotta-tile-base.png, matching existing WornTerracottaTile. No new generation or reconstructed prompt. Opaque RGB256×256; all four corner alpha values255. It preserves the original painted cell border. No prior approved or runtime PNG was replaced. Original source paths from generated_images are also recorded in manifest.json; canonical consumed files are the repo copies above.
