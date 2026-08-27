# Technical foundation — first slice

## Visual boundary

The starter shop, onboarding/name, Build catalog v3 and Basic Display Table
placement v2 references are current and approved. The SwiftUI layer follows
their native text, keyboard, Dynamic Type, VoiceOver and fixed-HUD requirements.

The visible world uses the clean `starter-shop-background` composition directly,
as explicitly corrected by the owner after reviewing the modular runtime build.
SpriteKit does not redraw the floor, walls, facade, lamp, debris or a placement
grid. The 19-piece modular kit remains preserved for later selective replacement
work, but it is not assembled in the current scene.

## Architecture

- SwiftUI owns app lifecycle and fixed overlays.
- SpriteKit owns the approved background plate plus furniture and placement overlays.
- `WorldGridGeometry` and `CameraViewportTransform` provide platform-neutral,
  testable world/screen conversion. Runtime taps use that same transform.
- `WorldCameraState` keeps zoom within `0.65...1.25` and vertical pan within
  `-220...220` points. Horizontal world pan is intentionally absent.
- `ShopFloorState` stores one `FloorStyleID` per invisible logical cell for the
  future flooring phase; those tiles are not currently rendered.
- `WorldHitMap` persists cell zones, static blockers and wall adjacency. Dynamic
  fixture occupancy is derived from the persisted fixture list.
- Swift/Foundation owns all rules and persistence so it can be tested without
  iOS frameworks.
- `FileGameStateStore` writes one atomic JSON file in Application Support.

## First-slice rules

- A new state has no name, incomplete onboarding, `$500` and no fixtures.
- Names are trimmed, internal whitespace is collapsed and length is 2–24
  characters. Control characters are rejected.
- Tables and shelves are active categories. Decor and walls are future data
  categories only.
- Basic Display Table costs `$50`, occupies exactly 1×1 and holds one item.
- Simple Shelf costs `$150`, occupies 2×1, holds two items and must touch a wall.
- Placement validation is side-effect free.
- Money is deducted only by a successful confirmation.
- Cancellation does not mutate the save.
- A fixture must stay on interior, non-entrance cells without static blockers
  or dynamic fixture occupancy.
- Starter blockers correspond to plaster rubble, wood slats, paper debris and
  the two front architectural posts rendered by the modular scene.
- A Simple Shelf must have one wall side in common across every occupied cell;
  coordinate edges alone do not satisfy the rule.
- Name, onboarding state, balance, fixtures, floor styles and hitmap are Codable
  and persisted. Schema 1 saves migrate to schema 2 with the starter world.
- Stock and Open behavior are out of scope; furniture capacity is metadata.

## Verification boundary

The current host is Windows and does not provide Swift or Xcode. Local static
verification can validate topology, source invariants, asset hashes and declared
coverage, but compilation, XCTest and 1:1 visual capture must be obtained on
macOS. Do not report the project as compiled or visually final until both macOS
scripts and the runtime comparison finish successfully.
