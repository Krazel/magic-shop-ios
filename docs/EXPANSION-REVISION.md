# Expansion presentation revision — 2026-09-21

The owner rejected the annex appearance in the delivered 0.4 screenshot and
confirmed that “impresión” meant the shop expansion. The annex looks pasted onto
the main room. Existing delegated authority covers this reversible correction;
no additional owner design approval is required. A director-selected full-screen
reference still precedes implementation and must be archived with provenance.

## Scope and acceptance

- Give the existing left, right and rear 5×5 annex a coherent architectural
  connection, perspective, materials and lighting.
- Preserve the main shop identity and all existing assets as historical sources.
- Preserve save schema 5, purchased direction, furniture, stock, floor choices,
  dirt, cash, rules and passable cells. This is a presentation correction, not a
  new expansion system.
- Verify all three directions with actual normal and compact simulator captures,
  including furniture and chosen floor in the annex and the connecting opening.
- Run native regression tests, inspect the real images, then produce and verify
  an unsigned iPhone IPA. Do not call a generated proposal an app screenshot.
- Target correction version 0.4.1, build 1, grouped as one delivery. Preserve 0.4.

## Ownership

Root owns integration, App fixtures/UI tests, CI, versioning and persistent state.
audit_runtime investigates and implements World rendering once the reference is
selected; commerce_core audits domain/save invariants and owns bounded domain
tests if needed; commerce_visuals owns reference art/assets and independent visual
review. No overlapping write scopes. No store, service, account or dependency work.

Direction selected: a contiguous exhibition alcove, with full-height cream/teal
walls, jambs only at the opening endpoints and a thin pale stone threshold at
floor level. The five-cell connection stays completely traversable. Separate
horizontal floor and vertically extruded walls replace the old all-in-one
warped room. Three complete references were reviewed and selected before final
implementation: left v2, right v2 and rear v3. Four original material sources
are archived with exact runtime copies and prompts. See design/APPROVALS.md and
docs/EXPANSION-ART.md for scope, provenance and native adaptations.

QA fixtures `annex-left`, `annex-right` and `annex-rear` use the actual restored
engine, move two existing displays into the annex, stock a potion and paint four
oak tiles. Native UI coverage taps the occupied display and returns/restocks its
item in each orientation. Domain audit extends existing three-direction
regression coverage for dirt and the whole opening. Final evidence pending.

## Integrated native-validation snapshot

- Source: `1cac2194d640986ae0c7ac113c1207f42cd063c0`, main/origin.
- Version: 0.4.1 (1), one correction delivery after 0.4.
- Windows static verification PASS; three selected masters and four new material
  source/runtime pairs preserved and checked. Independent read-only review found
  and resolved a camera jump when starting an annex Stock drag. The native UI
  test additionally holds the stocked display and verifies its overview position
  stays fixed after returning to preparation.
- CI run `35657369361`: Release simulator build PASS; all 131 XCTest cases PASS
  (118 domain/model and 13 UI, no failures or skips). The complete run succeeded,
  including all 15 requested normal, compact and large-text captures.
- Native visual review REJECTED the first snapshot: thin flat caps, bright flat
  walls and paper-like jambs do not match the original painted room; the rear
  painting also overlaps a jamb. See `docs/EXPANSION-VISUAL-QA.md`.
- The first unsigned 0.4.1 IPA built successfully in run `35659391617` and passed
  the package verifier, but is an intermediate rejected visual build, not the
  final deliverable. Last accepted delivered IPA remains 0.4.
- The finish correction reuses painted source crops and the existing corner
  post while preserving the tested map, camera and interactions. No new raster
  generation, dependency or save migration is needed.

## Verified correction delivered — 2026-09-22

Final app source: `8d58a2d0e969ba6b69c20c4e454dd56f367e751f`. The focused Release
build/capture run `35661013271` succeeded; root inspected all 15 PNGs and the
independent art review passed the nine occupied annex states. The narrow lateral
outer margin is a recorded nonblocking framing limitation; no floor or post is
clipped. No further app changes followed those captures.

Device run `35661029804` succeeded and its exact-source unsigned 0.4.1 (1) IPA
passed checksum, manifest, version, arm64 and minimum-iOS verification. See
`EXPANSION-VERIFICATION.md` and `design/runtime/0.4.1/` for the complete record.
The 131-test coverage remains attributed to the integrated functional source;
only painted rendering/mount placement changed afterward. Physical re-signing
and installation remain separate; no TestFlight or App Store operation occurred.
