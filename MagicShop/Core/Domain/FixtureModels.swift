import Foundation

public enum FixtureCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case tables
    case shelves
    case decor
    case walls

    public var isAvailable: Bool { self != .walls }

    public var isAvailableInFirstSlice: Bool {
        self == .tables || self == .shelves
    }
}

public enum FixtureKind: String, CaseIterable, Codable, Hashable, Sendable {
    case basicDisplayTable
    case simpleShelf
    case pottedFern
    case starRug
    case crystalDisplay
    case wallClock
    case moonPainting
    case brassLantern

    public var isDecoration: Bool {
        self != .basicDisplayTable && self != .simpleShelf
    }
}

public enum FixtureRotation: Int, CaseIterable, Codable, Hashable, Sendable {
    case north = 0
    case east = 90
    case south = 180
    case west = 270

    public var swapsAxes: Bool {
        self == .east || self == .west
    }
}

public struct GridPoint: Codable, Equatable, Hashable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct GridFootprint: Codable, Equatable, Sendable {
    public var width: Int
    public var depth: Int

    public init(width: Int, depth: Int) {
        precondition(width > 0 && depth > 0)
        self.width = width
        self.depth = depth
    }

    public func rotated(_ rotation: FixtureRotation) -> GridFootprint {
        rotation.swapsAxes
            ? GridFootprint(width: depth, depth: width)
            : self
    }
}

public enum PlacementConstraint: String, Codable, Hashable, Sendable {
    case anywhereOnFloor
    case adjacentToWall
}

public struct FixtureDefinition: Equatable, Sendable {
    public let kind: FixtureKind
    public let displayName: String
    public let category: FixtureCategory
    public let price: Int
    public let stockCapacity: Int
    public let blocksWalking: Bool
    public let footprint: GridFootprint
    public let placementConstraint: PlacementConstraint

    public init(
        kind: FixtureKind,
        displayName: String,
        category: FixtureCategory,
        price: Int,
        stockCapacity: Int,
        footprint: GridFootprint,
        placementConstraint: PlacementConstraint,
        blocksWalking: Bool = true
    ) {
        self.kind = kind
        self.displayName = displayName
        self.category = category
        self.price = price
        self.stockCapacity = stockCapacity
        self.footprint = footprint
        self.placementConstraint = placementConstraint
        self.blocksWalking = blocksWalking
    }
}

public struct PlacedFixture: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let kind: FixtureKind
    public var origin: GridPoint
    public var rotation: FixtureRotation

    public init(
        id: UUID = UUID(),
        kind: FixtureKind,
        origin: GridPoint,
        rotation: FixtureRotation = .north
    ) {
        self.id = id
        self.kind = kind
        self.origin = origin
        self.rotation = rotation
    }
}

public struct PlacementDraft: Equatable, Sendable {
    public let fixtureID: UUID
    public var kind: FixtureKind
    public var origin: GridPoint
    public var rotation: FixtureRotation

    public init(
        fixtureID: UUID = UUID(),
        kind: FixtureKind,
        origin: GridPoint,
        rotation: FixtureRotation = .north
    ) {
        self.fixtureID = fixtureID
        self.kind = kind
        self.origin = origin
        self.rotation = rotation
    }
}
