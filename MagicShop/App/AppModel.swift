import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var flow: FirstSliceFlow
    @Published var shopNameInput = ""
    @Published private(set) var selectedCategory: FixtureCategory = .tables
    @Published private(set) var inlineMessage: String?

    private var engine: GameEngine
    private let store: any GameStateStore

    init(store: (any GameStateStore)? = nil) {
        let resolvedStore: any GameStateStore
        if let store {
            resolvedStore = store
        } else if let fileStore = try? FileGameStateStore.applicationSupport() {
            resolvedStore = fileStore
        } else {
            resolvedStore = InMemoryGameStateStore()
        }

        self.store = resolvedStore
        let loadedState = (try? resolvedStore.load()) ?? .initial
        self.engine = GameEngine(state: loadedState)
        self.state = loadedState
        self.flow = FirstSliceFlow(state: loadedState)
        self.shopNameInput = loadedState.shopName ?? ""
    }

    var placementDraft: PlacementDraft? {
        guard case let .placement(draft) = flow.route else { return nil }
        return draft
    }

    var placementDefinition: FixtureDefinition? {
        placementDraft.map { FixtureCatalog.definition(for: $0.kind) }
    }

    var isPlacementValid: Bool {
        guard let draft = placementDraft else { return false }
        return (try? engine.validate(draft)) != nil
    }

    var placementMessage: String? {
        guard let draft = placementDraft else { return nil }
        do {
            try engine.validate(draft)
            return "Valid position"
        } catch {
            return userFacingMessage(for: error)
        }
    }

    @discardableResult
    func submitOnboarding() -> Bool {
        do {
            try engine.completeOnboarding(shopName: shopNameInput)
            try persistEngineState()
            var nextFlow = flow
            nextFlow.didCompleteOnboarding()
            flow = nextFlow
            inlineMessage = nil
            return true
        } catch {
            inlineMessage = userFacingMessage(for: error)
            return false
        }
    }

    func openBuild() {
        var nextFlow = flow
        nextFlow.openBuild()
        flow = nextFlow
        inlineMessage = nil
    }

    func closeBuild() {
        var nextFlow = flow
        nextFlow.closeBuild()
        flow = nextFlow
        inlineMessage = nil
    }

    func selectCategory(_ category: FixtureCategory) {
        selectedCategory = category
        inlineMessage = category.isAvailableInFirstSlice ? nil : "Coming soon"
    }

    func beginPlacement(kind: FixtureKind) {
        let defaultOrigin: GridPoint
        switch kind {
        case .basicDisplayTable:
            defaultOrigin = GridPoint(x: 5, y: 4)
        case .simpleShelf:
            defaultOrigin = GridPoint(x: 4, y: ShopLayout.starter.depth - 1)
        }

        let draft = engine.makePlacementDraft(kind: kind, origin: defaultOrigin)
        var nextFlow = flow
        nextFlow.beginPlacement(draft)
        flow = nextFlow
        inlineMessage = nil
    }

    func setPlacementOrigin(_ origin: GridPoint) {
        updateDraft { draft in
            let nextOrigin = clampedOrigin(origin, for: draft)
            draft.origin = nextOrigin
        }
    }

    func movePlacement(deltaX: Int, deltaY: Int) {
        updateDraft { draft in
            let proposed = GridPoint(
                x: draft.origin.x + deltaX,
                y: draft.origin.y + deltaY
            )
            draft.origin = clampedOrigin(proposed, for: draft)
        }
    }

    func rotatePlacement() {
        updateDraft { draft in
            let rotations = FixtureRotation.allCases
            guard let index = rotations.firstIndex(of: draft.rotation) else { return }
            draft.rotation = rotations[(index + 1) % rotations.count]
            draft.origin = clampedOrigin(draft.origin, for: draft)
        }
    }

    func cancelCurrentPlacement() {
        guard let draft = placementDraft else { return }
        engine.cancel(draft)
        state = engine.state
        var nextFlow = flow
        nextFlow.cancelPlacement()
        flow = nextFlow
        inlineMessage = nil
    }

    @discardableResult
    func confirmCurrentPlacement() -> Bool {
        guard let draft = placementDraft else { return false }
        do {
            try engine.confirm(draft)
            try persistEngineState()
            var nextFlow = flow
            nextFlow.finishPlacement()
            flow = nextFlow
            inlineMessage = nil
            return true
        } catch {
            inlineMessage = userFacingMessage(for: error)
            return false
        }
    }

    private func updateDraft(_ mutation: (inout PlacementDraft) -> Void) {
        guard var draft = placementDraft else { return }
        mutation(&draft)
        var nextFlow = flow
        nextFlow.updatePlacement(draft)
        flow = nextFlow
        inlineMessage = nil
    }

    private func clampedOrigin(_ origin: GridPoint, for draft: PlacementDraft) -> GridPoint {
        let definition = FixtureCatalog.definition(for: draft.kind)
        let footprint = definition.footprint.rotated(draft.rotation)
        return GridPoint(
            x: min(max(0, origin.x), engine.layout.width - footprint.width),
            y: min(max(0, origin.y), engine.layout.depth - footprint.depth)
        )
    }

    private func persistEngineState() throws {
        try store.save(engine.state)
        state = engine.state
    }

    private func userFacingMessage(for error: Error) -> String {
        switch error {
        case ShopNameValidationError.empty:
            return "Enter a name for your shop."
        case ShopNameValidationError.tooShort:
            return "Use at least 2 characters."
        case ShopNameValidationError.tooLong:
            return "Keep the name to 24 characters or fewer."
        case ShopNameValidationError.containsControlCharacters:
            return "That name contains unsupported characters."
        case let PlacementError.insufficientFunds(required, available):
            return "You need $\(required), but have $\(available)."
        case PlacementError.outsideShopBounds:
            return "Keep the fixture inside the shop."
        case PlacementError.entranceMustRemainClear:
            return "Keep the entrance clear."
        case let PlacementError.blockedByStaticObject(blocker):
            switch blocker {
            case .rubble:
                return "Clear the rubble before building here."
            case .brokenBoards:
                return "Clear the broken boards before building here."
            case .discardedPapers:
                return "Clear the discarded papers before building here."
            case .frontColumn:
                return "The shop structure blocks this cell."
            }
        case PlacementError.overlapsExistingFixture:
            return "That space is already occupied."
        case PlacementError.shelfMustBeAdjacentToWall:
            return "Shelves must be placed next to a wall."
        default:
            return "The change could not be saved. Please try again."
        }
    }
}
