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
        }
    }

    public static func fixtures(in category: FixtureCategory) -> [FixtureDefinition] {
        firstSlice.filter { $0.category == category }
    }
}
