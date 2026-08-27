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
    public let layout: ShopLayout

    public init(state: GameState = .initial, layout: ShopLayout = .starter) {
        self.state = state
        self.layout = state.world.hitMap.layout == layout ? layout : state.world.hitMap.layout
    }

    @discardableResult
    public mutating func completeOnboarding(shopName rawName: String) throws -> String {
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
        return fixture
    }

    public mutating func cancel(_ draft: PlacementDraft) {
        // Drafts are intentionally transient. Cancelling cannot alter money or state.
        _ = draft
    }
}
