# Magic Shop — First-slice asset inventory

Status: clean background plate selected for current runtime on 2026-08-27 after
the owner rejected the assembled modular result. Catalog v3 and placement v2
remain approved. The approved visual family remains the elevated cutaway camera,
compact square starter room, worn teal/cream architecture, terracotta floor and
dim recoverable atmosphere.

The current runtime plate contains only the environment; HUD, controls, text,
grid logic and furniture remain native or separate overlays.

## Runtime asset roots

- Existing furniture: `design/assets/first-slice/`.
- Current visible environment: `design/assets/first-slice/starter-shop-background.png`.
- Preserved dormant modular environment: `design/assets/first-slice/modular/`.
- Visual QA sheets: `outputs/magic-shop-runtime-kit-*.png`.

## Existing reusable assets

| Asset | File | Pixels | Format | SHA-256 | Runtime role |
| --- | --- | ---: | --- | --- | --- |
| Current clean environment plate | `design/assets/first-slice/starter-shop-background.png` | 853 x 1844 | RGB PNG | `CBB8A68B876CF8B1EBF9D0FD64A3672195594B6271BD9DA342FC29A7DDF073B3` | Current visible runtime environment. It contains no HUD or controls; furniture and interaction remain separate overlays. |
| Basic Display Table 1x1 | `design/assets/first-slice/basic-display-table-1x1.png` | 802 x 849 | RGBA PNG | `E840C4B750D915F6F197F7759DFDE579AA20B7978D7E75CF247BF618FF796B0A` | Approved `$50` one-product display unit; logical footprint exactly one cell. |
| Simple Shelf | `design/assets/first-slice/simple-shelf.png` | 762 x 1036 | RGBA PNG | `B232233FA16FF816B9C0C1AB3C9F0CAC91B65A4F61D6BDF9659E108516384D0E` | Approved vertical two-compartment shelf; `$150`, capacity two, logical footprint 2x1 against a wall. |

## Preserved modular floor (not currently rendered)

Each opaque tile represents one logical cell. Assemble an 11 x 11 square
before adding walls or furniture.

| Asset | Pixels | Format | SHA-256 | Function |
| --- | ---: | --- | --- | --- |
| `modular/floor/terracotta-tile-base.png` | 256 x 256 | RGB | `CF0B041D3620395A8CAD82B87D85D5FAC84E3777C9484B543217795615158FF7` | Primary worn terracotta cell. |
| `modular/floor/terracotta-tile-variant-a.png` | 256 x 256 | RGB | `21406E40C72BADD65B51D18EA027AF1B09AAE56730EBCABCC0148EBC7A40B6B7` | Quiet grain variant. |
| `modular/floor/terracotta-tile-variant-b.png` | 256 x 256 | RGB | `B5C61FA14D053C3D0470D1B03F0E9B804251FCACC7034AD3281FDEA91818D45A` | Quiet abrasion variant. |
| `modular/floor/terracotta-crack-decal.png` | 193 x 256 | RGBA | `F724B579EFD6B0AABFC659333747111FA1FDADA09841FABA37480B069088CB2C` | Optional one-cell hairline crack overlay. |
| `modular/floor/terracotta-stain-decal.png` | 256 x 229 | RGBA | `91D1205C5F5037EEC04EBDDDB74C0806455625C475DDBAF984BDF2F57516B329` | Optional one-cell dusty stain/scuff overlay. |

Suggested distribution: roughly 55% base, 25% variant A and 20% variant B.
Do not rotate tiles because their painted bevel lighting is directional. Mirror
sparingly if more variation is needed. Place the crack and stain explicitly,
at reduced opacity, rather than randomly on every run.

## Walls, teal base and cutaway caps

| Asset | Pixels | Format | SHA-256 | Function |
| --- | ---: | --- | --- | --- |
| `modular/walls/rear-plaster-panel.png` | 256 x 512 | RGB | `DB178BD2ADD004862E70AA281D5D97A05F229B4613D55950B275601BB8500E0F` | One rear-wall plaster unit; repeat across the eleven-cell back edge. |
| `modular/walls/side-wall-left.png` | 231 x 1024 | RGBA | `21E4B2FF5D8ECF1FE44363585564A9AF68A9BEFD253175C31F7AACEF04BE8379` | Full left interior side-wall strip for the eleven-cell depth. |
| `modular/walls/side-wall-right.png` | 249 x 1024 | RGBA | `703995B557088E1F32B0A92030844704830080772E34A754BBA7958720E9685F` | Full right interior side-wall strip for the eleven-cell depth. |
| `modular/walls/teal-baseboard-rear.png` | 1024 x 277 | RGBA | `89388815F4B5862F99B6AA1B0272B097A5473251BCC8B650A2FEC3E8F7736B4E` | Full worn teal rear wainscot/baseboard layer. |
| `modular/walls/cutaway-cap-rear.png` | 1024 x 137 | RGBA | `EE154E9AF2BEEA40990072F7280E8178B721BFCB413CC3D2E675256CE675AD66` | Full rear horizontal teal cutaway cap. |
| `modular/walls/cutaway-cap-left.png` | 716 x 939 | RGBA | `5F1111656CC765B7132AFADCC40A480FE7155D70FBCD6B3456CB6CF6B5634DB0` | Full left side teal cap with front rounded end. |
| `modular/walls/cutaway-cap-right.png` | 580 x 1024 | RGBA | `A855F29C40C3C20773B12407D840EB71AA8E76EA18CAB8D983510FBAF2E7BF5E` | Full right side teal cap with front rounded end. |

The rear plaster panel is the only wall texture intended to repeat. The side
wall and side cap art are complete strips and must be scaled uniformly as a
pair to the same eleven-cell depth; do not tile them segment by segment.

## Facade

| Asset | Pixels | Format | SHA-256 | Function |
| --- | ---: | --- | --- | --- |
| `modular/facade/window-bay.png` | 1024 x 843 | RGBA | `64F05114D6F5EDA0EE747278B02A9F6496C52E6354589DD499DDE54C74886DF5` | Dusty window bay; use once left and a horizontal mirror on the right. |
| `modular/facade/entrance-bay.png` | 705 x 959 | RGBA | `61F856112B75205699F14F5481480BCBCEE0D79E631E2664C09F8E507FF78F0B` | Central arched teal door, trim and doorstep. |
| `modular/facade/corner-post.png` | 207 x 1024 | RGBA | `6809ED14BFAD17A8DC609B4C945D236F0CC332DC857168D184AEE4F6583CF3B3` | Reusable outer post and seam cover; mirror for the right end. |

Window and entrance bays include their own immediate trim. Slightly overlap
adjacent trim behind the corner/seam posts rather than leaving visible gaps.
Keep the entrance centered on the square floor and both windows symmetric.

## Lamp and debris decals

| Asset | Pixels | Format | SHA-256 | Function |
| --- | ---: | --- | --- | --- |
| `modular/props/hanging-lamp.png` | 374 x 768 | RGBA | `A054019A9534A12111A4CEE97D76A42E77E3C96FB1F1AF42864040894E11E48E` | Rear-center lamp sprite with compact translucent warm glow. |
| `modular/props/debris-plaster.png` | 512 x 412 | RGBA | `B7E6A143D3B32D264565813E28235922A2FB7540846C94B585EDE5F02DD878C1` | One small plaster-rubble cluster. |
| `modular/props/debris-papers.png` | 466 x 512 | RGBA | `D3FB0C60F804B6A4298C19AEBD53F4D3C4A78DC4FE602BD2C7697E6177EF5BC3` | One cluster of unreadable dusty paper scraps. |
| `modular/props/debris-wood-slats.png` | 512 x 310 | RGBA | `2AA7EC29501AAC715C7B61C2545F4E52681F81AB0909B21A4D464FC040FAE934` | One short diagonal bundle of deteriorated slats. |

## Dormant modular mounting reference

1. Create the square 11 x 11 floor from the three terracotta tiles.
2. Add crack/stain decals inside selected cells, below furniture and grid UI.
3. Place eleven rear plaster panels along the back edge.
4. Place left and right full side-wall strips along the square floor depth.
5. Add the rear teal baseboard over the bottom of the rear plaster.
6. Add rear, left and right cutaway caps above their corresponding walls.
7. Assemble the front facade: mirrored corner posts at the ends, left window,
   centered entrance and mirrored right window. Resolve joins by overlap.
8. Hang the lamp centered on the rear wall; apply runtime light separately if
   desired, without enlarging the sprite glow.
9. Place the three debris clusters in fixed authored cells.
10. Place table/shelf and later stock above the floor/debris but behind fixed UI.
11. Draw placement grid, selection tint and all HUD/panels natively at runtime.

## Visual QA sheets

| Preview | Pixels | SHA-256 |
| --- | ---: | --- |
| `outputs/magic-shop-runtime-kit-floor-preview.png` | 1536 x 1024 | `27929CECE4FF577B326F845CD91A0D047D4C9B185FC3301EFD0638D5AD9A745A` |
| `outputs/magic-shop-runtime-kit-floor-11x11-preview.png` | 1408 x 1408 | `12C0A0244F7C8994929950FCA443DEF0619B43D4D93CCDC6EC01E338B13B3FAD` |
| `outputs/magic-shop-runtime-kit-architecture-preview.png` | 1536 x 1024 | `C5D03EAE85E62DAD1E3BBA05DD772745F8548FADA5F26619FDC6F3E224ACE04F` |
| `outputs/magic-shop-runtime-kit-facade-preview.png` | 1536 x 1024 | `D0EFB6DB868C5BBDD0986E8908BCA4A9EDC3DEABB0F1BDF595DACE87E1394A62` |
| `outputs/magic-shop-runtime-kit-props-preview.png` | 1536 x 1024 | `F89D532F92EA1145B3F0D4772DE6FF2F2A8E3E5AB6D6CBE009B6C8DC2B874017` |

## Build natively

Do not create or ship raster duplicates for HUD, product cards, Build panel,
category tabs, buttons, balance/name capsules, text, prices, grid, selection
highlight, valid/invalid placement effects, safe-area backdrop or accessibility
states. The world layer pans/zooms; native UI remains fixed.

## Limits

- The kit reproduces the approved first-slice room. It does not include clean,
  repaired, recolored or expanded-room variants.
- The side-wall/cap pairs and facade bays require one implementation-time scale
  calibration against the approved screenshot; their internal proportions must
  remain locked after calibration.
- The rear plaster unit will reveal repetition if all eleven copies use the
  same orientation. Alternating a horizontal mirror is allowed; arbitrary
  rotation is not.
- The crack has light clay chips and the stain reads as pale dust at full
  opacity. Runtime opacity should stay restrained to match the approved room.
- Lamp illumination, collision, z-order, wall attachment, merchandise sockets
  and camera math are runtime concerns, not embedded in these PNGs.
- No text, buttons or UI raster are included.

## Provenance

All new raster art was prepared with the built-in image-generation workflow,
using the approved Magic Shop images as local style/camera references. Opaque
checkerboard previews were extracted locally to verified RGBA assets. No
approved file, Brain record, application code or project configuration was
modified.
