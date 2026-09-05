import Foundation

// Simulator-only deterministic presentation fixtures. These do not exist in the
// device binary and never read or replace a player's saved shop.
extension AppModel {
    static func makeApplicationModel() -> AppModel {
        #if targetEnvironment(simulator)
        if let index = ProcessInfo.processInfo.arguments.firstIndex(of: "--visual-state"),
           ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
            return makeVisualFixture(ProcessInfo.processInfo.arguments[index + 1])
        }
        #endif
        return AppModel()
    }

    #if targetEnvironment(simulator)
    private static func makeVisualFixture(_ name: String) -> AppModel {
        do {
            var engine = GameEngine()
            if name != "onboarding" { try engine.completeOnboarding(shopName: "Moon & Mortar") }
            if ["stock", "open", "summary", "arrange", "improvements", "journal"].contains(name) {
                let table = try engine.confirm(engine.makePlacementDraft(kind: .basicDisplayTable, origin: GridPoint(x: 5, y: 4)))
                if ["open", "summary"].contains(name) {
                    let shelf = try engine.confirm(engine.makePlacementDraft(kind: .simpleShelf, origin: GridPoint(x: 4, y: 10)))
                    _ = try engine.confirm(engine.makeStockDraft(product: .luckyCharm, fixtureID: table.id, slotIndex: 0))
                    for slot in 0..<2 { _ = try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: shelf.id, slotIndex: slot)) }
                    _ = try engine.openDay()
                    if name == "summary" {
                        while let visit = engine.state.currentDay?.nextVisit { _ = try engine.advanceDay(expectedVisitID: visit.id) }
                    }
                }
            }
            if name == "repair-rubble" { _ = try engine.repair(.rubble) }
            if name == "repair-boards" { _ = try engine.repair(.brokenBoards) }
            if name == "repair-papers" { _ = try engine.repair(.discardedPapers) }
            if name.hasPrefix("restored") {
                let direction: ExpansionDirection = name == "restored-right" ? .right : name == "restored-rear" ? .rear : .left
                engine = try restoredVisualEngine(direction: direction)
            }
            if ["living", "pricing", "care", "floors", "floor-laid", "drag", "living-summary"].contains(name) {
                engine = GameEngine()
                try engine.completeOnboarding(shopName: "Moon & Mortar")
                let table = try engine.confirm(engine.makePlacementDraft(kind: .basicDisplayTable,
                    origin: GridPoint(x: 5, y: 6), fixtureID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!))
                let second = try engine.confirm(engine.makePlacementDraft(kind: .basicDisplayTable,
                    origin: GridPoint(x: 3, y: 4), fixtureID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!))
                let shelf = try engine.confirm(engine.makePlacementDraft(kind: .simpleShelf,
                    origin: GridPoint(x: 4, y: 10), fixtureID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!))
                _ = try engine.confirm(engine.makeStockDraft(product: .luckyCharm, fixtureID: table.id, slotIndex: 0))
                _ = try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: second.id, slotIndex: 0))
                _ = try engine.confirm(engine.makeStockDraft(product: .pocketSpellbook, fixtureID: shelf.id, slotIndex: 0))
                _ = try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: shelf.id, slotIndex: 1))
                try engine.setPrice(30, for: .glowPotion)
                if ["living", "living-summary"].contains(name) {
                    let day = try engine.openLivingDay(seed: 42)
                    let minute = name == "living-summary" ? 1080 : (600...1000).first(where: { minute in
                        day.visitors.filter { $0.arrivalMinute <= minute && minute < $0.departureMinute }.count >= 3
                    }) ?? 680
                    _ = try engine.advanceLivingDay(expectedDayID: day.id, expectedMinute: day.minute, toMinute: minute)
                }
                if name == "floor-laid" {
                    for y in 4...7 { for x in 3...6 { _ = try engine.paintFloor(at: GridPoint(x: x, y: y), style: .warmOak) } }
                }
            }
            let model = AppModel(store: InMemoryGameStateStore(initialState: engine.state))
            switch name {
            case "living": model.togglePause()
            case "pricing": model.showPanel(.pricing)
            case "care": model.showPanel(.care)
            case "floors", "floor-laid":
                model.showPanel(.care); model.carePaint = true
                if name == "floors" { for point in [GridPoint(x: 3, y: 6), GridPoint(x: 4, y: 6), GridPoint(x: 3, y: 7), GridPoint(x: 4, y: 7)] { model.toolStroke(point) } }
            case "build": model.openBuild()
            case "decor": model.openBuild(); model.selectCategory(.decor)
            case "placement": model.beginPlacement(kind: .basicDisplayTable)
            case "stock": model.showPanel(.stock)
            case "improvements": model.showPanel(.improvements)
            case "journal": model.showPanel(.journal)
            case "arrange":
                model.chooseFixture(model.state.fixtures.first?.id); model.panel = .fixture
            case "open":
                model.tick(seconds: 0.05)
                for _ in 0..<16 { model.tick(seconds: 0.25) }
                model.togglePause()
            default: break
            }
            return model
        } catch {
            preconditionFailure("Invalid simulator visual fixture \(name): \(error)")
        }
    }

    private static func restoredVisualEngine(direction: ExpansionDirection) throws -> GameEngine {
        var engine = GameEngine()
        try engine.completeOnboarding(shopName: "Moon & Mortar")
        var tables: [PlacedFixture] = []
        for point in [GridPoint(x: 2, y: 3), GridPoint(x: 4, y: 3), GridPoint(x: 6, y: 3), GridPoint(x: 7, y: 7)] {
            tables.append(try engine.confirm(engine.makePlacementDraft(kind: .basicDisplayTable, origin: point)))
        }
        let shelf = try engine.confirm(engine.makePlacementDraft(kind: .simpleShelf, origin: GridPoint(x: 4, y: 10)))
        for _ in 0..<4 {
            for (index, fixture) in tables.enumerated() {
                _ = try engine.confirm(engine.makeStockDraft(product: index < 2 ? .glowPotion : .luckyCharm, fixtureID: fixture.id, slotIndex: 0))
            }
            for slot in 0..<2 { _ = try engine.confirm(engine.makeStockDraft(product: .pocketSpellbook, fixtureID: shelf.id, slotIndex: slot)) }
            let day = try engine.openDay()
            while let visit = engine.state.currentDay?.nextVisit { _ = try engine.advanceDay(expectedVisitID: visit.id) }
            _ = try engine.acknowledgeDaySummary(dayID: day.id)
        }
        for repair in RestorationGroupID.allCases { _ = try engine.repair(repair) }
        for (kind, point) in [(FixtureKind.pottedFern, GridPoint(x: 2, y: 7)), (.starRug, GridPoint(x: 5, y: 6)), (.crystalDisplay, GridPoint(x: 8, y: 5)), (.wallClock, GridPoint(x: 0, y: 10)), (.moonPainting, GridPoint(x: 8, y: 10)), (.brassLantern, GridPoint(x: 9, y: 7))] {
            _ = try engine.confirm(engine.makePlacementDraft(kind: kind, origin: point))
        }
        if direction == .rear {
            try engine.moveFixture(fixtureID: shelf.id, origin: GridPoint(x: 0, y: 7), rotation: .east)
        }
        _ = try engine.expandShop(toward: direction)
        return engine
    }
    #endif
}