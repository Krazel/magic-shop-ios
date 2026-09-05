import Foundation

public struct FloorStyleID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty)
        self.rawValue = rawValue
    }

    public static let wornTerracotta = FloorStyleID(rawValue: "wornTerracotta")
    public static let terracotta = FloorStyleID(rawValue: "terracotta")
    public static let warmOak = FloorStyleID(rawValue: "warmOak")
    public static let checkerStone = FloorStyleID(rawValue: "checkerStone")
}

public struct FloorStyle: Equatable, Hashable, Sendable {
    public let id: FloorStyleID
    public let displayName: String
    public let textureAssetName: String
    public let variantAssetNames: [String]
    public let crackDecalAssetName: String?
    public let stainDecalAssetName: String?
    public let baseColorHex: String
    public let alternateColorHex: String
    public let groutColorHex: String

    public init(
        id: FloorStyleID,
        displayName: String,
        textureAssetName: String,
        variantAssetNames: [String] = [],
        crackDecalAssetName: String? = nil,
        stainDecalAssetName: String? = nil,
        baseColorHex: String,
        alternateColorHex: String,
        groutColorHex: String
    ) {
        self.id = id
        self.displayName = displayName
        self.textureAssetName = textureAssetName
        self.variantAssetNames = variantAssetNames
        self.crackDecalAssetName = crackDecalAssetName
        self.stainDecalAssetName = stainDecalAssetName
        self.baseColorHex = baseColorHex
        self.alternateColorHex = alternateColorHex
        self.groutColorHex = groutColorHex
    }
}

public enum FloorStyleCatalog {
    public static let wornTerracotta = FloorStyle(
        id: .wornTerracotta,
        displayName: "Worn Terracotta",
        textureAssetName: "WornTerracottaTile",
        variantAssetNames: ["WornTerracottaVariantA", "WornTerracottaVariantB"],
        crackDecalAssetName: "TerracottaCrackDecal",
        stainDecalAssetName: "TerracottaStainDecal",
        baseColorHex: "A65E35",
        alternateColorHex: "87452C",
        groutColorHex: "512C24"
    )

    public static let terracotta = FloorStyle(id: .terracotta, displayName: "Terracotta",
        textureAssetName: "FloorTerracotta", baseColorHex: "B7704B",
        alternateColorHex: "A65E35", groutColorHex: "673D2A")
    public static let warmOak = FloorStyle(id: .warmOak, displayName: "Warm Oak",
        textureAssetName: "FloorWarmOak", baseColorHex: "B88956",
        alternateColorHex: "9D7147", groutColorHex: "634831")
    public static let checkerStone = FloorStyle(id: .checkerStone, displayName: "Checker Stone",
        textureAssetName: "FloorCheckerStone", baseColorHex: "D9CFB4",
        alternateColorHex: "718E82", groutColorHex: "53665E")
    public static let paintable: [FloorStyle] = [terracotta, warmOak, checkerStone]
    public static let all: [FloorStyle] = [wornTerracotta] + paintable

    public static func definition(for id: FloorStyleID) -> FloorStyle? {
        all.first { $0.id == id }
    }
}

public struct FloorTileState: Codable, Equatable, Hashable, Sendable {
    public let point: GridPoint
    public var styleID: FloorStyleID

    public init(point: GridPoint, styleID: FloorStyleID) {
        self.point = point
        self.styleID = styleID
    }
}

public struct ShopFloorState: Codable, Equatable, Sendable {
    public let layout: ShopLayout
    public private(set) var tiles: [FloorTileState]

    public init(
        layout: ShopLayout = .starter,
        fill styleID: FloorStyleID = .wornTerracotta
    ) {
        self.layout = layout
        self.tiles = Self.points(in: layout).map {
            FloorTileState(point: $0, styleID: styleID)
        }
    }

    public init(layout: ShopLayout, tiles: [FloorTileState]) {
        self.layout = layout
        let supplied = Dictionary(uniqueKeysWithValues: tiles.map { ($0.point, $0.styleID) })
        self.tiles = Self.points(in: layout).map { point in
            FloorTileState(
                point: point,
                styleID: supplied[point] ?? .wornTerracotta
            )
        }
    }

    public func styleID(at point: GridPoint) -> FloorStyleID? {
        tiles.first { $0.point == point }?.styleID
    }

    @discardableResult
    public mutating func setStyleID(_ styleID: FloorStyleID, at point: GridPoint) -> Bool {
        guard let index = tiles.firstIndex(where: { $0.point == point }) else { return false }
        tiles[index].styleID = styleID
        return true
    }

    public mutating func replaceAll(with styleID: FloorStyleID) {
        for index in tiles.indices {
            tiles[index].styleID = styleID
        }
    }

    private static func points(in layout: ShopLayout) -> [GridPoint] {
        (0..<layout.depth).flatMap { y in
            (0..<layout.width).map { x in GridPoint(x: x, y: y) }
        }
    }
}

public enum WorldCellZone: String, Codable, Equatable, Hashable, Sendable {
    case outside
    case interior
    case entrance
}

public enum WallSide: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case front
    case rear
    case left
    case right
}

public enum StaticBlockerID: String, Codable, Equatable, Hashable, Sendable {
    case rubble
    case brokenBoards
    case discardedPapers
    case frontColumn
}

public struct WorldCellMetadata: Codable, Equatable, Hashable, Sendable {
    public let point: GridPoint
    public var zone: WorldCellZone
    public var staticBlocker: StaticBlockerID?
    public var adjacentWalls: Set<WallSide>

    public init(
        point: GridPoint,
        zone: WorldCellZone = .interior,
        staticBlocker: StaticBlockerID? = nil,
        adjacentWalls: Set<WallSide> = []
    ) {
        self.point = point
        self.zone = zone
        self.staticBlocker = staticBlocker
        self.adjacentWalls = adjacentWalls
    }
}

public enum WorldCellHit: Equatable, Sendable {
    case outside
    case entrance
    case blocked(StaticBlockerID)
    case occupied(UUID)
    case available
}

public struct WorldHitMap: Codable, Equatable, Sendable {
    public let layout: ShopLayout
    public private(set) var cells: [WorldCellMetadata]

    public init(layout: ShopLayout, cells: [WorldCellMetadata]) {
        self.layout = layout
        let supplied = Dictionary(uniqueKeysWithValues: cells.map { ($0.point, $0) })
        self.cells = Self.points(in: layout).compactMap { supplied[$0] }
    }

    public static var starter: WorldHitMap {
        let layout = ShopLayout.starter
        let entrance = GridPoint(x: layout.width / 2, y: 0)
        let blockers: [GridPoint: StaticBlockerID] = [
            GridPoint(x: 1, y: 5): .rubble,
            GridPoint(x: 9, y: 5): .brokenBoards,
            GridPoint(x: 9, y: 2): .discardedPapers,
            GridPoint(x: 0, y: 0): .frontColumn,
            GridPoint(x: layout.width - 1, y: 0): .frontColumn
        ]

        let cells = Self.points(in: layout).map { point -> WorldCellMetadata in
            var walls = Set<WallSide>()
            if point.x == 0 { walls.insert(.left) }
            if point.x == layout.width - 1 { walls.insert(.right) }
            if point.y == 0 { walls.insert(.front) }
            if point.y == layout.depth - 1 { walls.insert(.rear) }
            return WorldCellMetadata(
                point: point,
                zone: point == entrance ? .entrance : .interior,
                staticBlocker: blockers[point],
                adjacentWalls: walls
            )
        }
        return WorldHitMap(layout: layout, cells: cells)
    }

    public func cell(at point: GridPoint) -> WorldCellMetadata? {
        cells.first { $0.point == point }
    }

    @discardableResult
    public mutating func updateCell(
        at point: GridPoint,
        _ update: (inout WorldCellMetadata) -> Void
    ) -> Bool {
        guard let index = cells.firstIndex(where: { $0.point == point }) else { return false }
        update(&cells[index])
        return true
    }

    public func dynamicOccupancy(fixtures: [PlacedFixture]) -> [GridPoint: UUID] {
        var result: [GridPoint: UUID] = [:]
        for fixture in fixtures {
            let definition = FixtureCatalog.definition(for: fixture.kind)
            let footprint = definition.footprint.rotated(fixture.rotation)
            for x in fixture.origin.x..<(fixture.origin.x + footprint.width) {
                for y in fixture.origin.y..<(fixture.origin.y + footprint.depth) {
                    result[GridPoint(x: x, y: y)] = fixture.id
                }
            }
        }
        return result
    }

    public func hit(at point: GridPoint, fixtures: [PlacedFixture]) -> WorldCellHit {
        guard let cell = cell(at: point) else { return .outside }
        if cell.zone == .outside { return .outside }
        if cell.zone == .entrance { return .entrance }
        if let blocker = cell.staticBlocker { return .blocked(blocker) }
        if let fixtureID = dynamicOccupancy(fixtures: fixtures)[point] {
            return .occupied(fixtureID)
        }
        return .available
    }

    public func commonWallAdjacency(for points: Set<GridPoint>) -> Set<WallSide> {
        guard let first = points.first,
              let firstCell = cell(at: first) else { return [] }
        return points.dropFirst().reduce(firstCell.adjacentWalls) { result, point in
            guard let cell = cell(at: point) else { return [] }
            return result.intersection(cell.adjacentWalls)
        }
    }

    private static func points(in layout: ShopLayout) -> [GridPoint] {
        (0..<layout.depth).flatMap { y in
            (0..<layout.width).map { x in GridPoint(x: x, y: y) }
        }
    }
}

public struct ShopWorldState: Codable, Equatable, Sendable {
    public var floor: ShopFloorState
    public var hitMap: WorldHitMap

    public init(floor: ShopFloorState, hitMap: WorldHitMap) {
        precondition(floor.layout == hitMap.layout)
        self.floor = floor
        self.hitMap = hitMap
    }

    public static var starter: ShopWorldState {
        ShopWorldState(
            floor: ShopFloorState(layout: .starter, fill: .wornTerracotta),
            hitMap: .starter
        )
    }
}

public struct WorldPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct WorldGridGeometry: Equatable, Sendable {
    public let layout: ShopLayout
    public let tileSide: Double
    public let origin: WorldPoint

    public init(
        layout: ShopLayout = .starter,
        tileSide: Double,
        origin: WorldPoint? = nil
    ) {
        precondition(tileSide > 0)
        self.layout = layout
        self.tileSide = tileSide
        self.origin = origin ?? WorldPoint(
            x: -Double(layout.width) * tileSide / 2,
            y: -Double(layout.depth) * tileSide / 2
        )
    }

    public func cell(at worldPoint: WorldPoint) -> GridPoint? {
        let localX = worldPoint.x - origin.x
        let localY = worldPoint.y - origin.y
        guard localX >= 0,
              localY >= 0,
              localX < Double(layout.width) * tileSide,
              localY < Double(layout.depth) * tileSide else { return nil }
        return GridPoint(
            x: Int(floor(localX / tileSide)),
            y: Int(floor(localY / tileSide))
        )
    }

    public func center(of point: GridPoint) -> WorldPoint? {
        guard point.x >= 0, point.y >= 0,
              point.x < layout.width, point.y < layout.depth else { return nil }
        return WorldPoint(
            x: origin.x + (Double(point.x) + 0.5) * tileSide,
            y: origin.y + (Double(point.y) + 0.5) * tileSide
        )
    }
}

public struct ScreenPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct CameraViewportTransform: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let camera: WorldCameraState

    public init(width: Double, height: Double, camera: WorldCameraState) {
        precondition(width > 0 && height > 0)
        self.width = width
        self.height = height
        self.camera = camera
    }

    public func worldPoint(fromScreen point: ScreenPoint) -> WorldPoint {
        WorldPoint(
            x: (point.x - width / 2) * camera.zoom,
            y: (height / 2 - point.y) * camera.zoom + camera.verticalOffset
        )
    }
}

extension ShopWorldState {
    /// Historical map used only as the schema-1 migration source.
    static var legacyStarter: ShopWorldState {
        var world = Self.starter
        let moves: [(GridPoint, GridPoint, StaticBlockerID)] = [
            (GridPoint(x: 1, y: 5), GridPoint(x: 1, y: 4), .rubble),
            (GridPoint(x: 9, y: 5), GridPoint(x: 9, y: 4), .brokenBoards),
            (GridPoint(x: 9, y: 2), GridPoint(x: 8, y: 2), .discardedPapers)
        ]
        for (from, to, blocker) in moves {
            world.hitMap.updateCell(at: from) { $0.staticBlocker = nil }
            world.hitMap.updateCell(at: to) { $0.staticBlocker = blocker }
        }
        return world
    }
}
