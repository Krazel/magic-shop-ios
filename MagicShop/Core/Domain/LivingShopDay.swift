import Foundation

public enum LivingVisitorStatus: String, Codable, Sendable {
    case notArrived, arriving, browsing, comparing, leaving, departed
}

public struct LivingPosition: Equatable, Sendable {
    public let from: GridPoint
    public let to: GridPoint
    public let progress: Double
}

public struct LivingBrowseStop: Codable, Equatable, Sendable {
    public let fixtureID: UUID
    public let arrivalMinute: Int
    public let departureMinute: Int
    /// Walk from the preceding stop (or entrance) to a reachable display edge.
    public let path: [GridPoint]
}

public struct LivingVisitor: Identifiable, Codable, Equatable, Sendable {
    public let id: VisitID
    public let arrivalMinute: Int
    public let departureMinute: Int
    public let decisionMinute: Int
    public let preferredProduct: ProductKind
    public let secondaryProduct: ProductKind?
    public let budget: Int
    public let interestRoll: Int
    public let hasBuyingIntent: Bool
    public let stops: [LivingBrowseStop]
    public let exitPath: [GridPoint]
    public private(set) var outcome: VisitOutcome?
    public var sale: SaleReceipt? { outcome?.sale }

    public func status(at minute: Int) -> LivingVisitorStatus {
        if minute < arrivalMinute { return .notArrived }
        if minute >= departureMinute { return .departed }
        if minute >= (stops.last?.departureMinute ?? decisionMinute) { return .leaving }
        if minute < (stops.first?.arrivalMinute ?? decisionMinute) { return .arriving }
        if stops.dropFirst().contains(where: { minute >= $0.arrivalMinute && minute < $0.departureMinute }) {
            return .comparing
        }
        return .browsing
    }

    public func position(at minute: Double) -> LivingPosition {
        var startMinute = arrivalMinute
        for stop in stops {
            if minute < Double(stop.arrivalMinute) {
                return Self.interpolate(stop.path, fraction: (minute - Double(startMinute)) /
                    Double(max(1, stop.arrivalMinute - startMinute)))
            }
            if minute < Double(stop.departureMinute), let point = stop.path.last {
                return LivingPosition(from: point, to: point, progress: 0)
            }
            startMinute = stop.departureMinute
        }
        return Self.interpolate(exitPath, fraction: (minute - Double(startMinute)) /
            Double(max(1, departureMinute - startMinute)))
    }

    private static func interpolate(_ path: [GridPoint], fraction: Double) -> LivingPosition {
        guard let first = path.first else {
            return LivingPosition(from: GridPoint(x: 0, y: 0), to: GridPoint(x: 0, y: 0), progress: 0)
        }
        guard path.count > 1 else { return LivingPosition(from: first, to: first, progress: 0) }
        let safe = fraction.isFinite ? min(max(fraction, 0), 1) : 0
        let progress = safe * Double(path.count - 1)
        let index = min(Int(progress), path.count - 2)
        return LivingPosition(from: path[index], to: path[index + 1], progress: progress - Double(index))
    }

    mutating func record(_ result: VisitOutcome) { outcome = result }
}

public struct LivingDayAdvance: Equatable, Sendable {
    public let fromMinute: Int
    public let toMinute: Int
    public let outcomes: [VisitOutcome]
    public var sales: [SaleReceipt] { outcomes.compactMap(\.sale) }
    public let isFinished: Bool
}

/// The simulation cursor, profiles, routes and purchase outcomes are persisted.
/// Advancing requires the exact old minute, so a retried command cannot sell twice.
public struct LivingShopDay: Identifiable, Codable, Equatable, Sendable {
    public static let visitorCount = 12
    public let id: UUID
    public let dayNumber: Int
    public let seed: UInt64
    public let openingBalance: Int
    public private(set) var minute: Int
    public private(set) var inventoryCashFlow: Int
    public private(set) var visitors: [LivingVisitor]

    public var activeVisitors: [LivingVisitor] {
        visitors.filter { $0.arrivalMinute <= minute && minute < $0.departureMinute }
    }
    public var outcomes: [VisitOutcome] { visitors.compactMap(\.outcome) }
    public var sales: [SaleReceipt] { outcomes.compactMap(\.sale) }
    public var revenue: Int { sales.reduce(0) { $0 + $1.revenue } }
    public var costOfGoods: Int { sales.reduce(0) { $0 + $1.costOfGoods } }
    public var profit: Int { revenue - costOfGoods }
    public var isFinished: Bool { minute == ShopCalendar.closingMinute }
    public var summary: DaySummary? {
        guard isFinished else { return nil }
        return DaySummary(id: id, dayNumber: dayNumber, outcomes: outcomes,
                          simulation: .living, seed: seed)
    }

    init(id: UUID, dayNumber: Int, seed: UInt64, state: GameState) throws {
        self.id = id
        self.dayNumber = dayNumber
        self.seed = seed
        openingBalance = state.balance
        minute = ShopCalendar.openingMinute
        inventoryCashFlow = 0
        visitors = try Self.makeVisitors(id: id, seed: seed, state: state)
    }

    /// Day number alone supplies a stable default; Swift Hasher and wall time
    /// never influence visitor behavior. A supplied seed supports exact QA replay.
    public static func defaultSeed(dayNumber: Int) -> UInt64 {
        UInt64(max(dayNumber, 1)) &* 0x9E3779B97F4A7C15 &+ 0x4D41474943
    }

    mutating func setMinute(_ value: Int) { minute = value }
    mutating func record(_ outcome: VisitOutcome, visitorIndex: Int) {
        visitors[visitorIndex].record(outcome)
    }
    mutating func recordInventoryCashFlow(_ delta: Int) throws {
        let total = inventoryCashFlow.addingReportingOverflow(delta)
        guard !total.overflow else { throw CommerceError.totalOverflow }
        inventoryCashFlow = total.partialValue
    }

    private static func makeVisitors(id: UUID, seed: UInt64, state: GameState) throws -> [LivingVisitor] {
        let reachable = ShopAccess.reachableCells(in: state)
        guard let entrance = state.world.hitMap.cells.filter({
            $0.zone == .entrance && reachable.contains($0.point)
        }).map(\.point).sorted(by: pointOrder).first else { throw LivingShopError.noWalkableEntrance }
        let displays = state.fixtures.filter {
            FixtureCatalog.definition(for: $0.kind).stockCapacity > 0 && ShopAccess.isReachable($0, in: state)
        }.sorted { $0.id.uuidString < $1.id.uuidString }
        var random = LivingRandom(seed: seed)
        var result: [LivingVisitor] = []
        for index in 0..<visitorCount {
            // 16–64 minute arrival gaps, 96–115 minute stays. This guarantees
            // no more than four concurrent visitors, with overlap through the day.
            let arrival = ShopCalendar.openingMinute + index * 40 + random.next(25)
            let departure = min(ShopCalendar.closingMinute, arrival + 96 + random.next(20))
            let preferred = ProductKind.allCases[random.next(ProductKind.allCases.count)]
            let secondary = random.next(3) == 0 ? nil :
                ProductKind.allCases[(ProductKind.allCases.firstIndex(of: preferred)! + 1 + random.next(2)) % 3]
            let market = ProductCatalog.definition(for: preferred).salePrice
            let budget = market * (90 + random.next(131)) / 100
            let roll = random.next(100)
            let buyingIntent = random.next(100) < 85
            var shuffled = displays
            if shuffled.count > 1 {
                for cursor in stride(from: shuffled.count - 1, through: 1, by: -1) {
                    shuffled.swapAt(cursor, random.next(cursor + 1))
                }
            }
            let chosen = Array(shuffled.prefix(2 + random.next(2)))
            let segment = max(2, (departure - arrival) / (chosen.count + 1))
            var previous = entrance
            var previousMinute = arrival
            var stops: [LivingBrowseStop] = []
            for fixture in chosen {
                guard let path = ShopAccess.path(from: previous, to: fixture, in: state),
                      let destination = path.last else { continue }
                stops.append(LivingBrowseStop(fixtureID: fixture.id,
                    arrivalMinute: previousMinute + segment / 2,
                    departureMinute: previousMinute + segment, path: path))
                previous = destination
                previousMinute += segment
            }
            let exit = ShopAccess.path(from: previous, to: entrance, in: state) ?? [previous]
            let decision = max(arrival + 1, (stops.last?.departureMinute ?? (arrival + segment)) - 2)
            result.append(LivingVisitor(id: VisitID(dayID: id, index: index),
                arrivalMinute: arrival, departureMinute: departure, decisionMinute: decision,
                preferredProduct: preferred, secondaryProduct: secondary, budget: budget,
                interestRoll: roll, hasBuyingIntent: buyingIntent, stops: stops,
                exitPath: exit, outcome: nil))
        }
        return result
    }

    private static func pointOrder(_ left: GridPoint, _ right: GridPoint) -> Bool {
        left.y == right.y ? left.x < right.x : left.y < right.y
    }
}

struct LivingRandom {
    private var value: UInt64
    init(seed: UInt64) { value = seed }
    mutating func next(_ upperBound: Int) -> Int {
        value = value &* 6364136223846793005 &+ 1442695040888963407
        return Int((value >> 32) % UInt64(upperBound))
    }
}
