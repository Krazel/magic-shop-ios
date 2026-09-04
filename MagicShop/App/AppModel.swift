import Foundation
import SwiftUI

enum ShopPanel: String { case none, stock, improvements, journal, fixture }

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var flow: FirstSliceFlow
    @Published var shopNameInput = ""
    @Published private(set) var selectedCategory: FixtureCategory = .tables
    @Published private(set) var inlineMessage: String?
    @Published var panel: ShopPanel = .none
    @Published var selectedFixtureID: UUID?
    @Published var selectedSlot = 0
    @Published var selectedProduct: ProductKind = .glowPotion
    @Published private(set) var activeVisit: CustomerVisit?
    @Published private(set) var visitProgress = 0.0
    @Published private(set) var lastOutcome: VisitOutcome?
    @Published private(set) var isPaused = false
    @Published var isFast = false
    @Published private(set) var isAppActive = true
    @Published private(set) var movingFixtureID: UUID?
    private var visitWasCommitted = false
    private var session: GameSession?
    private let providedStore: (any GameStateStore)?
    private var engine: GameEngine { session?.engine ?? GameEngine() }

    init(store: (any GameStateStore)? = nil) {
        providedStore = store
        state = .initial
        flow = FirstSliceFlow(state: .initial)
        _ = restoreSavedSession()
    }

    @discardableResult
    private func restoreSavedSession() -> Bool {
        do {
            let store = try providedStore ?? FileGameStateStore.applicationSupport()
            let restored = try GameSession(store: store)
            session = restored
            state = restored.engine.state
            flow = FirstSliceFlow(state: state)
            shopNameInput = state.shopName ?? ""
            inlineMessage = nil
            return true
        } catch {
            session = nil
            inlineMessage = "Your saved shop could not be opened. It has not been changed. Tap Open the Door to retry."
            return false
        }
    }

    @discardableResult
    private func transact(_ command: (inout GameEngine) throws -> Void) -> Bool {
        guard let session else { return false }
        do {
            try session.commit(command)
            state = session.engine.state
            inlineMessage = nil
            return true
        } catch {
            inlineMessage = userFacingMessage(for: error)
            return false
        }
    }

    var placementDraft: PlacementDraft? {
        guard case let .placement(draft) = flow.route else { return nil }
        return draft
    }
    var placementDefinition: FixtureDefinition? { placementDraft.map { FixtureCatalog.definition(for: $0.kind) } }
    var isPlacementValid: Bool { placementDraft != nil && placementFailure == nil && session != nil }
    var placementMessage: String? { placementDraft == nil ? nil : placementFailure ?? "Ready to place" }
    private var placementFailure: String? {
        guard let draft = placementDraft else { return nil }
        do {
            if let id = movingFixtureID {
                var copy = engine
                try copy.moveFixture(fixtureID: id, origin: draft.origin, rotation: draft.rotation)
            } else { try engine.validate(draft) }
            return nil
        } catch { return userFacingMessage(for: error) }
    }
    var selectedFixture: PlacedFixture? { state.fixtures.first { $0.id == selectedFixtureID } }
    var selectedFixtureDefinition: FixtureDefinition? { selectedFixture.map { FixtureCatalog.definition(for: $0.kind) } }
    var stockFixtures: [PlacedFixture] { state.fixtures.filter { FixtureCatalog.definition(for: $0.kind).stockCapacity > 0 } }
    var selectedStock: StockItem? { state.stock.first { $0.fixtureID == selectedFixtureID && $0.slotIndex == selectedSlot } }
    var stockDraft: StockDraft? {
        guard let fixture = selectedFixture else { return nil }
        return engine.makeStockDraft(product: selectedProduct, fixtureID: fixture.id, slotIndex: selectedSlot)
    }
    var stockFailure: String? {
        guard let draft = stockDraft else { return "Build a table or shelf to display your first item." }
        do { try engine.validate(draft); return nil }
        catch { return userFacingMessage(for: error) }
    }
    var canOpen: Bool {
        state.phase == .preparing && state.stock.contains { item in
            state.fixtures.contains { $0.id == item.fixtureID && ShopAccess.isReachable($0, in: state) }
        }
    }
    var isTrading: Bool { state.phase == .open || activeVisit != nil }
    var showsSummary: Bool { state.phase == .summary && activeVisit == nil }
    var clockText: String {
        guard let visit = activeVisit else { return state.calendar.timeText }
        let minutes = min(18 * 60, 9 * 60 + visit.id.index * 90 + Int(visitProgress * 90))
        return String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
    var visitorText: String {
        guard let visit = activeVisit else { return isPaused ? "Paused" : "Welcoming your next visitor" }
        if visitWasCommitted, let outcome = lastOutcome {
            return outcome.sale.map { "+$\($0.revenue) · Thank you!" } ?? "Nothing today. Maybe tomorrow!"
        }
        return "Looking for \(ProductCatalog.definition(for: visit.requestedProduct).displayName)"
    }

    @discardableResult
    func submitOnboarding() -> Bool {
        guard session != nil else { _ = restoreSavedSession(); return false }
        if transact({ _ = try $0.completeOnboarding(shopName: shopNameInput) }) {
            flow.didCompleteOnboarding(); return true
        }
        return false
    }
    func openBuild() {
        guard state.phase == .preparing, session != nil else { return }
        panel = .none; movingFixtureID = nil; flow.openBuild(); inlineMessage = nil
    }
    func closeBuild() { flow.closeBuild(); panel = .none; movingFixtureID = nil; inlineMessage = nil }
    func selectCategory(_ category: FixtureCategory) {
        selectedCategory = category
        inlineMessage = nil
        if category == .walls { flow.closeBuild(); panel = .improvements }
    }
    func showPanel(_ next: ShopPanel) {
        guard state.phase == .preparing else { return }
        flow.closeBuild(); movingFixtureID = nil; panel = next; inlineMessage = nil
        if next == .stock {
            if (selectedFixtureDefinition?.stockCapacity ?? 0) == 0 { selectedFixtureID = stockFixtures.first?.id }
            chooseFixture(selectedFixtureID)
        }
    }
    func chooseFixture(_ id: UUID?) {
        selectedFixtureID = id
        selectedSlot = (0..<(selectedFixtureDefinition?.stockCapacity ?? 0)).first { slot in
            !state.stock.contains { $0.fixtureID == id && $0.slotIndex == slot }
        } ?? 0
        if let kind = selectedFixture?.kind,
           !ProductCatalog.definition(for: selectedProduct).isCompatible(with: kind) { selectedProduct = .glowPotion }
        inlineMessage = nil
    }
    func selectFixture(_ id: UUID) {
        guard state.phase == .preparing, placementDraft == nil else { return }
        chooseFixture(id)
        flow.closeBuild()
        panel = (selectedFixtureDefinition?.stockCapacity ?? 0) > 0 ? .stock : .fixture
    }
    func beginPlacement(kind: FixtureKind) {
        guard state.phase == .preparing, session != nil else { return }
        panel = .none; movingFixtureID = nil
        let preferred = GridPoint(x: 5, y: kind == .simpleShelf ? 10 : 4)
        var draft = engine.makePlacementDraft(kind: kind, origin: preferred)
        if (try? engine.validate(draft)) == nil {
            outer: for y in 0..<engine.layout.depth {
                for x in 0..<engine.layout.width {
                    let candidate = engine.makePlacementDraft(kind: kind, origin: GridPoint(x: x, y: y))
                    if (try? engine.validate(candidate)) != nil { draft = candidate; break outer }
                }
            }
        }
        flow.beginPlacement(draft); inlineMessage = nil
    }
    func beginMovingSelectedFixture() {
        guard let fixture = selectedFixture, state.phase == .preparing else { return }
        movingFixtureID = fixture.id; panel = .none
        flow.beginPlacement(PlacementDraft(fixtureID: fixture.id, kind: fixture.kind, origin: fixture.origin, rotation: fixture.rotation))
    }
    func setPlacementOrigin(_ point: GridPoint) { updateDraft { $0.origin = point } }
    func movePlacement(deltaX: Int, deltaY: Int) {
        updateDraft { $0.origin = GridPoint(x: $0.origin.x + deltaX, y: $0.origin.y + deltaY) }
    }
    func rotatePlacement() {
        updateDraft { draft in
            let rotations = FixtureRotation.allCases
            let index = rotations.firstIndex(of: draft.rotation) ?? 0
            draft.rotation = rotations[(index + 1) % rotations.count]
        }
    }
    private func updateDraft(_ mutation: (inout PlacementDraft) -> Void) {
        guard var draft = placementDraft else { return }
        mutation(&draft)
        let footprint = FixtureCatalog.definition(for: draft.kind).footprint.rotated(draft.rotation)
        draft.origin = GridPoint(x: min(max(0, draft.origin.x), engine.layout.width - footprint.width),
                                 y: min(max(0, draft.origin.y), engine.layout.depth - footprint.depth))
        flow.updatePlacement(draft); inlineMessage = nil
    }
    func cancelCurrentPlacement() {
        if movingFixtureID != nil { flow.closeBuild(); panel = .fixture }
        else { flow.cancelPlacement() }
        movingFixtureID = nil; inlineMessage = nil
    }
    @discardableResult
    func confirmCurrentPlacement() -> Bool {
        guard let draft = placementDraft else { return false }
        let moveID = movingFixtureID
        if transact({ engine in
            if let id = moveID { try engine.moveFixture(fixtureID: id, origin: draft.origin, rotation: draft.rotation) }
            else { _ = try engine.confirm(draft) }
        }) {
            selectedFixtureID = draft.fixtureID
            flow.finishPlacement(); movingFixtureID = nil; return true
        }
        return false
    }
    @discardableResult
    func confirmStock() -> Bool {
        guard let draft = stockDraft else { return false }
        if transact({ _ = try $0.confirm(draft) }) { chooseFixture(selectedFixtureID); return true }
        return false
    }
    func returnSelectedStock() {
        guard let item = selectedStock else { return }
        _ = transact { _ = try $0.returnStock(stockID: item.id) }
    }
    func sellSelectedFixture() {
        guard let id = selectedFixtureID else { return }
        if transact({ _ = try $0.sellEmptyFixture(fixtureID: id) }) {
            selectedFixtureID = nil; panel = .none
        }
    }
    func startDay() {
        guard state.phase == .preparing else { return }
        if transact({ _ = try $0.openDay() }) {
            panel = .none; flow.closeBuild(); isPaused = false
            startNextVisit()
        }
    }
    private func startNextVisit() {
        activeVisit = state.currentDay?.nextVisit
        visitProgress = 0; visitWasCommitted = false; lastOutcome = nil
    }
    // Presentation time only. Financial state advances once at the sale moment,
    // through an atomic save. A retry retains the original visitor token.
    func tick(seconds: Double) {
        guard isAppActive, !isPaused, seconds > 0 else { return }
        if activeVisit == nil, state.phase == .open { startNextVisit() }
        guard let visit = activeVisit else { return }
        visitProgress = min(1, visitProgress + min(seconds, 0.25) / (isFast ? 3.0 : 6.0))
        if visitProgress >= 0.65 && !visitWasCommitted {
            var result: VisitOutcome?
            guard transact({ result = try $0.advanceDay(expectedVisitID: visit.id) }) else {
                visitProgress = 0.64; isPaused = true; return
            }
            lastOutcome = result; visitWasCommitted = true
        }
        if visitProgress >= 1 {
            activeVisit = nil
            if state.phase == .open { startNextVisit() }
        }
    }
    func togglePause() { isPaused.toggle(); if !isPaused { inlineMessage = nil } }
    func setAppActive(_ active: Bool) { isAppActive = active }
    func prepareNextDay() {
        guard let day = state.currentDay, showsSummary else { return }
        if transact({ _ = try $0.acknowledgeDaySummary(dayID: day.id) }) { panel = .none; lastOutcome = nil }
    }

    func repair(_ group: RestorationGroupID) {
        _ = transact { _ = try $0.repair(group) }
    }
    func expand(_ direction: ExpansionDirection) {
        _ = transact { _ = try $0.expandShop(toward: direction) }
    }
    func repairFailure(_ group: RestorationGroupID) -> String? {
        do { try engine.validateRepair(group); return nil }
        catch { return userFacingMessage(for: error) }
    }
    func expansionFailure(_ direction: ExpansionDirection) -> String? {
        do { try engine.validateExpansion(toward: direction); return nil }
        catch { return userFacingMessage(for: error) }
    }
    private func userFacingMessage(for error: Error) -> String {
        switch error {
        case ShopNameValidationError.empty: return "Enter a name for your shop."
        case ShopNameValidationError.tooShort: return "Use at least 2 characters."
        case ShopNameValidationError.tooLong: return "Keep the name to 24 characters or fewer."
        case ShopNameValidationError.containsControlCharacters: return "That name contains unsupported characters."
        case let PlacementError.insufficientFunds(required, available), let CommerceError.insufficientFunds(required, available):
            return "You need $\(required), but have $\(available)."
        case PlacementError.outsideShopBounds: return "Keep the fixture inside the shop."
        case PlacementError.entranceMustRemainClear: return "Keep the entrance clear."
        case PlacementError.blockedByStaticObject: return "Repair this part of the shop before building here."
        case PlacementError.overlapsExistingFixture: return "That space is already occupied."
        case PlacementError.duplicateFixtureID: return "That fixture has already been placed."
        case PlacementError.shopIsNotPreparing, CommerceError.wrongPhase: return "Finish the trading day before changing the shop."
        case PlacementError.shelfMustBeAdjacentToWall: return "Place this fixture along a wall."
        case CommerceError.slotOccupied: return "This slot is full. Return its item or select an empty slot."
        case CommerceError.incompatibleProduct: return "Choose a compatible table or shelf for this item."
        case CommerceError.fixtureContainsStock: return "Return the stock before selling this fixture."
        case CommerceError.noReachableStock: return "Stock a display that customers can reach from the entrance. Move anything blocking the way."
        case RestorationError.repairsRequired: return "Complete all three repairs before adding a room."
        case RestorationError.alreadyExpanded: return "Your new room is already part of the shop."
        case RestorationError.expansionConnectionBlocked: return "Move fixtures away from this wall to open the passage."
        case RestorationError.repairAlreadyCompleted: return "This repair is already complete."
        default: return "The change could not be saved. Please try again."
        }
    }
}