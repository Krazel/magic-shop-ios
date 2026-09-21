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
        case .left: return "Left"
        case .right: return "Right"
        case .rear: return "Back"
        }
    }
}

/// Move one entire wall outward by five cells, leaving a single rectangle.
/// A left purchase translates the starter by +5 x; migrated saves are already shifted.
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
        case .left: return GridPoint(x: 0, y: 0)
        case .right: return GridPoint(x: 11, y: 0)
        case .rear: return GridPoint(x: 0, y: 11)
        }
    }
    public var roomFootprint: GridFootprint {
        direction == .rear ? GridFootprint(width: 11, depth: 5) : GridFootprint(width: 5, depth: 11)
    }
    public var layout: ShopLayout {
        direction == .rear ? ShopLayout(width: 11, depth: 16) : ShopLayout(width: 16, depth: 11)
    }

    /// The complete removed wall in starter coordinates, before translation.
    public var starterConnectionCells: Set<GridPoint> {
        Set((0...10).map { value in
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
        rectangularized(world, using: expansion, translateStarter: true)
    }

    /// Migration keeps existing coordinates, including a previously shifted
    /// left starter. Only a new purchase translates the original 11x11 world.
    static func rectangularized(_ world: ShopWorldState, using expansion: ExpansionState,
                                translateStarter: Bool) -> ShopWorldState {
        let shift = translateStarter ? expansion.starterOrigin : GridPoint(x: 0, y: 0)
        let layout = expansion.layout
        var supplied: [GridPoint: WorldCellMetadata] = [:]
        for cell in world.hitMap.cells {
            let point = GridPoint(x: cell.point.x + shift.x, y: cell.point.y + shift.y)
            supplied[point] = WorldCellMetadata(point: point, zone: cell.zone,
                staticBlocker: cell.staticBlocker, adjacentWalls: cell.adjacentWalls)
        }
        // The front corner belongs to the moved perimeter, not the former seam.
        let oldColumn = expansion.direction == .left ? GridPoint(x: 5, y: 0) : GridPoint(x: 10, y: 0)
        let newColumn = expansion.direction == .left ? GridPoint(x: 0, y: 0) : GridPoint(x: 15, y: 0)
        if expansion.direction != .rear { supplied[oldColumn]?.staticBlocker = nil }
        let interior = Set((0..<layout.depth).flatMap { y in
            (0..<layout.width).map { GridPoint(x: $0, y: y) }
        })
        var cells: [WorldCellMetadata] = []
        for y in 0..<layout.depth {
            for x in 0..<layout.width {
                let point = GridPoint(x: x, y: y)
                var cell = supplied[point] ?? WorldCellMetadata(point: point)
                if cell.zone == .outside { cell.zone = .interior }
                if expansion.direction != .rear && point == newColumn { cell.staticBlocker = .frontColumn }
                cell.adjacentWalls = wallAdjacency(at: point, interior: interior)
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

    static func wallAdjacency(at point: GridPoint, interior: Set<GridPoint>) -> Set<WallSide> {
        var result = Set<WallSide>()
        if !interior.contains(GridPoint(x: point.x - 1, y: point.y)) { result.insert(.left) }
        if !interior.contains(GridPoint(x: point.x + 1, y: point.y)) { result.insert(.right) }
        if !interior.contains(GridPoint(x: point.x, y: point.y - 1)) { result.insert(.front) }
        if !interior.contains(GridPoint(x: point.x, y: point.y + 1)) { result.insert(.rear) }
        return result
    }

    /// Move only furniture that loses every mounting wall. Reserve all other
    /// footprints, then pack larger items first and resolve ties by UUID.
    /// Backtracking prevents a one-cell decoration from stranding a shelf.
    static func relocateWallFixtures(in state: inout GameState, from oldMap: WorldHitMap) throws -> Bool {
        let moving = state.fixtures.indices.filter { index in
            let fixture = state.fixtures[index]
            return FixtureCatalog.definition(for: fixture.kind).placementConstraint == .adjacentToWall &&
                state.world.hitMap.commonWallAdjacency(for: PlacementRules.occupiedCells(for: fixture)).isEmpty
        }.sorted { left, right in
            let a = PlacementRules.occupiedCells(for: state.fixtures[left]).count
            let b = PlacementRules.occupiedCells(for: state.fixtures[right]).count
            return a == b ? state.fixtures[left].id.uuidString < state.fixtures[right].id.uuidString : a > b
        }
        guard !moving.isEmpty else { return false }
        let movingSet = Set(moving)
        var occupied = Set(state.fixtures.indices.filter { !movingSet.contains($0) }.flatMap {
            PlacementRules.occupiedCells(for: state.fixtures[$0])
        })
        struct Candidate {
            let point: GridPoint
            let cells: Set<GridPoint>
            let sideRank: Int
            let distance: Int
        }
        let map = state.world.hitMap
        var choices: [[Candidate]] = []
        for index in moving {
            let fixture = state.fixtures[index]
            let oldWalls = oldMap.commonWallAdjacency(for: PlacementRules.occupiedCells(for: fixture))
            let footprint = FixtureCatalog.definition(for: fixture.kind).footprint.rotated(fixture.rotation)
            var candidates: [Candidate] = []
            for y in 0...(map.layout.depth - footprint.depth) {
                for x in 0...(map.layout.width - footprint.width) {
                    let point = GridPoint(x: x, y: y)
                    let cells = PlacementRules.occupiedCells(origin: point, footprint: footprint)
                    let walls = map.commonWallAdjacency(for: cells)
                    guard !walls.isEmpty, cells.isDisjoint(with: occupied), cells.allSatisfy({
                        map.cell(at: $0)?.zone == .interior && map.cell(at: $0)?.staticBlocker == nil
                    }) else { continue }
                    candidates.append(Candidate(point: point, cells: cells,
                        sideRank: walls.isDisjoint(with: oldWalls) ? 1 : 0,
                        distance: abs(point.x - fixture.origin.x) + abs(point.y - fixture.origin.y)))
                }
            }
            candidates.sort { a, b in
                if a.sideRank != b.sideRank { return a.sideRank < b.sideRank }
                if a.distance != b.distance { return a.distance < b.distance }
                return a.point.y == b.point.y ? a.point.x < b.point.x : a.point.y < b.point.y
            }
            choices.append(candidates)
        }
        var selected: [Int: GridPoint] = [:]
        var failed = Set<String>()
        func place(_ cursor: Int) -> Bool {
            if cursor == moving.count { return true }
            let key = String(cursor) + ":" + occupied.map { $0.y * map.layout.width + $0.x }
                .sorted().map(String.init).joined(separator: ",")
            guard !failed.contains(key) else { return false }
            for candidate in choices[cursor] where candidate.cells.isDisjoint(with: occupied) {
                occupied.formUnion(candidate.cells)
                selected[moving[cursor]] = candidate.point
                if place(cursor + 1) { return true }
                occupied.subtract(candidate.cells)
            }
            selected.removeValue(forKey: moving[cursor])
            failed.insert(key)
            return false
        }
        guard place(0) else {
            throw GameStateValidationError.invalidState("No safe perimeter placement for saved wall furniture")
        }
        for (index, point) in selected { state.fixtures[index].origin = point }
        return true
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
