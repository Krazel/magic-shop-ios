import Foundation

public struct GameState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 4
    public static let startingBalance = 500

    public var schemaVersion: Int
    public var shopName: String?
    public var onboardingCompleted: Bool
    public var balance: Int
    public var fixtures: [PlacedFixture]
    public var world: ShopWorldState
    public var stock: [StockItem]
    public var phase: ShopPhase
    public var currentDay: ShopDayState?
    public var dayHistory: [DaySummary]
    public var restoration: ShopRestorationState

    public init(
        schemaVersion: Int = GameState.currentSchemaVersion,
        shopName: String? = nil,
        onboardingCompleted: Bool = false,
        balance: Int = GameState.startingBalance,
        fixtures: [PlacedFixture] = [],
        world: ShopWorldState = .starter,
        stock: [StockItem] = [],
        phase: ShopPhase = .preparing,
        currentDay: ShopDayState? = nil,
        dayHistory: [DaySummary] = [],
        restoration: ShopRestorationState = .initial
    ) {
        self.schemaVersion = schemaVersion
        self.shopName = shopName
        self.onboardingCompleted = onboardingCompleted
        self.balance = balance
        self.fixtures = fixtures
        self.world = world
        self.stock = stock
        self.phase = phase
        self.currentDay = currentDay
        self.dayHistory = dayHistory
        self.restoration = restoration
    }

    public static var initial: GameState { GameState() }
    public var completedDays: Int { dayHistory.count }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, shopName, onboardingCompleted, balance, fixtures, world
        case stock, phase, currentDay, dayHistory, restoration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let savedVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard (1...Self.currentSchemaVersion).contains(savedVersion) else {
            throw GameStateValidationError.unsupportedSchemaVersion(savedVersion)
        }
        schemaVersion = Self.currentSchemaVersion
        shopName = try container.decodeIfPresent(String.self, forKey: .shopName)
        if savedVersion >= 3 {
            // Current saves must contain their economy and shop state. Missing
            // or null fields are corruption, never permission to reset progress.
            onboardingCompleted = try container.decode(Bool.self, forKey: .onboardingCompleted)
            balance = try container.decode(Int.self, forKey: .balance)
            fixtures = try container.decode([PlacedFixture].self, forKey: .fixtures)
        } else {
            onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
            balance = try container.decodeIfPresent(Int.self, forKey: .balance) ?? Self.startingBalance
            fixtures = try container.decodeIfPresent([PlacedFixture].self, forKey: .fixtures) ?? []
        }
        if savedVersion >= 2 {
            world = try container.decode(ShopWorldState.self, forKey: .world)
        } else {
            // Schema 1 predated the persistent world.
            world = try container.decodeIfPresent(ShopWorldState.self, forKey: .world) ?? .legacyStarter
        }

        if savedVersion < 3 {
            // Legacy saves had no commerce state. Their shop and money survive
            // intact; no inventory, rewards or completed days are invented.
            stock = []
            phase = .preparing
            currentDay = nil
            dayHistory = []
        } else {
            stock = try container.decode([StockItem].self, forKey: .stock)
            phase = try container.decode(ShopPhase.self, forKey: .phase)
            currentDay = try container.decodeIfPresent(ShopDayState.self, forKey: .currentDay)
            dayHistory = try container.decode([DaySummary].self, forKey: .dayHistory)
        }
        if savedVersion < 4 {
            RestorationWorld.migrateCalibration(&world, fixtures: fixtures)
            let calibratedCells = world.hitMap.cells
            let repaired = RepairCatalog.all.filter { repair in
                !calibratedCells.contains { $0.staticBlocker == repair.blocker }
            }.map(\.id)
            restoration = ShopRestorationState(repairedGroups: Set(repaired))
        } else {
            restoration = try container.decode(ShopRestorationState.self, forKey: .restoration)
        }
        try validateIntegrity()
    }

    /// Reject malformed state before it can become a writable game session.
    /// Existing legacy furniture is not rejudged against newer debris metadata.
    public func validateIntegrity() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw GameStateValidationError.unsupportedSchemaVersion(schemaVersion)
        }
        guard balance >= 0 else { throw invalid("Negative balance") }
        let layout = world.hitMap.layout
        let cellCount = layout.width.multipliedReportingOverflow(by: layout.depth)
        guard layout.width > 0, layout.depth > 0, !cellCount.overflow,
              world.floor.layout == layout,
              world.hitMap.cells.count == cellCount.partialValue,
              world.floor.tiles.count == cellCount.partialValue else {
            throw invalid("Invalid world dimensions or incomplete world")
        }
        func isInside(_ point: GridPoint) -> Bool {
            point.x >= 0 && point.y >= 0 && point.x < layout.width && point.y < layout.depth
        }
        guard Set(world.hitMap.cells.map(\.point)).count == cellCount.partialValue,
              Set(world.floor.tiles.map(\.point)).count == cellCount.partialValue,
              world.hitMap.cells.allSatisfy({ isInside($0.point) }),
              world.floor.tiles.allSatisfy({ isInside($0.point) && !$0.styleID.rawValue.isEmpty }) else {
            throw invalid("Invalid or duplicate world cells")
        }
        guard Set(fixtures.map(\.id)).count == fixtures.count else {
            throw invalid("Duplicate furniture identity")
        }
        for fixture in fixtures {
            let footprint = FixtureCatalog.definition(for: fixture.kind).footprint.rotated(fixture.rotation)
            guard fixture.origin.x >= 0, fixture.origin.y >= 0,
                  fixture.origin.x <= layout.width - footprint.width,
                  fixture.origin.y <= layout.depth - footprint.depth else {
                throw invalid("Furniture outside world")
            }
            guard PlacementRules.occupiedCells(for: fixture).allSatisfy({
                world.hitMap.cell(at: $0)?.zone != .outside
            }) else { throw invalid("Furniture in outside space") }
        }
        guard Set(stock.map(\.id)).count == stock.count else {
            throw invalid("Duplicate stock identity")
        }
        var slots = Set<StockSlot>()
        for unit in stock {
            guard let fixture = fixtures.first(where: { $0.id == unit.fixtureID }),
                  (0..<FixtureCatalog.definition(for: fixture.kind).stockCapacity).contains(unit.slotIndex),
                  unit.purchaseCost >= 0,
                  ProductCatalog.definition(for: unit.product).isCompatible(with: fixture.kind),
                  slots.insert(StockSlot(fixtureID: unit.fixtureID, index: unit.slotIndex)).inserted else {
                throw invalid("Invalid stock reference, slot or compatibility")
            }
        }

        var dayIDs = Set<UUID>()
        var soldIDs = Set<UUID>()
        for (index, summary) in dayHistory.enumerated() {
            guard summary.dayNumber == index + 1,
                  dayIDs.insert(summary.id).inserted,
                  summary.outcomes.count == ShopDayState.visitorCount else {
                throw invalid("Invalid day history")
            }
            try validateOutcomes(summary.outcomes, dayID: summary.id,
                                 dayNumber: summary.dayNumber, soldIDs: &soldIDs)
        }
        switch phase {
        case .preparing:
            guard currentDay == nil else { throw invalid("Preparing with an active day") }
        case .open, .summary:
            guard onboardingCompleted,
                  let day = currentDay,
                  day.dayNumber == dayHistory.count + 1,
                  dayIDs.insert(day.id).inserted,
                  day.openingBalance >= 0,
                  (0...ShopDayState.visitorCount).contains(day.nextVisitIndex),
                  day.nextVisitIndex == day.outcomes.count,
                  (phase == .summary) == day.isFinished else {
                throw invalid("Inconsistent active day or phase")
            }
            try validateOutcomes(day.outcomes, dayID: day.id,
                                 dayNumber: day.dayNumber, soldIDs: &soldIDs)
            let expectedBalance = day.openingBalance.addingReportingOverflow(day.revenue)
            guard !expectedBalance.overflow, balance == expectedBalance.partialValue else {
                throw invalid("Day income does not match balance")
            }
        }
        guard soldIDs.isDisjoint(with: Set(stock.map(\.id))) else {
            throw invalid("Sold stock is still on display")
        }
        for group in restoration.repairedGroups {
            let blocker = RepairCatalog.definition(for: group).blocker
            guard !world.hitMap.cells.contains(where: { $0.staticBlocker == blocker }) else {
                throw invalid("Repaired group still blocks cells")
            }
        }
        if let expansion = restoration.expansion {
            guard restoration.repairedGroups.count == RestorationGroupID.allCases.count,
                  layout == expansion.layout else { throw invalid("Invalid expansion") }
            let shift = expansion.starterOrigin
            let room = expansion.roomOrigin
            for cell in world.hitMap.cells {
                let p = cell.point
                let inStarter = p.x >= shift.x && p.x < shift.x + 11 && p.y >= 0 && p.y < 11
                let inRoom = p.x >= room.x && p.x < room.x + 5 &&
                    p.y >= room.y && p.y < room.y + 5
                guard (cell.zone != .outside) == (inStarter || inRoom) else {
                    throw invalid("Expansion floor shape does not match room")
                }
            }
        }
        if let completion = restoration.completion {
            guard completion.completedOnDay > 0, completion.completedOnDay <= calendar.dayNumber,
                  restoration.repairedGroups.count == RestorationGroupID.allCases.count,
                  restoration.expansion != nil,
                  restorationProgress.successfulTradingDays >= RestorationProgress.requiredTradingDays else {
                throw invalid("Invalid restoration completion")
            }
        }
    }

    private func validateOutcomes(
        _ outcomes: [VisitOutcome],
        dayID: UUID,
        dayNumber: Int,
        soldIDs: inout Set<UUID>
    ) throws {
        guard outcomes.count <= ShopDayState.visitorCount else {
            throw invalid("Too many visitor outcomes")
        }
        let expected = ShopDayState(id: dayID, dayNumber: dayNumber, openingBalance: 0).visitors
        var revenue = 0
        var costOfGoods = 0
        for (index, outcome) in outcomes.enumerated() {
            guard outcome.visitID == expected[index].id,
                  outcome.requestedProduct == expected[index].requestedProduct else {
                throw invalid("Visitor journal is out of order")
            }
            if let sale = outcome.sale {
                guard sale.product == outcome.requestedProduct,
                      sale.revenue >= 0, sale.costOfGoods >= 0,
                      sale.slotIndex >= 0,
                      sale.slotIndex < FixtureCatalog.simpleShelf.stockCapacity,
                      soldIDs.insert(sale.stockID).inserted else {
                    throw invalid("Invalid or repeated sale")
                }
                let nextRevenue = revenue.addingReportingOverflow(sale.revenue)
                let nextCost = costOfGoods.addingReportingOverflow(sale.costOfGoods)
                guard !nextRevenue.overflow, !nextCost.overflow else {
                    throw invalid("Sale totals overflow")
                }
                revenue = nextRevenue.partialValue
                costOfGoods = nextCost.partialValue
            }
        }
    }

    private func invalid(_ message: String) -> GameStateValidationError {
        .invalidState(message)
    }

    private struct StockSlot: Hashable {
        let fixtureID: UUID
        let index: Int
    }
}
