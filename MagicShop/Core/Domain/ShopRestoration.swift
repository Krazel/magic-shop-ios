import Foundation

public enum RestorationGroupID: String, CaseIterable, Codable, Hashable, Sendable {
    case rubble
    case brokenBoards
    case discardedPapers
}

public struct RepairDefinition: Identifiable, Equatable, Sendable {
    public let id: RestorationGroupID
    public let displayName: String
    public let price: Int
    public let blocker: StaticBlockerID
}

public enum RepairCatalog {
    public static let all: [RepairDefinition] = [
        RepairDefinition(id: .rubble, displayName: "Clear Rubble", price: 40, blocker: .rubble),
        RepairDefinition(id: .brokenBoards, displayName: "Repair Floorboards", price: 60, blocker: .brokenBoards),
        RepairDefinition(id: .discardedPapers, displayName: "Tidy Papers", price: 25, blocker: .discardedPapers)
    ]

    public static func definition(for id: RestorationGroupID) -> RepairDefinition {
        switch id {
        case .rubble: return all[0]
        case .brokenBoards: return all[1]
        case .discardedPapers: return all[2]
        }
    }
}

public enum ExpansionDirection: String, CaseIterable, Codable, Hashable, Sendable {
    case left
    case right
    case rear

    public var displayName: String {
        switch self {
        case .left: return "Left Wing"
        case .right: return "Right Wing"
        case .rear: return "Rear Room"
        }
    }
}

/// One compact 5x5 room. Coordinates stay nonnegative; the existing shop moves
/// right by five cells only for the left wing. IDs and stock references persist.
public struct ExpansionState: Codable, Equatable, Sendable {
    public static let price = 250
    public static let roomSize = 5
    public let direction: ExpansionDirection

    public init(direction: ExpansionDirection) { self.direction = direction }

    public var starterOrigin: GridPoint {
        GridPoint(x: direction == .left ? Self.roomSize : 0, y: 0)
    }
    public var roomOrigin: GridPoint {
        switch direction {
        case .left: return GridPoint(x: 0, y: 3)
        case .right: return GridPoint(x: 11, y: 3)
        case .rear: return GridPoint(x: 3, y: 11)
        }
    }
    public var layout: ShopLayout {
        direction == .rear ? ShopLayout(width: 11, depth: 16) : ShopLayout(width: 16, depth: 11)
    }

    /// Doorway cells in the original 11x11 coordinates, before any translation.
    public var starterConnectionCells: Set<GridPoint> {
        Set((3...7).map { value in
            switch direction {
            case .left: return GridPoint(x: 0, y: value)
            case .right: return GridPoint(x: 10, y: value)
            case .rear: return GridPoint(x: value, y: 10)
            }
        })
    }
}

public struct RestorationCompletion: Codable, Equatable, Sendable {
    public let completedOnDay: Int
}

public struct ShopRestorationState: Codable, Equatable, Sendable {
    public var repairedGroups: Set<RestorationGroupID>
    public var expansion: ExpansionState?
    public var completion: RestorationCompletion?

    public init(repairedGroups: Set<RestorationGroupID> = [],
                expansion: ExpansionState? = nil, completion: RestorationCompletion? = nil) {
        self.repairedGroups = repairedGroups
        self.expansion = expansion
        self.completion = completion
    }

    public static var initial: ShopRestorationState { ShopRestorationState() }
}

public struct RestorationProgress: Equatable, Sendable {
    public static let requiredDecorVariety = 3
    public static let requiredTradingDays = 3
    public let repairedGroups: Int
    public let decorationVariety: Int
    public let successfulTradingDays: Int
    public let hasExpansion: Bool

    public var isComplete: Bool {
        repairedGroups == RestorationGroupID.allCases.count &&
        decorationVariety >= Self.requiredDecorVariety &&
        successfulTradingDays >= Self.requiredTradingDays && hasExpansion
    }
}

public enum RestorationError: Error, Equatable, Sendable {
    case repairAlreadyCompleted(RestorationGroupID)
    case noRepairableCells(RestorationGroupID)
    case repairsRequired
    case alreadyExpanded
    case unsupportedStarterLayout
    case expansionConnectionBlocked
}

extension GameState {
    public var restorationProgress: RestorationProgress {
        RestorationProgress(
            repairedGroups: restoration.repairedGroups.count,
            decorationVariety: Set(fixtures.filter { $0.kind.isDecoration }.map(\.kind)).count,
            successfulTradingDays: dayHistory.filter { $0.customersServed > 0 }.count,
            hasExpansion: restoration.expansion != nil
        )
    }
    public var hasCompletedRestoration: Bool { restoration.completion != nil }
}

/// World mutations are prepared as values and validated before they are committed.
enum RestorationWorld {
    static func expanded(_ world: ShopWorldState, using expansion: ExpansionState) -> ShopWorldState {
        let shift = expansion.starterOrigin
        let room = expansion.roomOrigin
        let size = ExpansionState.roomSize
        let layout = expansion.layout
        var oldCells: [GridPoint: WorldCellMetadata] = [:]
        for cell in world.hitMap.cells {
            let point = GridPoint(x: cell.point.x + shift.x, y: cell.point.y + shift.y)
            oldCells[point] = WorldCellMetadata(point: point, zone: cell.zone,
                                               staticBlocker: cell.staticBlocker,
                                               adjacentWalls: cell.adjacentWalls)
        }
        let roomPoints = Set((room.y..<(room.y + size)).flatMap { y in
            (room.x..<(room.x + size)).map { GridPoint(x: $0, y: y) }
        })
        let interior = Set(oldCells.keys).union(roomPoints)
        var cells: [WorldCellMetadata] = []
        for y in 0..<layout.depth {
            for x in 0..<layout.width {
                let point = GridPoint(x: x, y: y)
                guard interior.contains(point) else {
                    cells.append(WorldCellMetadata(point: point, zone: .outside))
                    continue
                }
                var cell = oldCells[point] ?? WorldCellMetadata(point: point)
                // Exterior edges now follow the union of the two rooms. The
                // full five-cell shared side is the open passage.
                cell.adjacentWalls = []
                if !interior.contains(GridPoint(x: x - 1, y: y)) { cell.adjacentWalls.insert(.left) }
                if !interior.contains(GridPoint(x: x + 1, y: y)) { cell.adjacentWalls.insert(.right) }
                if !interior.contains(GridPoint(x: x, y: y - 1)) { cell.adjacentWalls.insert(.front) }
                if !interior.contains(GridPoint(x: x, y: y + 1)) { cell.adjacentWalls.insert(.rear) }
                cells.append(cell)
            }
        }
        let tiles = world.floor.tiles.map { tile in
            FloorTileState(point: GridPoint(x: tile.point.x + shift.x, y: tile.point.y + shift.y),
                           styleID: tile.styleID)
        }
        return ShopWorldState(floor: ShopFloorState(layout: layout, tiles: tiles),
                              hitMap: WorldHitMap(layout: layout, cells: cells))
    }

    /// Versions 1–3 used approximate debris coordinates. Relocate a known
    /// blocker only if the calibrated destination is clear of saved furniture.
    static func migrateCalibration(_ world: inout ShopWorldState, fixtures: [PlacedFixture]) {
        guard world.hitMap.layout == .starter else { return }
        guard fixtures.allSatisfy({ fixture in
            let footprint = FixtureCatalog.definition(for: fixture.kind).footprint.rotated(fixture.rotation)
            return fixture.origin.x >= 0 && fixture.origin.y >= 0 &&
                fixture.origin.x <= 11 - footprint.width && fixture.origin.y <= 11 - footprint.depth
        }) else { return } // The normal integrity validator rejects invalid coordinates.
        let occupied = world.hitMap.dynamicOccupancy(fixtures: fixtures)
        let moves: [(StaticBlockerID, GridPoint, GridPoint)] = [
            (.rubble, GridPoint(x: 1, y: 4), GridPoint(x: 1, y: 5)),
            (.brokenBoards, GridPoint(x: 9, y: 4), GridPoint(x: 9, y: 5)),
            (.discardedPapers, GridPoint(x: 8, y: 2), GridPoint(x: 9, y: 2))
        ]
        for (blocker, from, to) in moves {
            guard world.hitMap.cell(at: from)?.staticBlocker == blocker,
                  world.hitMap.cell(at: to)?.staticBlocker == nil, occupied[to] == nil else { continue }
            world.hitMap.updateCell(at: from) { $0.staticBlocker = nil }
            world.hitMap.updateCell(at: to) { $0.staticBlocker = blocker }
        }
    }
}
