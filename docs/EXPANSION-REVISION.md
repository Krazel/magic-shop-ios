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
warped room. A new full-screen reference and four material sources are being
prepared; final visual implementation follows reference review.

QA fixtures `annex-left`, `annex-right` and `annex-rear` use the actual restored
engine, move two existing displays into the annex, stock a potion and paint four
oak tiles. Native UI coverage taps the occupied display and returns/restocks its
item in each orientation. Domain audit extends existing three-direction
regression coverage for dirt and the whole opening. Final evidence pending.
