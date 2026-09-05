import Foundation

public struct PricingQuote: Equatable, Sendable {
    public let product: ProductKind
    public let price: Int
    public let marketPrice: Int
    public let cost: Int
    /// Price appeal among interested visitors. Budget, available stock and browsing
    /// still determine a purchase; this is not a promised sell-through percentage.
    public let estimatedDemandPercent: Int
    public var isBelowCost: Bool { price < cost }
    public var minimumPrice: Int { cost }
    public var maximumPrice: Int { marketPrice * 3 }
}

public enum ShopPricing {
    public static var marketPrices: [ProductKind: Int] {
        Dictionary(uniqueKeysWithValues: ProductCatalog.all.map { ($0.kind, $0.salePrice) })
    }
    public static func quote(for product: ProductKind, price: Int) -> PricingQuote {
        let definition = ProductCatalog.definition(for: product)
        // Clamp the calculation before multiplication, including UI previews of
        // invalid imported/extreme values. Validation rejects invalid prices.
        let bounded = min(max(price, 1), definition.salePrice * 3)
        let appeal = max(5, min(95, 125 - 50 * bounded / definition.salePrice))
        return PricingQuote(product: product, price: price, marketPrice: definition.salePrice,
                            cost: definition.purchasePrice, estimatedDemandPercent: appeal)
    }
}

public enum ShopCare {
    public static let maximumDirtCells = 64
    public static let maximumDirtLevel = 3
    public static let repairStrokesRequired = 3
    public static let paintableStyles: [FloorStyleID] = [.terracotta, .warmOak, .checkerStone]
    public static func paintCost(for style: FloorStyleID) -> Int? {
        switch style {
        case .terracotta: return 1
        case .warmOak: return 2
        case .checkerStone: return 3
        default: return nil
        }
    }
}

public struct CleaningResult: Equatable, Sendable {
    public let point: GridPoint
    public let removedDirt: Int
    public let repairGroup: RestorationGroupID?
    public let repairProgress: Int
    public let completedRepair: Bool
    public var didChange: Bool { removedDirt > 0 || repairGroup != nil }
}

public enum LivingShopError: Error, Equatable, Sendable {
    case invalidPrice(minimum: Int, maximum: Int)
    case invalidFloorStyle
    case invalidCareCell
    case unexpectedMinute
    case invalidMinuteRange
    case noWalkableEntrance
    case workingCapitalRequired
}

extension GameState {
    public var canManageStock: Bool {
        phase == .preparing || (phase == .open && livingDay != nil)
    }
    public func price(for product: ProductKind) -> Int {
        pricing[product] ?? ProductCatalog.definition(for: product).salePrice
    }
    public func repairProgress(for group: RestorationGroupID) -> Int {
        restoration.repairedGroups.contains(group) ? ShopCare.repairStrokesRequired : (manualRepairProgress[group] ?? 0)
    }
    mutating func addFootfallDirt(at point: GridPoint) {
        guard let cell = world.hitMap.cell(at: point), cell.zone != .outside,
              cell.staticBlocker == nil else { return }
        if let level = dirt[point] {
            dirt[point] = min(ShopCare.maximumDirtLevel, level + 1)
        } else if dirt.count < ShopCare.maximumDirtCells {
            dirt[point] = 1
        }
    }
}
