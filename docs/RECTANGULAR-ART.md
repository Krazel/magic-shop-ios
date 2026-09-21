# Rectangular shop art — 2026-09-22

Status: **the owner explicitly approved the exact three-image set on 2026-09-22**, responding “Sí, aplica las tres” after viewing right v1, left v1 and rear v2.

The owner rejected the separate-room concept of 0.4.1. The new request is one continuous rectangular shop, expanded by moving an entire exterior wall to the new outer boundary. No wing, alcove, internal opening, threshold, post, seam or second room remains. Target product release is 0.5 (1). The approved references now govern the rectangular-room visual implementation within the existing product scope.

The project director prepared the three complete images under standing delegated authority. Automatic approval review initially rejected canonical promotion because it required exact-image approval; that rejection was respected. The owner then reviewed the displayed set and explicitly approved all three. Only after that new approval were matching canonical copies created in `design/approved/`. The review gate is resolved; all proposals, earlier references and runtime evidence remain preserved. Root owns the corresponding entry in `design/APPROVALS.md`.

## Three approved references and preserved proposals

Canonical references: [right v1](../design/approved/rectangular-right-v1.png), [left v1](../design/approved/rectangular-left-v1.png), and [rear v2](../design/approved/rectangular-rear-v2.png). Their SHA-256 hashes match the proposal rows below exactly.

Every image is a separate English portrait iPhone composition, 851×1848, opaque 24-bit RGB. Built-in ImageGen produced all images; no raster editing or resampling was performed in code. Every source has an adjacent exact `.prompt.txt`.

| Proposal | State | SHA-256 |
| --- | --- | --- |
| [rectangular-right-v1.png](../design/proposals/rectangular-v1/rectangular-right-v1.png) | One 16×11 room; five new columns right, original furnishings and entrance anchored in the left eleven columns | `C2085DF038EE4DB7026F4C74D8526F975DEA626BA68301B7C3E23FA1A14649F9` |
| [rectangular-left-v1.png](../design/proposals/rectangular-v1/rectangular-left-v1.png) | One 16×11 room; five new columns left, starter coordinates translated right, original entrance right of center | `23B6C41E98DFACD2495344498982C4E9C0FD1244E94B9F38DE9F525DAC9B5278` |
| [rectangular-rear-v2.png](../design/proposals/rectangular-v1/rectangular-rear-v2.png) | One 11×16 room; entire rear wall moved back, original centered entrance/front width retained | `228D9F273A7058C0E75836B52FFC1D5430C88E92BCC416A36697178AF7408B84` |

[Rear v1](../design/proposals/rectangular-v1/rectangular-rear-v1.png) remains a historical proposal. It incorrectly inherited an offset door and extra facade window bays from the side expansion; rear v2 corrects that arrangement.

## Source and generation provenance

Inputs were inspected with view_image before generation:

- [RepairedShopBackground.png](../design/assets/complete-game/RepairedShopBackground.png), 853×1844, original painted material/room reference.
- [restored-right-runtime.png](../design/runtime/0.4.1/8d58a2d/restored-right-runtime.png), real 0.4.1 capture, initial UI/furnishing edit target.
- Right v1 then supplied the continuous rectangular concept and current UI to left/rear v1.
- Rear v2 edits rear v1 with the original painted room as the facade reference.

Exact prompts:

- [Right v1 prompt](../design/proposals/rectangular-v1/rectangular-right-v1.prompt.txt)
- [Left v1 prompt](../design/proposals/rectangular-v1/rectangular-left-v1.prompt.txt)
- [Rear v1 prompt](../design/proposals/rectangular-v1/rectangular-rear-v1.prompt.txt)
- [Rear v2 prompt](../design/proposals/rectangular-v1/rectangular-rear-v2.prompt.txt)

Built-in original generation files remain under `$CODEX_HOME/generated_images/01a06e65-3852-7053-a87d-2c481f877daf/`:

| Proposal | Original generation filename |
| --- | --- |
| Right v1 | exec-c78a3a19-86f3-4043-a75a-e986823860b4.png |
| Left v1 | exec-7ce51571-738e-45f9-a58e-5ea1f9c369f3.png |
| Rear v1 | exec-cbb66fe6-dcde-4593-a69d-679a05c95125.png |
| Rear v2 | exec-c5c2ba60-ba08-4d57-b063-7181d10db983.png |

The project copies above preserve the originals at native dimensions and do not depend on temporary output paths.

## Proposed construction contract for World

This construction contract implements the approved direction. Native cell dimensions, saved state and the final Core migration contract remain authoritative; this document does not assert that implementation or migration has already shipped.

- Right: move the complete right exterior wall to x16, keep width16/depth11, extend the rear wall and front facade through the new five-column strip. The original entrance remains at its starter position, left of the new facade center.
- Left: move the complete left exterior wall to the new left bound, keep width16/depth11 and translate starter coordinates by five columns. The original entrance consequently sits right of the new center.
- Rear: move the full rear wall to y16, keep width11/depth16, extend both side walls and maintain the original centered entrance/facade width.
- Remove all old internal wall footprints and their caps, end posts, thresholds and material breaks. Each plan has exactly four exterior corners and one continuous usable floor plane.
- Preserve original physical sprite sizes, orientations and tile frequency. Fit the world through uniform camera scale/translation rather than stretching furniture, door, windows, lamp or wall decoration.
- Existing floor furniture retains its saved location after the agreed coordinate translation. The proposed rear wall attachment rule relocates a north-adjacent shelf from y10 to y15, preserving identity/stock/rotation unless Core must resolve a collision; this proposal is not proof that migration has shipped.
- Retain native controls and factual game state. A uniformly fitted world may continue behind the existing preparation panel.

## Preferred art inventory — existing paint, no new runtime bitmaps

No additional raster assets are needed for the approved direction at this stage. World can assemble the continuous rectangle from existing painted source strips and sprites:

1. Extend the floor using a small original tile sample at the original physical frequency, with broad scene illumination separate from the repeated detail. Do not stretch the full eleven-column floor to sixteen columns or copy a large fixed lighting patch into the new strip.
2. Keep the moved exterior wall's painted face, bevel/cap and curved corner treatment. Extend the parallel walls from lamp-free source segments while preserving the unique lamp, clock and painting.
3. Preserve the original entrance sprite and existing window dimensions, adding matching window bays where lateral frontage grows. The rear variant keeps the original two-window/center-door front arrangement.
4. Use existing facade columns only as exterior architecture. No remaining post may describe an internal boundary.

A read-only pixel inspection identified a useful original floor candidate around x375…477, y786…908, with intermediate joints near x426 and y847: approximately a 2×2 tile block. Perspective-adjusted corners are approximately far (376,786)/(477,786), near (374,908)/(479,908). Retain a small grout bleed and verify the repeat natively. The painted source is not mathematically periodic; these coordinates are a sampling candidate, not a guarantee of seamless repetition. Original art has roughly thirteen physical tiles across eleven logical cells; physical grout and logical placement cells need not coincide.

## Fidelity limits and native implementation adaptations

The three proposals correctly show one continuous rectangle without the rejected small room. They preserve the established painterly family, native English content and original-size object proportions.

ImageGen nevertheless resynthesizes individual floor lines, window details, furniture spacing and projection. Tile counts in the proposal must not redefine native cell dimensions or saved coordinates. Native factual furnishing positions and the original calibrated projection take precedence over accidental image resynthesis.

Rear v2 keeps the new continuous-room composition and centered facade, but its lower panel is approximately eighty source pixels lower than in the existing native UI master. This is a known proposal difference, not a request to move or shrink the native panel. The original shopkeeper layout, safe areas, accessibility behavior and real text remain the UI specification. The rear wall also has little clearance below Calendar in the generated image; native camera fitting must preserve a visible gap at normal, compact and accessibility sizes.

No runtime fidelity claim is made here. After implementation, capture the actual three directions at normal, compact and accessibility sizes; verify the single-room silhouette, absence of old partitions, tile/object scale, preserved entrance, continuous lighting and usable camera framing against the chosen references.
