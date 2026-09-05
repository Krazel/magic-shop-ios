# Magic Shop — Visual Approvals

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
