# Magic Shop — Visual Approvals

## Architectural expansion correction — 2026-09-21

The owner explicitly rejected the attached-looking annex and requested a
different solution. The director selected a contiguous showroom with a wide
opening, full-height cream/teal walls and a flush pale-stone threshold under the
owner's standing delegated visual authority. This is not a claim that the owner
reviewed the generated image individually. The first, short-walled proposal is
retained as rejected history in `design/proposals/expansion-v2/`.

- State: restored shop with left annex, preparation, English iPhone portrait.
- Current canonical image: `design/approved/expansion-left-v2.png`, 851×1848.
- Selected: 2026-09-21, director under explicit delegation.
- SHA-256: `39FA3296B7EC3164823860153121F7FA58202193A6C08EAE190D3B684D98FA07`.
- Supersedes the previous complete-game annex architecture only. Original
  starter shop, native controls and historical images remain preserved.
- Invariants: five-cell traversable opening; existing floor footprint and save
  positions; wall extrusion independent of floor perspective; jambs at endpoints
  outside the usable floor; no step, narrow doorway or central obstruction.
- Native adaptations: factual state text and furnishings, camera fit for each
  orientation, compact/Dynamic Type panel scrolling and original native HUD.
  Minor generated resynthesis of unchanged starter artwork is not a requested
  replacement of the original preserved plate.
- Materials: `design/assets/expansion-v2/`; provenance in
  `docs/EXPANSION-ART.md`. Comparable runtime captures pending.

The right orientation uses the same architectural contract, independently
reviewed before implementation: `design/approved/expansion-right-v2.png`,
851×1848, English iPhone portrait, selected by director 2026-09-21.
SHA-256: `1DAB158AE993CEE419FD7A140D4A01577AE1D51C0681EFF186AB0C71673D17B9`.

The rear orientation is `design/approved/expansion-rear-v3.png`, 851×1848,
English iPhone portrait, selected by director 2026-09-21. SHA-256:
`CC55FD083BEDCD9D2D5C3AF4CEE940D381B8291DE7DBA699C15BDFD4A97E7DE8`.
The opening must remove the original wall's entire height; the room remains
below the calendar. Preserve the original starter projection and its 11×11
geometry rather than copying the generated main-room widening. Its native HUD
and preparation controls remain governed by the existing shopkeeper reference.
Rear proposals v1/v2 are historical, not additional current references.

## Starter shop overview

- Status: current and approved
- State: first launch shop, before restoration
- Image: `design/approved/starter-shop-overview.png`
- Device: iPhone portrait
- Language: English
- Approved: 2026-08-27
- SHA-256: `F109DED9C96B1DDFD5B64039A86526AD7593ABC8F874C7385FD211FCE09F3006`
- Owner notes: keep the starter floor truly square; the world camera must support pinch zoom and vertical pan while the HUD remains fixed.
- Adaptable: native safe-area spacing, accessibility labels and runtime text rendering.

This approval governs the starter shop overview only. The first-slice screens
are governed independently by the approvals below.

## First-run story and shop name

- Status: current and approved
- State: first launch before entering the shop
- Image: `design/approved/first-slice-onboarding-name.png`
- Device: iPhone portrait
- Language: English
- Approved: 2026-08-27
- SHA-256: `3337E2D279E5D5CE74CB35F15A169E2EAF82D582AE2C079C201A2D334E9D857A`
- Owner notes: approve as part of the three-screen first-slice sequence; starting balance is $500 and the chosen name replaces `My Shop`.
- Adaptable: native text field, keyboard avoidance, safe-area spacing, Dynamic Type and VoiceOver labels.
- Runtime capture: `design/runtime/0.1.1/onboarding-runtime.png`, 1206x2622, CI 33925351640, SHA-256 `607E6F635A3F759C7C2E9DE85E63E909E49FA08F50561660272B407C51CDBC64`. Visual fidelity FAIL: see `docs/MILESTONE-001.md`; reference remains current.

## Build catalog

- Status: superseded historical reference
- State: Build open with starter Tables and Shelves
- Image: `design/approved/first-slice-build-catalog.png`
- Device: iPhone portrait
- Language: English
- Approved: 2026-08-27
- SHA-256: `76675D7E1F94445E13DEE920B36E4CCBBD1023FDCDDC38DCF3785840141DF2A6`
- Owner notes: v2 was approved, then superseded when the owner changed Basic Display Table to $50, footprint 1x1 and one stock slot. `Simple Shelf` remains an unmistakable vertical two-shelf unit. Decor and Walls remain `Coming soon`.
- Adaptable: native scrolling, safe-area spacing, Dynamic Type and VoiceOver labels.
- Runtime capture: pending implementation

## Build catalog v3

- Status: current and approved
- State: Build open with starter Tables and Shelves
- Image: `design/approved/first-slice-build-catalog-v3.png`
- Device: iPhone portrait
- Language: English
- Approved: 2026-08-27
- SHA-256: `49E25DEA9F007151C559C450BDD0994ECBCE61D7683C658DF753433F1F42964E`
- Owner notes: Basic Display Table costs $50, occupies exactly one square floor cell and holds one stock item. `Simple Shelf` remains $150, occupies 2x1 and holds two items. Decor and Walls remain `Coming soon`.
- Adaptable: native scrolling, safe-area spacing, Dynamic Type and VoiceOver labels.
- Runtime capture: pending implementation

## Basic Display Table placement

- Status: superseded historical reference
- State: valid preview before confirming purchase
- Image: `design/approved/first-slice-basic-table-placement.png`
- Device: iPhone portrait
- Language: English
- Approved: 2026-08-27
- SHA-256: `CA344DD9D3498A5538867D20004871AEE2830EF77C954A34A8C2928755E3C9F9`
- Owner notes: the approved version was superseded when the owner changed Basic Display Table to $50, footprint 1x1 and one stock slot. Balance remains $500 until `Place` confirms a valid position, then becomes $450.
- Adaptable: native gesture handling, accessible placement alternatives, safe-area spacing and VoiceOver labels.
- Runtime capture: pending implementation

## Basic Display Table placement v2

- Status: current and approved
- State: valid preview before confirming purchase
- Image: `design/approved/first-slice-basic-table-placement-v2.png`
- Device: iPhone portrait
- Language: English
- Approved: 2026-08-27
- SHA-256: `032CC2C513E60643FFCC53903C2AE7F283FC858D43D118F88D646CC03BD991DB`
- Owner notes: preview and selection occupy exactly one square floor cell; the table costs $50. Balance remains $500 until `Place` confirms a valid position, then becomes $450.
- Adaptable: native gesture handling, accessible placement alternatives, safe-area spacing and VoiceOver labels.
- Runtime capture: pending implementation

## Commerce and autonomous completion — 2026-09-05

The owner explicitly approved all three commerce images with "si" and asked
for the entire game to be completed without further questions, including varied
decorations, pleasant interaction, animations, and a meaningful schedule with
days and hours. Subsequent visual/product choices within this small game are
delegated to the director. Produce complete visual specifications before new
visual implementation and record the chosen references; do not create another
owner approval gate. This project-specific instruction supersedes earlier
pending-approval wording, not the preservation of the existing masters.

| Screen/state | Canonical image | SHA-256 |
| --- | --- | --- |
| Stock, empty table slot | `design/approved/commerce-01-stock-v1.png` | `1A8B322FB60558034866E76A72E502423DFA29355D2D1B02670149F643922ACF` |
| Open, first sale | `design/approved/commerce-02-open-v1.png` | `68C77294B3F31E5B396E1535049DD6E03283403DF82B35EE9730C52D459FC9C4` |
| Day complete, three sales | `design/approved/commerce-03-day-complete-v1.png` | `1EF68E66FEE8787BC8EDD541A3C20C2F865D83001BF0B1FAB92AF2D136E65617` |

All: current, owner-approved 2026-09-05, portrait 853x1844, English iPhone.
Runtime comparison pending the complete 0.2 candidate. Prompts and independent
scenario arithmetic remain in `design/proposals/commerce-v1/MANIFEST.md`.

## Complete game direction selected under delegated authority

- Status: historical v1, replaced by v2 below; selected by the director under the owner's
  explicit instruction to finish all design decisions without further questions.
  It is not a claim that the owner individually reviewed this additional image.
- Image: `design/approved/complete-game-director-v1.png`
- Canvas: 853x1844, portrait iPhone, English.
- Selection date: 2026-09-05.
- SHA-256: 32100A1AB80E3B6A850B4325C05B848FF4840E0AD55FC5AF2858A77F7E9F61CB
- State: restored/decorated shop, neighboring room, trading calendar.
- Governs: coherent restored materials, six decoration designs, customer scale,
  compact adjoining-room silhouette and the native day/time presentation family.
- Runtime product rules remain authoritative: Lucky Charms use tables only;
  the mockup's small charm-like shelf ornament must not create an exception.
- Runtime permits the same compact room on left, right or rear; the pictured
  right-side room is one example. Native safe areas and accessible text adapt.
- Runtime comparison: pending the complete asset integration and CI capture.

### Complete-game direction v2 — current
Selected by the director under the same delegated authority on2026-09-05.
`design/approved/complete-game-director-v2.png` (863x1823, portrait, English),
SHA-256 `B8BA06DDE38BDBCF65608F11E9B2660F52092A8348A895A6D697067B3E6B98D2`.
It replaces v1 as current and corrects the shelf product to a potion; v1 remains
historical. Same direction, native accessibility and expansion options apply.
App icon source selected under delegated authority: door, warm light and cyan
potion; archived with prompt and packaging provenance in COMPLETE-GAME-ART.md.

## Runtime comparison archive — 0.2 (1), 2026-09-05

The owner delegated the remaining visual decisions without further questions.
Native calendar, weekday, pause/speed controls, accessibility layouts and
progression panels were completed under that authority. The masters remain
archived specifications; these separate files are real screenshots of the app,
not generated store captures. File hashes, device canvases, source commit and
CI run are recorded beside each capture in the runtime manifests.

| Current screen/state | Actual comparable screenshot |
| --- | --- |
| Shop overview | [Overview](runtime/0.2/4087139/overview-runtime.png) |
| Onboarding | [Onboarding](runtime/0.2/4087139/onboarding-runtime.png) |
| Onboarding, compact | [Compact onboarding](runtime/0.2/4087139/onboarding-compact-runtime.png) |
| Build | [Build](runtime/0.2/4087139/build-runtime.png) |
| Placement | [Placement](runtime/0.2/4087139/placement-runtime.png) |
| Placement, compact | [Compact placement](runtime/0.2/4087139/placement-compact-runtime.png) |
| Open, first sale paused | [Open](runtime/0.2/4087139/open-runtime.png) |
| Day complete | [Summary](runtime/0.2/4087139/summary-runtime.png) |
| Decoration catalog | [Decor](runtime/0.2/4087139/decor-runtime.png) |
| Improvements | [Improvements](runtime/0.2/4087139/improvements-runtime.png) |
| Journal | [Journal](runtime/0.2/4087139/journal-runtime.png) |
| Restored, left wing | [Left wing](runtime/0.2/4087139/restored-runtime.png) |
| Restored, right wing | [Right wing](runtime/0.2/4087139/restored-right-runtime.png) |
| Restored, rear room | [Rear room](runtime/0.2/4087139/restored-rear-runtime.png) |
| Rubble repaired | [Rubble](runtime/0.2/4087139/repair-rubble-runtime.png) |
| Floorboards repaired | [Boards](runtime/0.2/4087139/repair-boards-runtime.png) |
| Papers tidied | [Papers](runtime/0.2/4087139/repair-papers-runtime.png) |

The old Stock captures in 4087139 remain historical evidence of the panel
correction. A final 75-point extra camera lift is separately recaptured so the
default selected table is visible above that panel. See the final Stock archive
record below. Native control sizes and scrolling adapt to iPhone safe areas
and accessibility text. See COMPLETE-GAME-VERIFICATION.md for exact checks and
minor retained presentation limits; no pixel-identical or physical-device
verification is claimed.

### Final Stock archive — current

Source `77cbc09488072736c1fcee95c4581252f78da8f2`, focused Release capture run
`33932562250` SUCCESS, director review PASS on 2026-09-05. The selected table is
visible above the panel; the purchase actions remain contained and legible.

- [Stock](runtime/0.2/77cbc09/stock-runtime.png)
- [Stock, compact](runtime/0.2/77cbc09/stock-compact-runtime.png)
- [Stock, large type](runtime/0.2/77cbc09/stock-large-text-runtime.png)

`runtime/0.2/current-manifest.json` identifies the 20 current screen captures;
23 images remain archived including the three superseded Stock captures.


## Living Shop 0.3 — current director-selected masters

Selected on 2026-09-05 by the project director under the owner's explicit authorization of the 0.3 expansion and autonomous design decisions. The owner did not individually review these three generated images; this archive does not claim otherwise. Earlier references and proposal history remain preserved. These are full-screen visual specifications, not runtime or store screenshots.

| Screen/state | Canonical image | Actual canvas | Language | SHA-256 |
| --- | --- | --- | --- | --- |
| Open, three concurrent browsers and response bubbles | [Living Open v2](approved/living-open-v2.png) | 852×1846 | English | `A7E9A8EFECA4C9D8471828D4BCDC8100603B23D09E62F7676FDA323B1C793EE0` |
| Pricing, Glow Potion pending at $30 | [Living Pricing v1](approved/living-pricing-v1.png) | 851×1849 | English | `37D47B6112A67FF8FEEA4737685DD528D69ADD9EF45FC0849B5ACB6D0E1951BC` |
| Care / Floor, four Oak tiles pending at $8 | [Living Care/Floors v1](approved/living-care-floors-v1.png) | 851×1849 | English | `D6330129292EE8CC00DBAAFEA72B91F115D079353ED7A65DB2DFC06339707144` |

- Device/orientation: English iPhone, portrait; requested reference canvas 1206×2622. Built-in ImageGen returned the actual canvases listed above.
- Source proposal history, exact prompts, inventory and fidelity notes: [Living Shop master manifest](proposals/living-shop/MANIFEST.md), [machine-readable manifest](proposals/living-shop/manifest.json). Open v1 remains historical in proposals and is not current.
- Governing base: the final native 0.2 Stock screenshot and the restored-right screenshot. Preserve existing room geometry, plates, customer/product sprites, native safe areas and accessibility behavior. Generated restaging does not authorize changing the world's physical layout.
- Product rules: the displayed 70% interest and example balances are illustrative; live pricing interest, costs, demand and balances come from Core. Exactly three product kinds remain. Each shelf slot holds one product.
- Floor prices: Terracotta $1, Oak $2 and Checkered $3 per eligible tile. Floor preview is pending until Apply Floor. Clean is the compact companion state with sweeping gestures, initial three-pass repair progress and free recurrent dust removal.
- Native adaptation: scrollable panel contents, Dynamic Type, VoiceOver labels, safe-area spacing and stepper layout may adapt to device. Retain the bounded teal/gold surfaces and clear actions; do not hide the world interaction area behind controls.
- Runtime sources/imagesets: [Living Shop art manifest](assets/living-shop/MANIFEST.md). New PNGs are materials/decals only; full-screen masters are never flattened runtime backgrounds.
- Comparable runtime captures and completed qualitative review are recorded below. Native accessibility adaptations are documented; no pixel equality is claimed.


### Living Shop runtime comparison — 0.3 (1), 2026-09-05

Director review complete after real simulator capture and eight passing native UI
tests. These are app screenshots, separate from the generated masters. Final app
source is `6474cab768d53a6deac669a123a2da689933c21f`; unchanged states retain their
earlier tested source, explicitly identified in the manifest.

| Master / state | Current comparable runtime |
| --- | --- |
| Living Open v2 | [Three concurrent visitors](runtime/0.3/0b99f37/living-runtime.png) |
| Living Pricing v1 | [Pricing](runtime/0.3/0b99f37/pricing-runtime.png) |
| Living Care/Floors v1 | [Floor preview](runtime/0.3/6474cab/floors-runtime.png) |
| Floor, compact | [Compact floor controls](runtime/0.3/6474cab/floors-compact-runtime.png) |
| Floor, large text | [Accessible material carousel](runtime/0.3/6474cab/floors-large-text-runtime.png) |
| Clean companion | [Manual cleaning](runtime/0.3/0b99f37/care-runtime.png) |
| Applied floor | [Applied materials](runtime/0.3/0b99f37/floor-laid-runtime.png) |
| Saved price, large text | [Saved $31 price](runtime/0.3/0b99f37/ui-price-saved-large.png) |
| Gesture result | [Moved furniture](runtime/0.3/0b99f37/ui-drag-after.png) |
| Gesture result | [Three-stroke cleanup](runtime/0.3/0b99f37/ui-clean-after-strokes.png) |

The material geometry, ornamented bounded panels, customer/product art and world
interaction area match the established direction. Safe areas, scrolling and the
large-text carousel adapt the full-screen illustration for actual devices. Live
computed interest is 65% for the $30 potion example, superseding the illustrative
70% in the master. Prices, stock and physical world placement come from Core.
`runtime/0.3/current-manifest.json` contains 20 current images, 23 preserved images,
SHA-256, canvases and provenance. See `docs/LIVING-SHOP-VERIFICATION.md` for executed
coverage and physical-device limitations.


## Shopkeeper 0.4 — current director-selected masters

Selected on 2026-09-21 by the project director under the owner's explicit authorization of autonomous design and the 0.4 improvement scope. The owner did not individually review these generated images; no such review is claimed. These are visual specifications, not real app or store screenshots.

| Screen/state | Canonical image | Device/canvas | Orientation/language | SHA-256 |
| --- | --- | --- | --- | --- |
| Preparation; next restoration objective, 1/3 | [Shopkeeper preparation v1](approved/shopkeeper-preparation-v1.png) | iPhone, 851×1849 actual (1206×2622 requested) | Portrait, English | `9DBA62373730D37263D2E3527DDDEEA50003D030D1DEFF083738DB747E537EBF` |
| Day complete; product sales/margins and observed-interest advice | [Shopkeeper summary v1](approved/shopkeeper-summary-v1.png) | iPhone, 851×1848 actual (1206×2622 requested) | Portrait, English | `C01884FE990F4FFC3CFDE3AA926834C074E97B2997CBC42AA44256D7D9345F8A` |

- These govern the changed 0.4 preparation hint and day-complete panel. They supersede the earlier generic preparation hint and commerce day-summary UI for those states only; all older masters and runtime images remain preserved as history. Existing world/art masters continue to govern the room.
- Source runtime: preparation [0.3 drag/overview](runtime/0.3/0b99f37/drag-runtime.png); summary [0.2 native summary](runtime/0.2/4087139/summary-runtime.png), whose panel family remains in 0.3.
- Exact prompts, proposal history, arithmetic, asset inventory, fidelity caveats and native adaptation targets: [Shopkeeper manifest](proposals/shopkeeper-v1/MANIFEST.md), [machine-readable record](proposals/shopkeeper-v1/manifest.json).
- Existing product sprites and OrnatePanel are reused; no new runtime bitmap. Full-screen images are never flattened runtime screens.
- Accessibility may adapt wrapping, scroll area height, footer layout and secondary actions. Preserve the bounded panel, readable text, unobstructed world controls and fixed next-day action. Respect native safe areas over incidental ImageGen margins.
- Day, amounts, progress, counts, product margins and Tomorrow advice come from live Core data. Observed requested-product interest must not be labeled lost sales or treated as proof of the reason a visitor left.
- The authorized CalendarBar pause action belongs to the open state; preparing/closed examples correctly omit it.
- Comparable 0.4 runtime captures and qualitative review are complete below; this does not claim pixel equality or physical-device verification.

- Director-confirmed native preparation adaptation: retain Improve as a fourth secondary access for expansion/planning and add a brief two-line explanation of three sweeping passes. Standard-size actions may share a row; their text ceiling follows the existing navigation policy (xxxLarge), with full accessibility labels and at least 44-point touch areas. This preserves the selected direction and does not claim an additional owner image review.
- Runtime-driven summary adaptation (2026-09-21): the closed-day panel may use
  70% of the viewport, with 6-point section spacing, so the third product and
  Tomorrow advice are visible sooner. The trading world is inactive at this
  point. Preserve type sizes, the fixed next-day button and scrollable compact/
  accessibility content. Remove redundant explanatory copy after the factual
  non-buying visitor count. This corrects the initial capture's two-row view.


### Shopkeeper runtime comparison — 0.4 (1), 2026-09-21

Full UI/capture source `a7017884307c3beeafc00167716fde5dde8db6f6`, CI 35635145547.
These are real app screenshots, separate from the generated masters.

| Master / state | Comparable runtime |
| --- | --- |
| Preparation v1 | [Next restoration step](runtime/0.4/a701788/preparation-runtime.png) |
| Summary v1 | [Three products and Tomorrow](runtime/0.4/a701788/living-summary-runtime.png) |
| Summary, compact | [Compact report](runtime/0.4/a701788/living-summary-compact-runtime.png) |
| Summary, accessibility after scrolling | [Tomorrow and fixed action](runtime/0.4/a701788/ui-closing-report-with-large-text.png) |
| Pricing | [Fixed price controls](runtime/0.4/a701788/pricing-runtime.png) |
| Care | [Repair counters first](runtime/0.4/a701788/care-large-text-runtime.png) |
| Paused stock, actual interaction | [Replaced product rendered](runtime/0.4/a701788/ui-product-visible-while-the-shop-stays-paused.png) |
| Restored free play | [Records and product mix](runtime/0.4/a701788/freeplay-runtime.png) |

Review confirms the room/material/typography direction, teal preparation action,
clear repair progress and per-product report. Native safe areas, extra Improve
access, factual game values and scrollable compact/accessibility content are
intentional adaptations. The closed-day report's larger panel exposes all three
products and advice on the normal device; there is no need to manipulate the
world behind that report. No new bitmap assets or flattened mockups are used.
The manifest contains 32 current images and 38 preserved images, including the
initial stale paused frame and smaller report as historical comparisons.
Full test/IPA evidence and limits: `../docs/SHOPKEEPER-VERIFICATION.md`.

Final compact Stock correction: source `5e4a4998ecbb8e5b5e4f3f40b91a6e71c0feaf11`,
CI 35637669014. A 120-point Stock camera lift below 700-point viewport height
keeps the selected table and potion below the calendar. Normal height retains
180 points. [Compact](runtime/0.4/5e4a499/paused-stock-compact-runtime.png) and
[accessibility](runtime/0.4/5e4a499/paused-stock-large-text-runtime.png) pass review.
The new normal-size file is a rejected white launch-frame acquisition; it is
archived but not current evidence. The unchanged normal layout keeps its valid
[a701788 capture](runtime/0.4/a701788/paused-stock-runtime.png). Source, rejection
and current selection are explicit in the manifest; no three-valid-final-frame
claim is made. This closes the observed selected-table occlusion on iPhone SE.
