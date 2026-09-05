import Foundation

public enum FirstSliceRoute: Equatable, Sendable {
    case onboarding
    case shop
    case buildCatalog
    case placement(PlacementDraft)
}

/// Platform-neutral presentation flow. SwiftUI renders this state, while all
/// economy and placement decisions continue to be owned by `GameEngine`.
public struct FirstSliceFlow: Equatable, Sendable {
    public private(set) var route: FirstSliceRoute

    public init(state: GameState) {
        route = state.onboardingCompleted ? .shop : .onboarding
    }

    public mutating func didCompleteOnboarding() {
        route = .shop
    }

    public mutating func openBuild() {
        route = .buildCatalog
    }

    public mutating func closeBuild() {
        route = .shop
    }

    public mutating func beginPlacement(_ draft: PlacementDraft) {
        route = .placement(draft)
    }

    public mutating func updatePlacement(_ draft: PlacementDraft) {
        guard case .placement = route else { return }
        route = .placement(draft)
    }

    public mutating func cancelPlacement() {
        route = .buildCatalog
    }

    public mutating func finishPlacement() {
        route = .shop
    }
}

public struct GameEngine: Sendable {
    public private(set) var state: GameState
    public var layout: ShopLayout { state.world.hitMap.layout }

    public init(state: GameState = .initial, layout: ShopLayout = .starter) {
        self.state = state
        _ = layout // Persisted world geometry is authoritative, including expansion.
    }

    @discardableResult
    public mutating func completeOnboarding(shopName rawName: String) throws -> String {
        try requirePreparing()
        let normalizedName = try ShopNameValidator.normalized(rawName)
        state.shopName = normalizedName
        state.onboardingCompleted = true
        return normalizedName
    }

    public func makePlacementDraft(
        kind: FixtureKind,
        origin: GridPoint,
        rotation: FixtureRotation = .north,
        fixtureID: UUID = UUID()
    ) -> PlacementDraft {
        PlacementDraft(
            fixtureID: fixtureID,
            kind: kind,
            origin: origin,
            rotation: rotation
        )
    }

    public func validate(_ draft: PlacementDraft) throws {
        try state.validateIntegrity()
        try PlacementRules.validate(draft, in: state, layout: layout)
    }

    @discardableResult
    public mutating func confirm(_ draft: PlacementDraft) throws -> PlacedFixture {
        try validate(draft)

        let definition = FixtureCatalog.definition(for: draft.kind)
        let fixture = PlacedFixture(
            id: draft.fixtureID,
            kind: draft.kind,
            origin: draft.origin,
            rotation: draft.rotation
        )

        state.balance -= definition.price
        state.fixtures.append(fixture)
        refreshRestorationCompletion()
        return fixture
    }

    public mutating func cancel(_ draft: PlacementDraft) {
        // Drafts are intentionally transient. Cancelling cannot alter money or state.
        _ = draft
    }
}

extension GameEngine {
    public func makeStockDraft(
        product: ProductKind, fixtureID: UUID, slotIndex: Int, stockID: UUID = UUID()
    ) -> StockDraft {
        StockDraft(stockID: stockID, product: product, fixtureID: fixtureID, slotIndex: slotIndex)
    }

    public func validate(_ draft: StockDraft) throws {
        try requireStockManagement()
        guard !state.stock.contains(where: { $0.id == draft.stockID }),
              !soldStockIDs.contains(draft.stockID) else {
            throw CommerceError.duplicateStockID(draft.stockID)
        }
        guard let fixture = state.fixtures.first(where: { $0.id == draft.fixtureID }) else {
            throw CommerceError.fixtureNotFound(draft.fixtureID)
        }
        guard (0..<FixtureCatalog.definition(for: fixture.kind).stockCapacity).contains(draft.slotIndex) else {
            throw CommerceError.invalidSlot
        }
        guard !state.stock.contains(where: {
            $0.fixtureID == draft.fixtureID && $0.slotIndex == draft.slotIndex
        }) else { throw CommerceError.slotOccupied }
        let product = ProductCatalog.definition(for: draft.product)
        guard product.isCompatible(with: fixture.kind) else { throw CommerceError.incompatibleProduct }
        guard state.balance >= product.purchasePrice else {
            throw CommerceError.insufficientFunds(required: product.purchasePrice, available: state.balance)
        }
    }

    @discardableResult
    public mutating func confirm(_ draft: StockDraft) throws -> StockItem {
        try validate(draft)
        let unit = StockItem(id: draft.stockID, product: draft.product,
                             fixtureID: draft.fixtureID, slotIndex: draft.slotIndex)
        let cost = ProductCatalog.definition(for: draft.product).purchasePrice
        var living = state.livingDay
        try living?.recordInventoryCashFlow(-cost)
        state.balance -= cost
        state.stock.append(unit)
        state.livingDay = living
        return unit
    }

    public mutating func cancel(_ draft: StockDraft) {
        _ = draft
    }

    @discardableResult
    public mutating func returnStock(stockID: UUID) throws -> Int {
        try requireStockManagement()
        guard let index = state.stock.firstIndex(where: { $0.id == stockID }) else {
            throw CommerceError.stockNotFound(stockID)
        }
        let refund = state.stock[index].purchaseCost
        let updated = try balanceAdding(refund)
        var living = state.livingDay
        try living?.recordInventoryCashFlow(refund)
        state.stock.remove(at: index)
        state.balance = updated
        state.livingDay = living
        return refund
    }

    @discardableResult
    public mutating func sellEmptyFixture(fixtureID: UUID) throws -> Int {
        try requirePreparing()
        guard let index = state.fixtures.firstIndex(where: { $0.id == fixtureID }) else {
            throw CommerceError.fixtureNotFound(fixtureID)
        }
        guard !state.stock.contains(where: { $0.fixtureID == fixtureID }) else {
            throw CommerceError.fixtureContainsStock
        }
        let refund = FixtureCatalog.definition(for: state.fixtures[index].kind).price
        let updated = try balanceAdding(refund)
        state.fixtures.remove(at: index)
        state.balance = updated
        return refund
    }

    @discardableResult
    public mutating func moveFixture(
        fixtureID: UUID, origin: GridPoint, rotation: FixtureRotation? = nil
    ) throws -> PlacedFixture {
        try requirePreparing()
        guard let index = state.fixtures.firstIndex(where: { $0.id == fixtureID }) else {
            throw CommerceError.fixtureNotFound(fixtureID)
        }
        let current = state.fixtures[index]
        let selectedRotation = rotation ?? current.rotation
        let draft = PlacementDraft(fixtureID: fixtureID, kind: current.kind,
                                   origin: origin, rotation: selectedRotation)
        try PlacementRules.validateLocation(draft, in: state, layout: layout,
                                            ignoringFixtureID: fixtureID)
        state.fixtures[index].origin = origin
        state.fixtures[index].rotation = selectedRotation
        return state.fixtures[index]
    }

    @discardableResult
    public mutating func openDay(dayID: UUID = UUID()) throws -> ShopDayState {
        try requirePreparing()
        guard state.onboardingCompleted else { throw CommerceError.onboardingRequired }
        guard !state.dayHistory.contains(where: { $0.id == dayID }) else {
            throw CommerceError.duplicateDayID(dayID)
        }
        guard state.stock.contains(where: { unit in
            guard let fixture = state.fixtures.first(where: { $0.id == unit.fixtureID }) else { return false }
            return ShopAccess.isReachable(fixture, in: state)
        }) else { throw CommerceError.noReachableStock }

        let day = ShopDayState(id: dayID, dayNumber: state.completedDays + 1,
                               openingBalance: state.balance)
        state.currentDay = day
        state.phase = .open
        return day
    }

    /// One deterministic visitor per successful transaction. The caller should
    /// atomically save the whole candidate state before displaying this result.
    @discardableResult
    public mutating func advanceDay(expectedVisitID: VisitID) throws -> VisitOutcome {
        try state.validateIntegrity()
        try requirePhase(.open)
        guard var day = state.currentDay,
              let visitor = day.nextVisit, visitor.id == expectedVisitID else {
            throw CommerceError.unexpectedVisit
        }
        let stockIndex = state.stock.firstIndex { unit in
            guard unit.product == visitor.requestedProduct,
                  let fixture = state.fixtures.first(where: { $0.id == unit.fixtureID }) else {
                return false
            }
            return ShopAccess.isReachable(fixture, in: state)
        }
        var sale: SaleReceipt?
        var newBalance = state.balance
        if let index = stockIndex {
            let unit = state.stock[index]
            let revenue = ProductCatalog.definition(for: unit.product).salePrice
            newBalance = try balanceAdding(revenue)
            guard !day.costOfGoods.addingReportingOverflow(unit.purchaseCost).overflow else {
                throw CommerceError.totalOverflow
            }
            sale = SaleReceipt(stockID: unit.id, product: unit.product,
                               fixtureID: unit.fixtureID, slotIndex: unit.slotIndex,
                               revenue: revenue, costOfGoods: unit.purchaseCost)
        }
        let outcome = VisitOutcome(visitID: visitor.id,
                                   requestedProduct: visitor.requestedProduct, sale: sale)
        day.record(outcome)
        // All throwing checks are complete before any part of state changes.
        if let index = stockIndex { state.stock.remove(at: index) }
        state.balance = newBalance
        state.currentDay = day
        state.phase = day.isFinished ? .summary : .open
        return outcome
    }

    @discardableResult
    public mutating func acknowledgeDaySummary(dayID: UUID) throws -> DaySummary {
        try state.validateIntegrity()
        try requirePhase(.summary)
        guard let day = state.currentDay, day.id == dayID,
              let summary = day.summary else { throw CommerceError.unexpectedDay }
        state.dayHistory.append(summary)
        state.currentDay = nil
        state.phase = .preparing
        refreshRestorationCompletion()
        return summary
    }

    private func requirePreparing() throws {
        try state.validateIntegrity()
        try requirePhase(.preparing)
    }

    private func requirePhase(_ expected: ShopPhase) throws {
        guard state.phase == expected else {
            throw CommerceError.wrongPhase(required: expected, actual: state.phase)
        }
    }

    private var soldStockIDs: Set<UUID> {
        let history = state.dayHistory.flatMap { $0.sales.map(\.stockID) }
        let active = state.currentDay?.sales.map(\.stockID) ?? []
        let living = state.livingDay?.sales.map(\.stockID) ?? []
        return Set(history + active + living)
    }

    private func balanceAdding(_ amount: Int) throws -> Int {
        let result = state.balance.addingReportingOverflow(amount)
        guard !result.overflow else { throw CommerceError.balanceOverflow }
        return result.partialValue
    }
}

extension GameEngine {
    public func validateRepair(_ group: RestorationGroupID) throws {
        try requirePreparing()
        guard !state.restoration.repairedGroups.contains(group) else {
            throw RestorationError.repairAlreadyCompleted(group)
        }
        let definition = RepairCatalog.definition(for: group)
        guard state.world.hitMap.cells.contains(where: { $0.staticBlocker == definition.blocker }) else {
            throw RestorationError.noRepairableCells(group)
        }
        guard state.balance >= definition.price else {
            throw CommerceError.insufficientFunds(required: definition.price, available: state.balance)
        }
    }

    /// Call only on confirmation. The whole authored blocker group is cleared,
    /// including a legacy cell preserved during calibration migration.
    @discardableResult
    public mutating func repair(_ group: RestorationGroupID) throws -> RepairDefinition {
        try validateRepair(group)
        let definition = RepairCatalog.definition(for: group)
        var candidate = state
        let cells = candidate.world.hitMap.cells.filter { $0.staticBlocker == definition.blocker }
        for cell in cells {
            candidate.world.hitMap.updateCell(at: cell.point) { $0.staticBlocker = nil }
        }
        candidate.balance -= definition.price
        candidate.restoration.repairedGroups.insert(group)
        candidate.manualRepairProgress.removeValue(forKey: group)
        try candidate.validateIntegrity()
        state = candidate
        refreshRestorationCompletion()
        return definition
    }

    public func validateExpansion(toward direction: ExpansionDirection) throws {
        try requirePreparing()
        guard state.restoration.expansion == nil else { throw RestorationError.alreadyExpanded }
        guard state.restoration.repairedGroups.count == RestorationGroupID.allCases.count else {
            throw RestorationError.repairsRequired
        }
        guard state.world.hitMap.layout == .starter else {
            throw RestorationError.unsupportedStarterLayout
        }
        guard state.balance >= ExpansionState.price else {
            throw CommerceError.insufficientFunds(required: ExpansionState.price, available: state.balance)
        }
        let connection = ExpansionState(direction: direction).starterConnectionCells
        let occupied = state.world.hitMap.dynamicOccupancy(fixtures: state.fixtures)
        guard connection.allSatisfy({ occupied[$0] == nil }),
              !connection.isDisjoint(with: ShopAccess.reachableCells(in: state)) else {
            throw RestorationError.expansionConnectionBlocked
        }
    }

    @discardableResult
    public mutating func expandShop(toward direction: ExpansionDirection) throws -> ExpansionState {
        try validateExpansion(toward: direction)
        let expansion = ExpansionState(direction: direction)
        var candidate = state
        candidate.world = RestorationWorld.expanded(state.world, using: expansion)
        if expansion.starterOrigin.x != 0 {
            for index in candidate.fixtures.indices {
                candidate.fixtures[index].origin.x += expansion.starterOrigin.x
            }
            candidate.dirt = Dictionary(uniqueKeysWithValues: candidate.dirt.map {
                (GridPoint(x: $0.key.x + expansion.starterOrigin.x, y: $0.key.y), $0.value)
            })
        }
        candidate.restoration.expansion = expansion
        candidate.balance -= ExpansionState.price
        try candidate.validateIntegrity()
        state = candidate
        refreshRestorationCompletion()
        return expansion
    }

    private mutating func refreshRestorationCompletion() {
        guard state.restoration.completion == nil, state.restorationProgress.isComplete else { return }
        state.restoration.completion = RestorationCompletion(completedOnDay: state.calendar.dayNumber)
    }
}

extension GameEngine {
    public func pricingQuote(for product: ProductKind, price: Int? = nil) -> PricingQuote {
        ShopPricing.quote(for: product, price: price ?? state.price(for: product))
    }

    public mutating func setPrice(_ price: Int, for product: ProductKind) throws {
        try requireStockManagement()
        let quote = pricingQuote(for: product, price: price)
        guard (quote.minimumPrice...quote.maximumPrice).contains(price) else {
            throw LivingShopError.invalidPrice(minimum: quote.minimumPrice, maximum: quote.maximumPrice)
        }
        state.pricing[product] = price
    }

    @discardableResult
    public mutating func paintFloor(at point: GridPoint, style: FloorStyleID) throws -> Int {
        try requirePreparing()
        guard let cost = ShopCare.paintCost(for: style) else { throw LivingShopError.invalidFloorStyle }
        guard let cell = state.world.hitMap.cell(at: point), cell.zone != .outside,
              cell.staticBlocker == nil else { throw LivingShopError.invalidCareCell }
        if state.world.floor.styleID(at: point) == style { return 0 }
        guard state.balance >= cost else {
            throw CommerceError.insufficientFunds(required: cost, available: state.balance)
        }
        // A permanent cosmetic purchase may not consume the last recoverable
        // table-and-potion capital. Stock and fixtures can still be returned.
        let required = cost + 60
        var capital = min(required, state.balance)
        for fixture in state.fixtures where capital < required {
            capital += min(required - capital, FixtureCatalog.definition(for: fixture.kind).price)
        }
        for unit in state.stock where capital < required {
            capital += min(required - capital, unit.purchaseCost)
        }
        guard capital >= required else { throw LivingShopError.workingCapitalRequired }
        state.world.floor.setStyleID(style, at: point)
        state.balance -= cost
        return cost
    }

    @discardableResult
    public mutating func cleanCell(at point: GridPoint) throws -> CleaningResult {
        try requireStockManagement()
        guard let cell = state.world.hitMap.cell(at: point), cell.zone != .outside else {
            throw LivingShopError.invalidCareCell
        }
        let repair = RepairCatalog.all.first { $0.blocker == cell.staticBlocker }
        if cell.staticBlocker != nil && repair == nil { throw LivingShopError.invalidCareCell }
        var candidate = state
        let removed = candidate.dirt[point] == nil ? 0 : 1
        if let level = candidate.dirt[point] {
            if level <= 1 { candidate.dirt.removeValue(forKey: point) }
            else { candidate.dirt[point] = level - 1 }
        }
        var progress = 0
        var completed = false
        if let repair {
            progress = candidate.repairProgress(for: repair.id) + 1
            completed = progress >= ShopCare.repairStrokesRequired
            if completed {
                for blocked in candidate.world.hitMap.cells.filter({ $0.staticBlocker == repair.blocker }) {
                    candidate.world.hitMap.updateCell(at: blocked.point) { $0.staticBlocker = nil }
                }
                candidate.restoration.repairedGroups.insert(repair.id)
                candidate.manualRepairProgress.removeValue(forKey: repair.id)
            } else { candidate.manualRepairProgress[repair.id] = progress }
        }
        try candidate.validateIntegrity()
        state = candidate
        refreshRestorationCompletion()
        return CleaningResult(point: point, removedDirt: removed, repairGroup: repair?.id,
                              repairProgress: progress, completedRepair: completed)
    }

    @discardableResult
    public mutating func openLivingDay(dayID: UUID = UUID(), seed: UInt64? = nil) throws -> LivingShopDay {
        try requirePreparing()
        guard state.onboardingCompleted else { throw CommerceError.onboardingRequired }
        guard !state.dayHistory.contains(where: { $0.id == dayID }) else { throw CommerceError.duplicateDayID(dayID) }
        guard state.stock.contains(where: { item in
            state.fixtures.contains { $0.id == item.fixtureID && ShopAccess.isReachable($0, in: state) }
        }) else { throw CommerceError.noReachableStock }
        let number = state.completedDays + 1
        let day = try LivingShopDay(id: dayID, dayNumber: number,
            seed: seed ?? LivingShopDay.defaultSeed(dayNumber: number), state: state)
        var candidate = state
        candidate.livingDay = day
        candidate.phase = .open
        try candidate.validateIntegrity()
        state = candidate
        return day
    }

    @discardableResult
    public mutating func advanceLivingDay(expectedDayID: UUID, expectedMinute: Int,
                                         toMinute: Int) throws -> LivingDayAdvance {
        try state.validateIntegrity()
        try requirePhase(.open)
        guard var day = state.livingDay, day.id == expectedDayID else { throw CommerceError.unexpectedDay }
        guard day.minute == expectedMinute else { throw LivingShopError.unexpectedMinute }
        guard toMinute > expectedMinute, toMinute <= ShopCalendar.closingMinute else {
            throw LivingShopError.invalidMinuteRange
        }
        var candidate = state
        var outcomes: [VisitOutcome] = []
        for minute in (expectedMinute + 1)...toMinute {
            // Stable visitor-index order arbitrates simultaneous demand for the
            // same physical unit; the second visitor sees the updated stock.
            for index in day.visitors.indices {
                let visitor = day.visitors[index]
                if visitor.arrivalMinute <= minute && minute < visitor.departureMinute,
                   minute % 15 == (index * 3) % 15 {
                    candidate.addFootfallDirt(at: visitor.position(at: Double(minute)).from)
                }
                guard minute == visitor.decisionMinute else { continue }
                let unit = Self.chooseLivingStock(for: visitor, in: candidate)
                var sale: SaleReceipt?
                if let unit {
                    let revenue = candidate.price(for: unit.product)
                    let newBalance = candidate.balance.addingReportingOverflow(revenue)
                    let newCost = day.costOfGoods.addingReportingOverflow(unit.purchaseCost)
                    guard !newBalance.overflow else { throw CommerceError.balanceOverflow }
                    guard !newCost.overflow else { throw CommerceError.totalOverflow }
                    sale = SaleReceipt(stockID: unit.id, product: unit.product, fixtureID: unit.fixtureID,
                                       slotIndex: unit.slotIndex, revenue: revenue, costOfGoods: unit.purchaseCost)
                    candidate.stock.removeAll { $0.id == unit.id }
                    candidate.balance = newBalance.partialValue
                }
                let outcome = VisitOutcome(visitID: visitor.id, requestedProduct: visitor.preferredProduct, sale: sale)
                day.record(outcome, visitorIndex: index)
                outcomes.append(outcome)
            }
        }
        day.setMinute(toMinute)
        candidate.livingDay = day
        candidate.phase = day.isFinished ? .summary : .open
        try candidate.validateIntegrity()
        state = candidate
        return LivingDayAdvance(fromMinute: expectedMinute, toMinute: toMinute,
                                outcomes: outcomes, isFinished: day.isFinished)
    }

    @discardableResult
    public mutating func acknowledgeLivingDaySummary(dayID: UUID) throws -> DaySummary {
        try state.validateIntegrity()
        try requirePhase(.summary)
        guard let day = state.livingDay, day.id == dayID, let summary = day.summary else {
            throw CommerceError.unexpectedDay
        }
        state.dayHistory.append(summary)
        state.livingDay = nil
        state.phase = .preparing
        refreshRestorationCompletion()
        return summary
    }

    private func requireStockManagement() throws {
        try state.validateIntegrity()
        guard state.canManageStock else {
            throw CommerceError.wrongPhase(required: .preparing, actual: state.phase)
        }
    }

    private static func chooseLivingStock(for visitor: LivingVisitor, in state: GameState) -> StockItem? {
        guard visitor.hasBuyingIntent else { return nil }
        let viewed = Set(visitor.stops.map(\.fixtureID))
        return state.stock.filter { unit in
            let price = state.price(for: unit.product)
            let appeal = ShopPricing.quote(for: unit.product, price: price).estimatedDemandPercent
            let interested = unit.product == visitor.preferredProduct || unit.product == visitor.secondaryProduct
            let secondaryPenalty = unit.product == visitor.preferredProduct ? 0 : 15
            guard interested, viewed.contains(unit.fixtureID), price <= visitor.budget,
                  visitor.interestRoll < max(0, appeal - secondaryPenalty),
                  let fixture = state.fixtures.first(where: { $0.id == unit.fixtureID }) else { return false }
            return ShopAccess.isReachable(fixture, in: state)
        }.sorted { left, right in
            func score(_ unit: StockItem) -> Int {
                state.price(for: unit.product) * 100 / ProductCatalog.definition(for: unit.product).salePrice -
                    (unit.product == visitor.preferredProduct ? 15 : 0)
            }
            if score(left) != score(right) { return score(left) < score(right) }
            if left.fixtureID != right.fixtureID { return left.fixtureID.uuidString < right.fixtureID.uuidString }
            if left.slotIndex != right.slotIndex { return left.slotIndex < right.slotIndex }
            return left.id.uuidString < right.id.uuidString
        }.first
    }
}
