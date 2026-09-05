import Foundation

extension LivingShopDay {
    func validate(in state: GameState, soldIDs: inout Set<UUID>) throws {
        func bad(_ message: String) -> GameStateValidationError { .invalidState(message) }
        guard dayNumber > 0, openingBalance >= 0,
              (ShopCalendar.openingMinute...ShopCalendar.closingMinute).contains(minute),
              visitors.count == Self.visitorCount else { throw bad("Invalid living day") }
        let walkable = ShopAccess.reachableCells(in: state)
        var revenueTotal = 0
        var costTotal = 0
        for (index, visitor) in visitors.enumerated() {
            guard visitor.id == VisitID(dayID: id, index: index),
                  (540...1020).contains(visitor.arrivalMinute),
                  visitor.arrivalMinute < visitor.decisionMinute,
                  visitor.decisionMinute < visitor.departureMinute,
                  visitor.departureMinute <= 1080,
                  visitor.departureMinute - visitor.arrivalMinute <= 115,
                  visitor.budget > 0, visitor.budget <= 1000,
                  (0..<100).contains(visitor.interestRoll),
                  visitor.secondaryProduct != visitor.preferredProduct,
                  (1...3).contains(visitor.stops.count),
                  Set(visitor.stops.map(\.fixtureID)).count == visitor.stops.count,
                  (visitor.outcome != nil) == (minute >= visitor.decisionMinute) else {
                throw bad("Invalid living visitor or decision cursor")
            }
            if index > 0, visitor.arrivalMinute <= visitors[index - 1].arrivalMinute {
                throw bad("Unordered visitor arrivals")
            }
            var previousMinute = visitor.arrivalMinute
            var previousPoint: GridPoint?
            for stop in visitor.stops {
                guard let fixture = state.fixtures.first(where: { $0.id == stop.fixtureID }),
                      FixtureCatalog.definition(for: fixture.kind).stockCapacity > 0,
                      previousMinute < stop.arrivalMinute,
                      stop.arrivalMinute < stop.departureMinute,
                      stop.departureMinute < visitor.departureMinute,
                      let first = stop.path.first, let last = stop.path.last,
                      walkable.contains(first), walkable.contains(last),
                      previousPoint == nil || previousPoint == first,
                      previousPoint != nil || state.world.hitMap.cell(at: first)?.zone == .entrance,
                      PlacementRules.occupiedCells(for: fixture).contains(where: {
                          abs($0.x - last.x) + abs($0.y - last.y) == 1
                      }) else { throw bad("Invalid browse stop") }
                try Self.validatePath(stop.path, walkable: walkable)
                previousMinute = stop.departureMinute
                previousPoint = last
            }
            guard visitor.decisionMinute >= (visitor.stops.last?.arrivalMinute ?? visitor.arrivalMinute),
                  visitor.decisionMinute < (visitor.stops.last?.departureMinute ?? visitor.departureMinute),
                  visitor.exitPath.first == previousPoint,
                  let exit = visitor.exitPath.last,
                  state.world.hitMap.cell(at: exit)?.zone == .entrance else {
                throw bad("Invalid departure route")
            }
            try Self.validatePath(visitor.exitPath, walkable: walkable)
            if let outcome = visitor.outcome {
                guard outcome.visitID == visitor.id, outcome.requestedProduct == visitor.preferredProduct else {
                    throw bad("Visitor outcome identity mismatch")
                }
                if let sale = outcome.sale {
                    guard visitor.hasBuyingIntent,
                          sale.product == visitor.preferredProduct || sale.product == visitor.secondaryProduct,
                          visitor.stops.contains(where: { $0.fixtureID == sale.fixtureID }),
                          sale.revenue > 0, sale.revenue <= visitor.budget,
                          sale.costOfGoods >= 0, sale.slotIndex >= 0, sale.slotIndex < 2,
                          soldIDs.insert(sale.stockID).inserted else { throw bad("Invalid living sale") }
                    let nextRevenue = revenueTotal.addingReportingOverflow(sale.revenue)
                    let nextCost = costTotal.addingReportingOverflow(sale.costOfGoods)
                    guard !nextRevenue.overflow, !nextCost.overflow else { throw bad("Living totals overflow") }
                    revenueTotal = nextRevenue.partialValue
                    costTotal = nextCost.partialValue
                }
            }
        }
        for time in visitors.map(\.arrivalMinute) {
            guard visitors.filter({ $0.arrivalMinute <= time && time < $0.departureMinute }).count <= 4 else {
                throw bad("Too many concurrent visitors")
            }
        }
        let credited = openingBalance.addingReportingOverflow(revenueTotal)
        let expected = credited.partialValue.addingReportingOverflow(inventoryCashFlow)
        guard !credited.overflow, !expected.overflow, expected.partialValue == state.balance else {
            throw bad("Living day cash flow does not match balance")
        }
    }

    private static func validatePath(_ path: [GridPoint], walkable: Set<GridPoint>) throws {
        guard !path.isEmpty, path.count <= 256, path.allSatisfy({ walkable.contains($0) }) else {
            throw GameStateValidationError.invalidState("Invalid living route cells")
        }
        for pair in zip(path, path.dropFirst()) {
            guard abs(pair.0.x - pair.1.x) + abs(pair.0.y - pair.1.y) == 1 else {
                throw GameStateValidationError.invalidState("Non-cardinal living route")
            }
        }
    }
}
