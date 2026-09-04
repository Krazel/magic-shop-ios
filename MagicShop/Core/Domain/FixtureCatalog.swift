import Foundation

public enum FixtureCatalog {
    public static let basicDisplayTable = FixtureDefinition(
        kind: .basicDisplayTable,
        displayName: "Basic Display Table",
        category: .tables,
        price: 50,
        stockCapacity: 1,
        footprint: GridFootprint(width: 1, depth: 1),
        placementConstraint: .anywhereOnFloor
    )

    public static let simpleShelf = FixtureDefinition(
        kind: .simpleShelf,
        displayName: "Simple Shelf",
        category: .shelves,
        price: 150,
        stockCapacity: 2,
        footprint: GridFootprint(width: 2, depth: 1),
        placementConstraint: .adjacentToWall
    )

    public static let decor: [FixtureDefinition] = [
        FixtureDefinition(kind: .pottedFern, displayName: "Potted Fern", category: .decor,
                          price: 35, stockCapacity: 0, footprint: GridFootprint(width: 1, depth: 1),
                          placementConstraint: .anywhereOnFloor),
        FixtureDefinition(kind: .starRug, displayName: "Star Rug", category: .decor,
                          price: 45, stockCapacity: 0, footprint: GridFootprint(width: 1, depth: 1),
                          placementConstraint: .anywhereOnFloor, blocksWalking: false),
        FixtureDefinition(kind: .crystalDisplay, displayName: "Crystal Display", category: .decor,
                          price: 60, stockCapacity: 0, footprint: GridFootprint(width: 1, depth: 1),
                          placementConstraint: .anywhereOnFloor),
        FixtureDefinition(kind: .wallClock, displayName: "Wall Clock", category: .decor,
                          price: 100, stockCapacity: 0, footprint: GridFootprint(width: 1, depth: 1),
                          placementConstraint: .adjacentToWall, blocksWalking: false),
        FixtureDefinition(kind: .moonPainting, displayName: "Moon Painting", category: .decor,
                          price: 75, stockCapacity: 0, footprint: GridFootprint(width: 1, depth: 1),
                          placementConstraint: .adjacentToWall, blocksWalking: false),
        FixtureDefinition(kind: .brassLantern, displayName: "Brass Lantern", category: .decor,
                          price: 55, stockCapacity: 0, footprint: GridFootprint(width: 1, depth: 1),
                          placementConstraint: .anywhereOnFloor)
    ]

    public static var all: [FixtureDefinition] { firstSlice + decor }

    public static let firstSlice: [FixtureDefinition] = [
        basicDisplayTable,
        simpleShelf
    ]

    public static func definition(for kind: FixtureKind) -> FixtureDefinition {
        switch kind {
        case .basicDisplayTable:
            return basicDisplayTable
        case .simpleShelf:
            return simpleShelf
        case .pottedFern: return decor[0]
        case .starRug: return decor[1]
        case .crystalDisplay: return decor[2]
        case .wallClock: return decor[3]
        case .moonPainting: return decor[4]
        case .brassLantern: return decor[5]
        }
    }

    public static func fixtures(in category: FixtureCategory) -> [FixtureDefinition] {
        all.filter { $0.category == category }
    }
}
