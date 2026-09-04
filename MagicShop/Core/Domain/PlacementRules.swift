import Foundation

public struct ShopLayout: Codable, Equatable, Sendable {
    public var width: Int
    public var depth: Int

    public init(width: Int = 11, depth: Int = 11) {
        precondition(width > 0 && depth > 0)
        self.width = width
        self.depth = depth
    }

    public static let starter = ShopLayout(width: 11, depth: 11)
}

public enum PlacementError: Error, Equatable, Sendable {
    case insufficientFunds(required: Int, available: Int)
    case outsideShopBounds
    case entranceMustRemainClear
    case blockedByStaticObject(StaticBlockerID)
    case overlapsExistingFixture
    case shelfMustBeAdjacentToWall
    case duplicateFixtureID(UUID)
    case shopIsNotPreparing(ShopPhase)
}

public enum PlacementRules {
    public static func occupiedCells(
        origin: GridPoint,
        footprint: GridFootprint
    ) -> Set<GridPoint> {
        var result = Set<GridPoint>()
        for x in origin.x..<(origin.x + footprint.width) {
            for y in origin.y..<(origin.y + footprint.depth) {
                result.insert(GridPoint(x: x, y: y))
            }
        }
        return result
    }

    public static func occupiedCells(for fixture: PlacedFixture) -> Set<GridPoint> {
        let definition = FixtureCatalog.definition(for: fixture.kind)
        return occupiedCells(
            origin: fixture.origin,
            footprint: definition.footprint.rotated(fixture.rotation)
        )
    }

    public static func validate(
        _ draft: PlacementDraft,
        in state: GameState,
        layout: ShopLayout? = nil
    ) throws {
        guard state.phase == .preparing else {
            throw PlacementError.shopIsNotPreparing(state.phase)
        }
        guard !state.fixtures.contains(where: { $0.id == draft.fixtureID }) else {
            throw PlacementError.duplicateFixtureID(draft.fixtureID)
        }
        let definition = FixtureCatalog.definition(for: draft.kind)
        guard state.balance >= definition.price else {
            throw PlacementError.insufficientFunds(required: definition.price, available: state.balance)
        }
        try validateLocation(draft, in: state, layout: layout)
    }

    /// Geometry is shared by purchase and relocation. Moving ignores only the
    /// existing furniture's own footprint and never checks a purchase price.
    static func validateLocation(
        _ draft: PlacementDraft,
        in state: GameState,
        layout: ShopLayout? = nil,
        ignoringFixtureID: UUID? = nil
    ) throws {
        let definition = FixtureCatalog.definition(for: draft.kind)
        let footprint = definition.footprint.rotated(draft.rotation)
        let hitMap = state.world.hitMap
        let expectedLayout = layout ?? hitMap.layout
        guard draft.origin.x >= 0, draft.origin.y >= 0,
              draft.origin.x <= expectedLayout.width - footprint.width,
              draft.origin.y <= expectedLayout.depth - footprint.depth else {
            throw PlacementError.outsideShopBounds
        }
        let proposedCells = occupiedCells(origin: draft.origin, footprint: footprint)
        for point in proposedCells {
            guard let cell = hitMap.cell(at: point) else {
                throw PlacementError.outsideShopBounds
            }
            if cell.zone == .outside { throw PlacementError.outsideShopBounds }
            if cell.zone == .entrance { throw PlacementError.entranceMustRemainClear }
            if let blocker = cell.staticBlocker {
                throw PlacementError.blockedByStaticObject(blocker)
            }
        }
        let others = state.fixtures.filter { $0.id != ignoringFixtureID }
        let occupied = hitMap.dynamicOccupancy(fixtures: others)
        guard proposedCells.allSatisfy({ occupied[$0] == nil }) else {
            throw PlacementError.overlapsExistingFixture
        }
        if definition.placementConstraint == .adjacentToWall {
            guard !hitMap.commonWallAdjacency(for: proposedCells).isEmpty else {
                throw PlacementError.shelfMustBeAdjacentToWall
            }
        }
    }
}
