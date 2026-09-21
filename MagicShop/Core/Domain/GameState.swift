import Foundation

public struct GameState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 6
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
    public var livingDay: LivingShopDay?
    public var pricing: [ProductKind: Int]
    public var dirt: [GridPoint: Int]
    public var manualRepairProgress: [RestorationGroupID: Int]

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
        restoration: ShopRestorationState = .initial,
        livingDay: LivingShopDay? = nil,
        pricing: [ProductKind: Int] = ShopPricing.marketPrices,
        dirt: [GridPoint: Int] = [:],
        manualRepairProgress: [RestorationGroupID: Int] = [:]
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
        self.livingDay = livingDay
        self.pricing = pricing
        self.dirt = dirt
        self.manualRepairProgress = manualRepairProgress
    }

    public static var initial: GameState { GameState() }
    public var completedDays: Int { dayHistory.count }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, shopName, onboardingCompleted, balance, fixtures, world
        case stock, phase, currentDay, dayHistory, restoration
        case livingDay, pricing, dirt, manualRepairProgress
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
        if savedVersion >= 5 {
            pricing = try container.decode([ProductKind: Int].self, forKey: .pricing)
            dirt = try container.decode([GridPoint: Int].self, forKey: .dirt)
            manualRepairProgress = try container.decode([RestorationGroupID: Int].self, forKey: .manualRepairProgress)
            livingDay = try container.decodeIfPresent(LivingShopDay.self, forKey: .livingDay)
        } else {
            pricing = ShopPricing.marketPrices
            dirt = [:]
            manualRepairProgress = [:]
            livingDay = nil
        }
        // Validate the source topology/routes before changing any coordinates.
        // Otherwise a migration could hide corrupt walls, holes or itineraries.
        if savedVersion < 6, let expansion = restoration.expansion {
            try validateIntegrity(legacyExpansion: true)
            let oldMap = world.hitMap
            world = RestorationWorld.rectangularized(world, using: expansion, translateStarter: false)
            _ = try RestorationWorld.relocateWallFixtures(in: &self, from: oldMap)
            if let day = livingDay, day.requiresRerouting(in: self) {
                livingDay = try day.rerouted(in: self)
            }
        }
        try validateIntegrity()
    }

    /// Reject malformed state before it can become a writable game session.
    /// Existing legacy furniture is not rejudged against newer debris metadata.
    public func validateIntegrity() throws {
        try validateIntegrity(legacyExpansion: false)
    }

    /// Used only to validate a decoded pre-6 annex before migration.
    func validateIntegrity(legacyExpansion: Bool) throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw GameStateValidationError.unsupportedSchemaVersion(schemaVersion)
        }
        guard balance >= 0 else { throw invalid("Negative balance") }
        guard Set(pricing.keys) == Set(ProductKind.allCases),
              pricing.allSatisfy({ product, price in
                  let definition = ProductCatalog.definition(for: product)
                  return (definition.purchasePrice...(definition.salePrice * 3)).contains(price)
              }) else { throw invalid("Invalid product pricing") }
        guard dirt.count <= ShopCare.maximumDirtCells, dirt.allSatisfy({ point, level in
            guard let cell = world.hitMap.cell(at: point) else { return false }
            return cell.zone != .outside && cell.staticBlocker == nil && (1...3).contains(level)
        }) else { throw invalid("Invalid dirt cells") }
        guard manualRepairProgress.allSatisfy({ group, progress in
            (1..<ShopCare.repairStrokesRequired).contains(progress) &&
            !restoration.repairedGroups.contains(group) &&
            world.hitMap.cells.contains { $0.staticBlocker == RepairCatalog.definition(for: group).blocker }
        }) else { throw invalid("Invalid manual repair progress") }
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
                  summary.outcomes.count == summary.visitorCount,
                  (summary.simulation == .living) == (summary.seed != nil) else {
                throw invalid("Invalid day history")
            }
            try validateOutcomes(summary.outcomes, dayID: summary.id,
                                 dayNumber: summary.dayNumber, soldIDs: &soldIDs,
                                 simulation: summary.simulation)
        }
        switch phase {
        case .preparing:
            guard currentDay == nil, livingDay == nil else { throw invalid("Preparing with an active day") }
        case .open, .summary:
            if let day = livingDay {
                guard currentDay == nil, onboardingCompleted, day.dayNumber == dayHistory.count + 1,
                      dayIDs.insert(day.id).inserted, (phase == .summary) == day.isFinished else {
                    throw invalid("Inconsistent living day or phase")
                }
                try day.validate(in: self, soldIDs: &soldIDs)
                break
            }
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
            let oldRoom: GridPoint
            switch expansion.direction {
            case .left: oldRoom = GridPoint(x: 0, y: 3)
            case .right: oldRoom = GridPoint(x: 11, y: 3)
            case .rear: oldRoom = GridPoint(x: 3, y: 11)
            }
            let interior = Set(world.hitMap.cells.compactMap { cell -> GridPoint? in
                let p = cell.point
                let inStarter = p.x >= shift.x && p.x < shift.x + 11 && p.y < 11
                let inOldRoom = p.x >= oldRoom.x && p.x < oldRoom.x + 5 &&
                    p.y >= oldRoom.y && p.y < oldRoom.y + 5
                return !legacyExpansion || inStarter || inOldRoom ? p : nil
            })
            let entrance = GridPoint(x: 5 + shift.x, y: 0)
            let columns: Set<GridPoint> = legacyExpansion
                ? [GridPoint(x: shift.x, y: 0), GridPoint(x: shift.x + 10, y: 0)]
                : [GridPoint(x: 0, y: 0), GridPoint(x: layout.width - 1, y: 0)]
            for cell in world.hitMap.cells {
                let expectedZone: WorldCellZone = cell.point == entrance ? .entrance :
                    (interior.contains(cell.point) ? .interior : .outside)
                let expectedWalls = interior.contains(cell.point)
                    ? RestorationWorld.wallAdjacency(at: cell.point, interior: interior) : []
                let expectedBlocker: StaticBlockerID? = columns.contains(cell.point) ? .frontColumn : nil
                guard cell.zone == expectedZone, cell.adjacentWalls == expectedWalls,
                      cell.staticBlocker == expectedBlocker else {
                    throw invalid("Expansion topology does not match its saved geometry")
                }
            }
            var occupied = Set<GridPoint>()
            for fixture in fixtures {
                let cells = PlacementRules.occupiedCells(for: fixture)
                guard cells.isDisjoint(with: occupied), cells.allSatisfy({ point in
                    world.hitMap.cell(at: point)?.zone == .interior &&
                    world.hitMap.cell(at: point)?.staticBlocker == nil
                }) else { throw invalid("Invalid expanded furniture occupancy") }
                occupied.formUnion(cells)
                if FixtureCatalog.definition(for: fixture.kind).placementConstraint == .adjacentToWall,
                   world.hitMap.commonWallAdjacency(for: cells).isEmpty {
                    throw invalid("Expanded furniture has no mounting wall")
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
        soldIDs: inout Set<UUID>,
        simulation: DaySimulationKind = .legacy
    ) throws {
        let limit = simulation == .living ? LivingShopDay.visitorCount : ShopDayState.visitorCount
        guard outcomes.count <= limit else {
            throw invalid("Too many visitor outcomes")
        }
        let expected = ShopDayState(id: dayID, dayNumber: dayNumber, openingBalance: 0).visitors
        var revenue = 0
        var costOfGoods = 0
        for (index, outcome) in outcomes.enumerated() {
            guard outcome.visitID == VisitID(dayID: dayID, index: index),
                  simulation == .living || outcome.requestedProduct == expected[index].requestedProduct else {
                throw invalid("Visitor journal is out of order")
            }
            if let sale = outcome.sale {
                guard (simulation == .living || sale.product == outcome.requestedProduct),
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
