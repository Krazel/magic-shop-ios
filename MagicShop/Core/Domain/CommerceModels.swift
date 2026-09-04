import Foundation

public enum ProductKind: String, CaseIterable, Codable, Hashable, Sendable {
    case glowPotion
    case luckyCharm
    case pocketSpellbook
}

public struct ProductDefinition: Equatable, Sendable {
    public let kind: ProductKind
    public let displayName: String
    public let purchasePrice: Int
    public let salePrice: Int
    public let compatibleFixtures: Set<FixtureKind>

    public func isCompatible(with fixture: FixtureKind) -> Bool {
        compatibleFixtures.contains(fixture)
    }
}

public enum ProductCatalog {
    public static let all: [ProductDefinition] = [
        ProductDefinition(kind: .glowPotion, displayName: "Glow Potion",
                          purchasePrice: 10, salePrice: 25,
                          compatibleFixtures: [.basicDisplayTable, .simpleShelf]),
        ProductDefinition(kind: .luckyCharm, displayName: "Lucky Charm",
                          purchasePrice: 20, salePrice: 45,
                          compatibleFixtures: [.basicDisplayTable]),
        ProductDefinition(kind: .pocketSpellbook, displayName: "Pocket Spellbook",
                          purchasePrice: 30, salePrice: 70,
                          compatibleFixtures: [.simpleShelf])
    ]

    public static func definition(for kind: ProductKind) -> ProductDefinition {
        // The exhaustive switch keeps enum additions visible to the compiler.
        switch kind {
        case .glowPotion: return all[0]
        case .luckyCharm: return all[1]
        case .pocketSpellbook: return all[2]
        }
    }
}

/// One physical unit in one numbered furniture slot. A slot is never a stack.
public struct StockItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let product: ProductKind
    public let fixtureID: UUID
    public let slotIndex: Int
    public let purchaseCost: Int

    public init(id: UUID = UUID(), product: ProductKind, fixtureID: UUID, slotIndex: Int,
                purchaseCost: Int? = nil) {
        self.id = id
        self.product = product
        self.fixtureID = fixtureID
        self.slotIndex = slotIndex
        self.purchaseCost = purchaseCost ?? ProductCatalog.definition(for: product).purchasePrice
    }
}

/// Draft creation, validation and cancellation never spend money.
public struct StockDraft: Equatable, Sendable {
    public let stockID: UUID
    public let product: ProductKind
    public let fixtureID: UUID
    public let slotIndex: Int

    public init(stockID: UUID = UUID(), product: ProductKind, fixtureID: UUID, slotIndex: Int) {
        self.stockID = stockID
        self.product = product
        self.fixtureID = fixtureID
        self.slotIndex = slotIndex
    }
}

public enum ShopPhase: String, Codable, Equatable, Sendable {
    case preparing
    case open
    case summary
}

/// Callers retain this token until a successful save. Replaying an already
/// consumed token fails without changing money, stock or the visitor cursor.
public struct VisitID: Codable, Equatable, Hashable, Sendable {
    public let dayID: UUID
    public let index: Int

    public init(dayID: UUID, index: Int) {
        self.dayID = dayID
        self.index = index
    }
}

public struct CustomerVisit: Equatable, Sendable {
    public let id: VisitID
    public let requestedProduct: ProductKind
}

public struct SaleReceipt: Codable, Equatable, Sendable {
    public let stockID: UUID
    public let product: ProductKind
    public let fixtureID: UUID
    public let slotIndex: Int
    public let revenue: Int
    public let costOfGoods: Int
}

public struct VisitOutcome: Codable, Equatable, Sendable {
    public let visitID: VisitID
    public let requestedProduct: ProductKind
    public let sale: SaleReceipt?
}

public struct ShopDayState: Identifiable, Codable, Equatable, Sendable {
    public static let visitorCount = 6

    public let id: UUID
    public let dayNumber: Int
    public let openingBalance: Int
    public private(set) var nextVisitIndex: Int
    public private(set) var outcomes: [VisitOutcome]

    public init(id: UUID = UUID(), dayNumber: Int, openingBalance: Int) {
        self.id = id
        self.dayNumber = dayNumber
        self.openingBalance = openingBalance
        nextVisitIndex = 0
        outcomes = []
    }

    public var visitors: [CustomerVisit] {
        let products = ProductKind.allCases
        // Each day has two customers per product; the first request rotates.
        let offset = ((dayNumber % products.count) + products.count - 1) % products.count
        return (0..<Self.visitorCount).map { index in
            CustomerVisit(id: VisitID(dayID: id, index: index),
                          requestedProduct: products[(offset + index) % products.count])
        }
    }

    public var nextVisit: CustomerVisit? {
        guard (0..<Self.visitorCount).contains(nextVisitIndex) else { return nil }
        return visitors[nextVisitIndex]
    }

    public var sales: [SaleReceipt] { outcomes.compactMap(\.sale) }
    public var revenue: Int { sales.reduce(0) { $0 + $1.revenue } }
    public var costOfGoods: Int { sales.reduce(0) { $0 + $1.costOfGoods } }
    public var profit: Int { revenue - costOfGoods }
    public var isFinished: Bool { nextVisitIndex == Self.visitorCount }

    mutating func record(_ outcome: VisitOutcome) {
        outcomes.append(outcome)
        nextVisitIndex += 1
    }

    public var summary: DaySummary? {
        guard isFinished else { return nil }
        return DaySummary(id: id, dayNumber: dayNumber, outcomes: outcomes)
    }
}

/// Acknowledged summaries are history, not pending rewards. Revenue was already
/// credited during the corresponding visitor transaction.
public struct DaySummary: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let dayNumber: Int
    public let outcomes: [VisitOutcome]

    public var sales: [SaleReceipt] { outcomes.compactMap(\.sale) }
    public var revenue: Int { sales.reduce(0) { $0 + $1.revenue } }
    public var costOfGoods: Int { sales.reduce(0) { $0 + $1.costOfGoods } }
    public var profit: Int { revenue - costOfGoods }
    public var customersServed: Int { sales.count }
    public var customersWithoutPurchase: Int { outcomes.count - sales.count }
}

public enum CommerceError: Error, Equatable, Sendable {
    case wrongPhase(required: ShopPhase, actual: ShopPhase)
    case onboardingRequired
    case fixtureNotFound(UUID)
    case stockNotFound(UUID)
    case invalidSlot
    case slotOccupied
    case incompatibleProduct
    case insufficientFunds(required: Int, available: Int)
    case duplicateStockID(UUID)
    case duplicateDayID(UUID)
    case fixtureContainsStock
    case noReachableStock
    case unexpectedVisit
    case unexpectedDay
    case balanceOverflow
    case totalOverflow
}

public enum GameStateValidationError: Error, Equatable, Sendable {
    case unsupportedSchemaVersion(Int)
    case invalidState(String)
}
