# Complete-game decoration art

Date: 2026-09-05. Six individual sprites selected under the owner's delegated complete-game design authority. These are autonomous production selections, not a claim of separate owner review of each sprite.

Visual reference inspected before generation: [complete-game-master-v1.png](../design/proposals/complete-game/complete-game-master-v1.png). The warm hand-painted 2D style uses terracotta, dark teal, walnut and antique gold. Generation and all raster corrections used the built-in ImageGen tool. No CLI fallback or programmatic raster editing was used. Final PNGs are unchanged copies of selected tool outputs.

## Delivered files

All six sprites have a 1254 × 1254 canvas, PNG color type 6 (RGBA), and a one-cell domain footprint. Canonical source files are in `design/assets/complete-game/decor/`; runtime copies are in `MagicShop/Resources/Assets.xcassets/<Asset>.imageset/<Asset>.png`. Each imageset has a universal entry in `Contents.json`.

| Asset | Canonical source | SHA-256 |
| --- | --- | --- |
| PottedFern | [PottedFern.png](../design/assets/complete-game/decor/PottedFern.png) | `16F0BC3F6DA4A268BBDD8D357F841D6150126498AE0555E6445CCAD7DA32EAEB` |
| CrystalDisplay | [CrystalDisplay.png](../design/assets/complete-game/decor/CrystalDisplay.png) | `7216802AF7DD9040EF1AFDC8ED7FC00AB836C1B5061527E930B43DE1A3E22C29` |
| WallClock | [WallClock.png](../design/assets/complete-game/decor/WallClock.png) | `D280C90FDD81C0E055ACB9A42085EEBA7B1290CF6A1CE1433CA9B731F7CCD034` |
| MoonPainting | [MoonPainting.png](../design/assets/complete-game/decor/MoonPainting.png) | `4351356418BC708035C07EDD003AFEC46734607C3F93E211F84FEFC5D1EA4096` |
| BrassLantern | [BrassLantern.png](../design/assets/complete-game/decor/BrassLantern.png) | `CCB585BA89E59D8B4315FF2D795010E624CC429331AB4B0B377BE102084944FD` |
| StarRug | [StarRug.png](../design/assets/complete-game/decor/StarRug.png) | `4EF1D8AD7FCA4D8532099B417D1673FE5EC397AFFB9ED80C9DA89C00783A9954` |

## Visual and transparency verification

Every final image was inspected visually. PNG headers and pixel values were inspected read-only with System.Drawing. Alpha was sampled on a 4-pixel grid (98,596 samples per image), and every pixel on all four canvas borders was checked for opaque clipping. All outputs have sampled alpha range 0–255 and zero border pixels with alpha above 128. No RGB checkerboard image is included. The following bounds are approximate sampled bounds for alpha above 16, not an exhaustive bounding-box calculation.

| Asset | Approximate alpha bounds (xMin, yMin, xMax, yMax) | Fully transparent samples | Opaque border pixels |
| --- | --- | ---: | ---: |
| PottedFern | 88, 24, 1160, 1180 | 53189 | 0 |
| CrystalDisplay | 236, 44, 1044, 1140 | 61710 | 0 |
| WallClock | 112, 72, 1144, 1132 | 44200 | 0 |
| MoonPainting | 132, 68, 1120, 1124 | 36745 | 0 |
| BrassLantern | 384, 28, 868, 1128 | 74601 | 0 |
| StarRug | 20, 24, 1228, 1208 | 27639 | 0 |

Runtime should account for transparent canvas margins when calibrating visible size. The lantern has a narrow silhouette (about 39% of canvas width), and the crystal occupies about 65%. The rug is a flat circular texture: the world renderer supplies its floor projection. Clock and painting are upright wall decorations and require the wall transform from the world renderer. These images alone do not verify device-scale composition; compare the integrated game captures against the master.

StarRug required six iterations. Earlier variants with an exterior brown halo, RGB checkerboard, or clipped border were rejected and are not included in the repository. The selected sixth variant is a detailed, non-luminous woven teal rug with gold stars and crescents, genuine transparent margins and a complete border.

## Reproducible generation record

Tool: `image_gen.imagegen` (built-in). Final outputs were copied from the tool's generated-images directory. The filenames below identify the selected generation; the canonical copies above are the durable project sources. All six final images were independent generations; the rejected rug correction chain is not consumed by the project.

### PottedFern

Selected tool output: `exec-88325ca0-1da4-439e-af79-4111e409b0ee.png`.

Exact prompt:

```text
Create a single TRANSPARENT-BACKGROUND PNG GAME SPRITE. Use case: stylized-concept. Asset type: one finished 2D decoration for an English iPhone magic-shop game. SQUARE canvas, actual transparent alpha channel everywhere outside the object, preserve transparent PNG output; no solid background, no painted checkerboard, no floor, no wall, no backdrop, no text or watermark. Match an ornate warm storybook fantasy cutaway shop: hand-painted 2D, defined dark brown contour edges, softly modeled volume, richly shaded but clean readable shapes, warm amber light from upper left, subdued dark teal and antique gold accents, slightly worn handmade materials. Elevated camera looking down at 45 degrees with verticals upright and front facing toward the viewer; no diamond-isometric rotation, no photorealism, no plastic 3D look. One isolated object centered, entirely visible, 7% transparent margin, small tight contact shadow only. Must remain legible as a 60–90px game object. Subject: one lush compact potted fern, matching a fern in a cozy old magic shop. A low round terracotta pot with a slightly rolled ochre rim, warm brown clay body and a narrow antique gold decorative band. Dense graceful rich green fern fronds arch outward and upward, with a clear tapered frond silhouette and individually painted leaflets. View the dark soil and pot opening from above. No flowers, no detached leaves, no surrounding plants. The pot is rounded and squat, fern about twice the height of the pot.
```

### CrystalDisplay

Selected tool output: `exec-f554ddd9-872c-413d-859c-dcd7f632d197.png`.

Exact prompt:

```text
Create a single TRANSPARENT-BACKGROUND PNG GAME SPRITE. Use case: stylized-concept. Asset type: one finished 2D decoration for an English iPhone magic-shop game. SQUARE canvas, actual transparent alpha channel everywhere outside the object, preserve transparent PNG output; no solid background, no painted checkerboard, no floor, no wall, no backdrop, no text or watermark. Match an ornate warm storybook fantasy cutaway shop: hand-painted 2D, defined dark brown contour edges, softly modeled volume, richly shaded but clean readable shapes, warm amber light from upper left, subdued dark teal and antique gold accents, slightly worn handmade materials. Elevated camera looking down at 45 degrees with verticals upright and front facing toward the viewer; no diamond-isometric rotation, no photorealism, no plastic 3D look. One isolated object centered, entirely visible, 7% transparent margin, small tight contact shadow only. Must remain legible as a 60–90px game object. Subject: a small cluster of exactly three faceted violet amethyst crystals on a low round antique bronze display base. Largest crystal in center, two shorter crystals at sides, deep purple shadow planes, luminous lavender and pink top facets, crisp clear faceted silhouette. Heavy squat stepped bronze plinth with warm worn gold rim, top surface visible from above. Crystals fit tightly within the base footprint. The glow stays INSIDE the crystal facets, no external aura, smoke, sparkles or background.
```

### WallClock

Selected tool output: `exec-1b1e3391-38e3-4114-bfca-30547e84f65d.png`.

Exact prompt:

```text
Create a single TRANSPARENT-BACKGROUND PNG GAME SPRITE. Use case: stylized-concept. Asset type: one finished 2D decoration for an English iPhone magic-shop game. SQUARE canvas, actual transparent alpha channel everywhere outside the object, preserve transparent PNG output; no solid background, no painted checkerboard, no floor, no wall, no backdrop, no text or watermark. Match an ornate warm storybook fantasy cutaway shop: hand-painted 2D, defined dark brown contour edges, softly modeled volume, richly shaded but clean readable shapes, warm amber light from upper left, subdued dark teal and antique gold accents, slightly worn handmade materials. Elevated camera looking down at 45 degrees with verticals upright and front facing toward the viewer; no diamond-isometric rotation, no photorealism, no plastic 3D look. One isolated object centered, entirely visible, 7% transparent margin, small tight contact shadow only. Must remain legible as a 60–90px game object. Subject: a small round wall clock for the rear wall of the magic shop. Deep walnut wooden outer case, narrow aged brass rim, warm cream dial with twelve clear dark hour tick marks and two dark elegant clock hands reading roughly ten past ten. No numerals, no words, no pendulum, no legs, no wall segment. Face nearly front-facing, with only a subtle elevated top-edge view showing the wooden case depth. The whole clock is a simple compact circle, one complete isolated object with actual transparency outside its outer rim.
```

### MoonPainting

Selected tool output: `exec-13afa526-f366-4cf8-a45a-acab08e2d882.png`.

Exact prompt:

```text
Create a single TRANSPARENT-BACKGROUND PNG GAME SPRITE. Use case: stylized-concept. Asset type: one finished 2D decoration for an English iPhone magic-shop game. SQUARE canvas, actual transparent alpha channel everywhere outside the object, preserve transparent PNG output; no solid background, no painted checkerboard, no floor, no wall, no backdrop, no text or watermark. Match an ornate warm storybook fantasy cutaway shop: hand-painted 2D, defined dark brown contour edges, softly modeled volume, richly shaded but clean readable shapes, warm amber light from upper left, subdued dark teal and antique gold accents, slightly worn handmade materials. Elevated camera looking down at 45 degrees with verticals upright and front facing toward the viewer; no diamond-isometric rotation, no photorealism, no plastic 3D look. One isolated object centered, entirely visible, 7% transparent margin, small tight contact shadow only. Must remain legible as a 60–90px game object. Subject: a small square framed magical painting to hang on the shop wall. Substantial layered antique gold and dark walnut frame, slight wear on its corners. Inside the frame: dark midnight teal sky, one large elegant golden crescent moon facing right, and five tiny gold stars. No scenery, no planets, no landscape, no writing. Frame nearly front-facing, subtle raised upper-edge depth consistent with elevated cutaway camera. Clearly readable moon at 60px. No external glow or surrounding wall, all space outside the complete frame is actually transparent.
```

### BrassLantern

Selected tool output: `exec-11a6aaa5-8b79-4bdb-812d-92c474cf677c.png`.

Exact prompt:

```text
Create a single TRANSPARENT-BACKGROUND PNG GAME SPRITE. Use case: stylized-concept. Asset type: one finished 2D decoration for an English iPhone magic-shop game. SQUARE canvas, actual transparent alpha channel everywhere outside the object, preserve transparent PNG output; no solid background, no painted checkerboard, no floor, no wall, no backdrop, no text or watermark. Match an ornate warm storybook fantasy cutaway shop: hand-painted 2D, defined dark brown contour edges, softly modeled volume, richly shaded but clean readable shapes, warm amber light from upper left, subdued dark teal and antique gold accents, slightly worn handmade materials. Elevated camera looking down at 45 degrees with verticals upright and front facing toward the viewer; no diamond-isometric rotation, no photorealism, no plastic 3D look. One isolated object centered, entirely visible, 7% transparent margin, small tight contact shadow only. Must remain legible as a 60–90px game object. Subject: one compact freestanding brass lantern standing on its own flat hexagonal brass foot. Warm burnished antique brass ribs, amber glass panes containing one small glowing candle, tapered ornate brass roof, delicate round carrying loop. Elevated view reveals the roof facets, with vertical body upright. Rich golden highlights and darker old-brass shading, hand-painted and lightly worn. Warm light is confined to the amber glass, no broad exterior glow, no sparks, no floor patch, no chain or wall hook. One complete isolated lantern, about 1.4 times as tall as its widest body.
```

### StarRug

Selected tool output: `exec-10c79a13-2fe9-4a9b-a032-8999d697b28f.png`.

Exact prompt:

```text
Create a single TRANSPARENT-BACKGROUND PNG GAME SPRITE. One flat circular dark teal woven rug with an antique gold border and a restrained ring of small golden stars and crescent moons. Top-down floor decal, isolated complete round silhouette centered on a square transparent canvas with 10 percent clear margin on every side. Warm storybook 2D hand-painted style with fine woven fabric texture and subdued gold accents, matching a cozy old magical shop with dark teal wood and terracotta floors. The rug itself is non-luminous. Absolutely NO cast shadow, glow, halo, light spill or colored pixels beyond its circular sewn edge. Every outside pixel must be real alpha transparency, not a black or white background and not a checkerboard. Keep every part of the border in frame. The game will project this flat circular texture onto the floor.
```

