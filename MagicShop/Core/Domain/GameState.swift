import Foundation

public struct GameState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2
    public static let startingBalance = 500

    public var schemaVersion: Int
    public var shopName: String?
    public var onboardingCompleted: Bool
    public var balance: Int
    public var fixtures: [PlacedFixture]
    public var world: ShopWorldState

    public init(
        schemaVersion: Int = GameState.currentSchemaVersion,
        shopName: String? = nil,
        onboardingCompleted: Bool = false,
        balance: Int = GameState.startingBalance,
        fixtures: [PlacedFixture] = [],
        world: ShopWorldState = .starter
    ) {
        self.schemaVersion = schemaVersion
        self.shopName = shopName
        self.onboardingCompleted = onboardingCompleted
        self.balance = balance
        self.fixtures = fixtures
        self.world = world
    }

    public static var initial: GameState { GameState() }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case shopName
        case onboardingCompleted
        case balance
        case fixtures
        case world
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = GameState.currentSchemaVersion
        shopName = try container.decodeIfPresent(String.self, forKey: .shopName)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        balance = try container.decodeIfPresent(Int.self, forKey: .balance) ?? GameState.startingBalance
        fixtures = try container.decodeIfPresent([PlacedFixture].self, forKey: .fixtures) ?? []
        world = try container.decodeIfPresent(ShopWorldState.self, forKey: .world) ?? .starter
    }
}
