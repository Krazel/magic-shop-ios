import SwiftUI

struct ProvisionalRootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MagicPalette.earth.ignoresSafeArea()
                ShopSceneContainer(
                    state: model.state, preview: model.placementDraft,
                    previewIsValid: model.isPlacementValid,
                    selectedFixtureID: model.selectedFixtureID,
                    activeVisit: model.activeVisit, visitProgress: model.visitProgress,
                    lastOutcome: model.lastOutcome, reduceMotion: reduceMotion,
                    isPaused: model.isPaused || !model.isAppActive,
                    contentLift: model.panel == .stock || model.flow.route == .buildCatalog ? 105 : 0,
                    onGridTap: model.setPlacementOrigin, onFixtureTap: model.selectFixture
                )
                .ignoresSafeArea()
                .accessibilityLabel("Shop floor")
                .accessibilityHint("Pinch to zoom or drag to explore. Select furniture using the Stock list or Build controls.")

                VStack(spacing: 8) {
                    ShopHUD()
                    if model.state.onboardingCompleted {
                        CalendarBar()
                        if model.isTrading { TradingStatus() }
                    }
                    Spacer(minLength: 6)
                    if model.state.onboardingCompleted {
                        bottomPanel(maxHeight: geometry.size.height * 0.60)
                        BottomNavigation()
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)

                if model.flow.route == .onboarding {
                    OnboardingOverlay(maxHeight: geometry.size.height * 0.73)
                        .zIndex(10)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.flow.route)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.panel)
        }
        .preferredColorScheme(.dark)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled else { return }
                model.tick(seconds: 0.05)
            }
        }
        .onChange(of: scenePhase) { model.setAppActive($0 == .active) }
    }

    @ViewBuilder private func bottomPanel(maxHeight: CGFloat) -> some View {
        Group {
            if model.showsSummary { SummaryPanel() }
            else if model.placementDraft != nil { PlacementPanel() }
            else if model.flow.route == .buildCatalog { BuildCatalogPanel() }
            else {
                switch model.panel {
                case .stock: StockPanel()
                case .improvements: ImprovementsPanel()
                case .journal: JournalPanel()
                case .fixture: FixturePanel()
                case .none:
                    if !model.isTrading { PreparationHint() }
                    else if let message = model.inlineMessage { Text(message).font(.callout).padding(14).magicPanel() }
                }
            }
        }
        .frame(maxWidth: 600, maxHeight: maxHeight)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private struct ShopHUD: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        HStack(spacing: 8) {
            if model.state.onboardingCompleted {
                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill").foregroundStyle(MagicPalette.leaf)
                    Text(model.state.shopName ?? "My Shop")
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Image(systemName: "leaf.fill").scaleEffect(x: -1).foregroundStyle(MagicPalette.leaf)
                }.frame(maxWidth: .infinity).hudCapsule()
            } else { Spacer() }
            HStack(spacing: 6) {
                CoinMark(size: 25)
                Text("$\(model.state.balance)").font(.system(.title3, design: .serif, weight: .bold)).monospacedDigit()
            }.hudCapsule().fixedSize()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Balance, \(model.state.balance) dollars")
        }
    }
}

private struct CalendarBar: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: model.isTrading ? "sun.max.fill" : "clock")
                .foregroundStyle(MagicPalette.gold)
            VStack(alignment: .leading, spacing: 1) {
                Text("Day \(model.state.calendar.dayNumber) · \(model.state.calendar.weekdayName)")
                    .font(.system(.subheadline, design: .serif, weight: .bold))
                Text(model.isTrading ? "OPEN 09:00–18:00" : model.showsSummary ? "CLOSED · See you tomorrow" : "PREPARING · Opens at 09:00")
                    .font(.caption2).foregroundStyle(MagicPalette.parchment.opacity(0.8))
            }
            Spacer(minLength: 4)
            Text(model.clockText).font(.system(.title3, design: .serif, weight: .bold)).monospacedDigit()
            if model.state.phase == .preparing {
                Button { model.showPanel(.journal) } label: {
                    Image(systemName: "book.closed.fill").frame(width: 44, height: 44)
                }.accessibilityLabel("Shop journal and goals")
            }
        }
        .foregroundStyle(MagicPalette.parchment).padding(.horizontal, 12).padding(.vertical, 3)
        .magicPanel(corner: 18)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shop-calendar")
    }
}

private struct TradingStatus: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(model.isPaused ? "Shop paused" : "Shop open")
                    .font(.system(.headline, design: .serif))
                Spacer()
                Button { model.isFast.toggle() } label: {
                    Text(model.isFast ? "2×" : "1×").frame(width: 44, height: 44)
                }.accessibilityLabel(model.isFast ? "Normal speed" : "Double speed")
                Button(action: model.togglePause) {
                    Image(systemName: model.isPaused ? "play.fill" : "pause.fill").frame(width: 44, height: 44)
                }.accessibilityLabel(model.isPaused ? "Resume day" : "Pause day")
            }
            ProgressView(value: Double(model.activeVisit?.id.index ?? 6) + model.visitProgress, total: 6)
                .tint(MagicPalette.gold).accessibilityLabel("Trading day progress")
            Text(model.visitorText).font(.caption).multilineTextAlignment(.center)
                .accessibilityIdentifier("visitor-status")
        }.foregroundStyle(MagicPalette.parchment).padding(.horizontal, 14).padding(.bottom, 10).magicPanel(corner: 18)
    }
}

private struct OnboardingOverlay: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var focused: Bool
    let maxHeight: CGFloat
    var body: some View {
        VStack {
            Spacer(minLength: 50)
            ScrollView {
                VStack(spacing: 13) {
                    Image(systemName: "key.horizontal.fill").font(.system(size: 30)).foregroundStyle(MagicPalette.gold).accessibilityHidden(true)
                    Text("A Shop of Your Own").font(.system(.title2, design: .serif, weight: .bold))
                        .multilineTextAlignment(.center).minimumScaleFactor(0.8)
                    GoldDivider()
                    Text("At the end of a quiet street stands a forgotten shop. Dusty windows, worn walls… and a little magic waiting to return.")
                        .font(.system(.body, design: .serif)).multilineTextAlignment(.center)
                    Text("With $500 and a name above the door, you can make it your own.")
                        .font(.system(.body, design: .serif)).multilineTextAlignment(.center)
                    GoldDivider()
                    Text("What will you call your shop?").font(.system(.headline, design: .serif))
                    TextField("My Shop", text: $model.shopNameInput, prompt: Text("My Shop").foregroundColor(.black.opacity(0.5)))
                        .focused($focused).textInputAutocapitalization(.words).submitLabel(.done)
                        .onSubmit(openDoor).font(.system(.title3, design: .serif))
                        .foregroundStyle(Color.black.opacity(0.85)).tint(MagicPalette.teal)
                        .padding(14).background(MagicPalette.parchment, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MagicPalette.gold, lineWidth: 2))
                        .accessibilityLabel("Shop name").accessibilityHint("Enter between 2 and 24 characters")
                        .accessibilityIdentifier("shop-name-field")
                    InlineMessage()
                    Button("Open the Door", action: openDoor).buttonStyle(GoldButtonStyle()).accessibilityIdentifier("open-the-door-button")
                }.foregroundStyle(MagicPalette.parchment).padding(24)
            }.scrollDismissesKeyboard(.interactively).frame(maxWidth: 520, maxHeight: maxHeight)
                .magicPanel(corner: 34).padding(.horizontal, 20)
            Spacer(minLength: 30)
        }
    }
    private func openDoor() { focused = false; _ = model.submitOnboarding() }
}

private struct PanelHeading: View {
    @EnvironmentObject private var model: AppModel
    let title: String
    let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(MagicPalette.gold)
            Text(title).font(.system(.title2, design: .serif, weight: .bold))
            Spacer()
            Button(action: model.closeBuild) { Image(systemName: "xmark").frame(width: 44, height: 44) }
                .accessibilityLabel("Close \(title)")
        }.foregroundStyle(MagicPalette.parchment)
    }
}

private struct BuildCatalogPanel: View {
    @EnvironmentObject private var model: AppModel
    private var entries: [FixtureDefinition] {
        FixtureCatalog.all.filter { $0.category == model.selectedCategory }
    }
    var body: some View {
        VStack(spacing: 8) {
            PanelHeading(title: "Build", icon: "hammer.fill")
            HStack(spacing: 5) {
                ForEach(FixtureCategory.allCases, id: \.self) { category in
                    Button(category == .walls ? "Improve" : category.rawValue.capitalized) { model.selectCategory(category) }
                        .font(.system(.subheadline, design: .serif, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(MagicPalette.parchment)
                        .background(model.selectedCategory == category ? MagicPalette.teal : .black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(MagicPalette.gold.opacity(0.7), lineWidth: 1))
                }
            }
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 10) {
                    ForEach(entries, id: \.kind) { definition in
                        Button { model.beginPlacement(kind: definition.kind) } label: {
                            VStack(spacing: 5) {
                                Image(definition.kind.assetName).resizable().scaledToFit().frame(height: 90)
                                Text(definition.displayName).font(.system(.headline, design: .serif)).multilineTextAlignment(.center).frame(minHeight: 40)
                                Text(definition.stockCapacity > 0 ? "Holds \(definition.stockCapacity) \(definition.stockCapacity == 1 ? "item" : "items")" : "Make it your own")
                                    .font(.caption)
                                Text("$\(definition.price)").font(.title3.bold()).padding(.horizontal, 22).padding(.vertical, 8)
                                    .foregroundStyle(MagicPalette.parchment).background(MagicPalette.deepTeal, in: Capsule())
                            }.foregroundStyle(MagicPalette.ink).padding(12).frame(width: 155).parchmentCard()
                        }.buttonStyle(.plain).accessibilityIdentifier("fixture-\(definition.kind.rawValue)")
                            .accessibilityLabel("\(definition.displayName), \(definition.price) dollars")
                            .accessibilityHint("Choose a position. Pay only when you confirm.")
                    }
                }.padding(.bottom, 5)
            }
            Text("Pay only when you place. Move or sell later.").font(.caption).foregroundStyle(MagicPalette.parchment)
            InlineMessage()
        }.padding(14).magicPanel().accessibilityIdentifier("build-catalog")
    }
}

private struct PlacementPanel: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        if let definition = model.placementDefinition {
            VStack(spacing: 8) {
                Text(definition.displayName).font(.system(.headline, design: .serif))
                Text(model.movingFixtureID == nil ? "$\(definition.price) · Tap the floor to position" : "Move for free · Stock stays on the display")
                    .font(.caption)
                Text(model.placementMessage ?? "").font(.caption.weight(.semibold))
                    .foregroundStyle(model.isPlacementValid ? MagicPalette.mint : .orange)
                HStack(spacing: 6) {
                    moveButton("arrow.left", "Move left", -1, 0)
                    moveButton("arrow.up", "Move toward rear wall", 0, 1)
                    moveButton("arrow.down", "Move toward entrance", 0, -1)
                    moveButton("arrow.right", "Move right", 1, 0)
                    Button(action: model.rotatePlacement) { Image(systemName: "rotate.right").frame(width: 44, height: 44) }
                        .accessibilityLabel("Rotate clockwise")
                }.foregroundStyle(MagicPalette.gold)
                HStack(spacing: 10) {
                    Button("Cancel", action: model.cancelCurrentPlacement).buttonStyle(GoldButtonStyle(secondary: true))
                    Button(model.movingFixtureID == nil ? "Place" : "Move") { _ = model.confirmCurrentPlacement() }
                        .buttonStyle(GoldButtonStyle()).disabled(!model.isPlacementValid)
                        .accessibilityIdentifier("confirm-placement")
                }
                InlineMessage()
            }.foregroundStyle(MagicPalette.parchment).padding(15).magicPanel().accessibilityIdentifier("placement-panel")
        }
    }
    private func moveButton(_ icon: String, _ label: String, _ x: Int, _ y: Int) -> some View {
        Button { model.movePlacement(deltaX: x, deltaY: y) } label: { Image(systemName: icon).frame(width: 44, height: 44) }.accessibilityLabel(label)
    }
}

private struct StockPanel: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        VStack(spacing: 7) {
            PanelHeading(title: "Stock", icon: "shippingbox.fill")
            if model.stockFixtures.isEmpty {
                Text("Every little shop starts with a display.").font(.system(.headline, design: .serif))
                Text("Build a $50 table, then stock your first Glow Potion for $10.").font(.callout).multilineTextAlignment(.center)
                Button("Choose a display", action: model.openBuild).buttonStyle(GoldButtonStyle())
            } else {
                fixturePicker
                if let definition = model.selectedFixtureDefinition {
                    HStack {
                        ForEach(0..<definition.stockCapacity, id: \.self) { index in
                            Button { model.selectedSlot = index } label: {
                                let item = model.state.stock.first { $0.fixtureID == model.selectedFixtureID && $0.slotIndex == index }
                                Text("Slot \(index + 1) · \(item == nil ? "Empty" : "Full")")
                                    .font(.caption.bold()).frame(maxWidth: .infinity, minHeight: 44)
                                    .background(model.selectedSlot == index ? MagicPalette.teal : .black.opacity(0.2), in: Capsule())
                            }.accessibilityValue(model.selectedSlot == index ? "Selected" : "")
                        }
                    }
                    if let fixture = model.selectedFixture, !ShopAccess.isReachable(fixture, in: model.state) {
                        Text("Customers cannot reach this display. Move it or clear the path.").font(.caption).foregroundStyle(.orange)
                    }
                    if let item = model.selectedStock { stockedItem(item) }
                    else { productChoices }
                    HStack {
                        Button("Move display", action: model.beginMovingSelectedFixture).font(.caption).frame(minHeight: 44)
                        Spacer()
                        Button("Manage", action: { model.panel = .fixture }).font(.caption).frame(minHeight: 44)
                    }
                }
            }
            InlineMessage()
        }.foregroundStyle(MagicPalette.parchment).padding(14).magicPanel().accessibilityIdentifier("stock-panel")
    }
    private var fixturePicker: some View {
        Picker("Display", selection: Binding(get: { model.selectedFixtureID }, set: { model.chooseFixture($0) })) {
            ForEach(Array(model.stockFixtures.enumerated()), id: \.element.id) { index, fixture in
                Text("\(FixtureCatalog.definition(for: fixture.kind).displayName) \(index + 1)").tag(Optional(fixture.id))
            }
        }.pickerStyle(.menu).tint(MagicPalette.parchment).accessibilityLabel("Choose display")
    }
    private var productChoices: some View {
        VStack(spacing: 7) {
            ScrollView {
                VStack(spacing: 3) {
                    ForEach(ProductCatalog.all, id: \.kind) { product in
                        let compatible = model.selectedFixture.map { product.isCompatible(with: $0.kind) } ?? false
                        Button { model.selectedProduct = product.kind } label: {
                            HStack(spacing: 10) {
                                Image(product.kind.assetName).resizable().scaledToFit().frame(width: 48, height: 52)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.displayName).font(.system(.headline, design: .serif))
                                    Text("Buy $\(product.purchasePrice) · Sell $\(product.salePrice)").font(.subheadline.weight(.semibold)).foregroundStyle(MagicPalette.deepTeal)
                                    Text(product.kind == .pocketSpellbook ? "Shelf only" : product.kind == .luckyCharm ? "Table only" : "Table or shelf").font(.caption)
                                }
                                Spacer(minLength: 0)
                                if model.selectedProduct == product.kind { Image(systemName: "checkmark").foregroundStyle(MagicPalette.bronze) }
                            }.foregroundStyle(MagicPalette.ink).padding(8).frame(maxWidth: .infinity).parchmentCard()
                                .opacity(compatible ? 1 : 0.55)
                        }.buttonStyle(.plain).disabled(!compatible).accessibilityIdentifier("product-\(product.kind.rawValue)")
                    }
                }
            }.frame(maxHeight: 220)
            if let reason = model.stockFailure { Text(reason).font(.caption).foregroundStyle(.orange) }
            HStack(spacing: 10) {
                Button("Cancel", action: model.closeBuild).buttonStyle(GoldButtonStyle(secondary: true))
                Button("Stock for $\(ProductCatalog.definition(for: model.selectedProduct).purchasePrice)") { _ = model.confirmStock() }
                    .buttonStyle(GoldButtonStyle()).disabled(model.stockFailure != nil).accessibilityIdentifier("confirm-stock")
            }
        }
    }
    private func stockedItem(_ item: StockItem) -> some View {
        HStack {
            Image(item.product.assetName).resizable().scaledToFit().frame(width: 60, height: 70)
            VStack(alignment: .leading) {
                Text(ProductCatalog.definition(for: item.product).displayName).font(.system(.headline, design: .serif))
                Text("Ready for today's visitors").font(.caption)
                Button("Return for $\(item.purchaseCost)", action: model.returnSelectedStock).frame(minHeight: 44).font(.callout.bold())
            }
        }.frame(maxWidth: .infinity).padding(10).foregroundStyle(MagicPalette.ink).parchmentCard()
    }
}

private struct FixturePanel: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        VStack(spacing: 10) {
            PanelHeading(title: "Arrange", icon: "hand.draw.fill")
            if let fixture = model.selectedFixture, let definition = model.selectedFixtureDefinition {
                Image(fixture.kind.assetName).resizable().scaledToFit().frame(height: 85)
                Text(definition.displayName).font(.system(.headline, design: .serif))
                Button("Move for free", action: model.beginMovingSelectedFixture).buttonStyle(GoldButtonStyle())
                if definition.stockCapacity > 0 {
                    Button("Manage stock") { model.panel = .stock }.buttonStyle(GoldButtonStyle(secondary: true))
                }
                Button("Sell for $\(definition.price)", action: model.sellSelectedFixture).frame(minHeight: 44)
                Text("Return any stock first. You can buy the fixture again at the same price.").font(.caption).multilineTextAlignment(.center)
            }
            InlineMessage()
        }.foregroundStyle(MagicPalette.parchment).padding(16).magicPanel()
    }
}

private struct SummaryPanel: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        if let summary = model.state.currentDay?.summary {
            VStack(spacing: 12) {
                Image(systemName: "moon.stars.fill").font(.title).foregroundStyle(MagicPalette.gold).accessibilityHidden(true)
                Text("Day complete").font(.system(.title, design: .serif, weight: .bold))
                Text("Day \(summary.dayNumber) · \(summary.customersServed) items sold").font(.system(.headline, design: .serif))
                GoldDivider()
                VStack(spacing: 8) {
                    summaryRow("Sales", summary.revenue)
                    summaryRow("Stock cost", summary.costOfGoods)
                    summaryRow("Profit", summary.profit)
                }.font(.system(.title3, design: .serif)).padding(.horizontal, 20)
                Text(summary.customersServed == 6 ? "Every visitor found a little magic." : "\(summary.customersWithoutPurchase) visitors left without buying. Try a mix of all three products tomorrow.")
                    .font(.callout).multilineTextAlignment(.center)
                Button("Prepare Day \(summary.dayNumber + 1)", action: model.prepareNextDay)
                    .buttonStyle(GoldButtonStyle()).accessibilityIdentifier("prepare-next-day")
                InlineMessage()
            }.foregroundStyle(MagicPalette.parchment).padding(22).magicPanel(corner: 32).accessibilityIdentifier("day-summary")
        }
    }
    private func summaryRow(_ name: String, _ value: Int) -> some View { HStack { Text(name); Spacer(); Text("$\(value)").monospacedDigit() } }
}

private struct PreparationHint: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        VStack(spacing: 6) {
            Text(model.state.hasCompletedRestoration ? "Your little shop is restored ✦" : model.state.fixtures.isEmpty ? "A little magic starts here" : model.state.stock.isEmpty ? "Your displays are waiting" : "Ready when you are")
                .font(.system(.headline, design: .serif))
            Text(model.state.fixtures.isEmpty ? "BUILD a display, STOCK an item, then OPEN your doors." : model.state.stock.isEmpty ? "Stock a few curious things. Each slot holds one item." : "Two visitors per product today. Unsold stock stays for tomorrow.")
                .font(.caption).multilineTextAlignment(.center)
            HStack {
                Button("Improve the shop") { model.showPanel(.improvements) }.frame(minHeight: 44)
                Spacer()
                Button("Journal") { model.showPanel(.journal) }.frame(minHeight: 44)
            }.font(.caption.bold()).foregroundStyle(MagicPalette.gold)
            InlineMessage()
        }.foregroundStyle(MagicPalette.parchment).padding(.horizontal, 14).padding(.top, 12).magicPanel(corner: 20)
    }
}

private struct BottomNavigation: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        HStack(spacing: 8) {
            nav("BUILD", "hammer.fill", MagicPalette.purple, model.state.phase == .preparing, model.flow.route == .buildCatalog, model.openBuild)
            nav("STOCK", "shippingbox.fill", MagicPalette.coral, model.state.phase == .preparing, model.panel == .stock) { model.showPanel(.stock) }
            nav("OPEN", "storefront.fill", MagicPalette.teal, model.state.phase == .preparing, model.isTrading, model.startDay)
        }
    }
    private func nav(_ title: String, _ icon: String, _ color: Color, _ enabled: Bool, _ active: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.system(.headline, design: .serif, weight: .heavy))
            }.foregroundStyle(MagicPalette.parchment).frame(maxWidth: .infinity, minHeight: 62)
                .background(LinearGradient(colors: [color.opacity(0.8), color, color.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 21))
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(MagicPalette.goldGradient, lineWidth: active ? 3 : 2))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.22), lineWidth: 1).padding(4))
                .shadow(color: active ? MagicPalette.gold.opacity(0.5) : .black.opacity(0.4), radius: active ? 6 : 2, y: 2)
                .opacity(enabled || active ? 1 : 0.5)
        }.buttonStyle(.plain).disabled(!enabled).accessibilityIdentifier("nav-\(title.lowercased())")
    }
}

private struct InlineMessage: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        if let message = model.inlineMessage {
            Text(message).font(.caption.weight(.semibold)).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("inline-message")
        }
    }
}

private struct CoinMark: View {
    let size: CGFloat
    var body: some View {
        Text("$").font(.system(size: size * 0.65, weight: .black, design: .serif))
            .foregroundStyle(MagicPalette.bronze).frame(width: size, height: size)
            .background(MagicPalette.goldGradient, in: Circle()).overlay(Circle().stroke(MagicPalette.bronze, lineWidth: 1)).accessibilityHidden(true)
    }
}
private struct GoldDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().frame(height: 1)
            Text("❧  ◆  ❧").font(.system(.caption, design: .serif))
            Rectangle().frame(height: 1)
        }.foregroundStyle(MagicPalette.gold).accessibilityHidden(true)
    }
}
private struct GoldButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var enabled
    var secondary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .serif, weight: .bold))
            .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 48).padding(.horizontal, 8)
            .foregroundStyle(secondary ? MagicPalette.ink : MagicPalette.parchment)
            .background(secondary ? MagicPalette.parchment : MagicPalette.teal, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(MagicPalette.goldGradient, lineWidth: 2))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.18), lineWidth: 1).padding(3))
            .shadow(color: .black.opacity(0.4), radius: 2, y: 2)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1).opacity(enabled ? 1 : 0.45)
    }
}
private extension View {
    func magicPanel(corner: CGFloat = 27) -> some View {
        self.background {
            ZStack {
                LinearGradient(colors: [MagicPalette.deepTeal, MagicPalette.teal.opacity(0.85), MagicPalette.deepTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image("OrnatePanel").resizable(capInsets: EdgeInsets(top: 90, leading: 65, bottom: 65, trailing: 65)).opacity(0.8)
            }.clipShape(RoundedRectangle(cornerRadius: corner))
        }
        .overlay(RoundedRectangle(cornerRadius: corner).stroke(MagicPalette.goldGradient, lineWidth: 2.5))
        .overlay(RoundedRectangle(cornerRadius: max(1, corner - 4)).stroke(.white.opacity(0.18), lineWidth: 1).padding(4))
        .shadow(color: .black.opacity(0.55), radius: 8, y: 5)
    }
    func hudCapsule() -> some View { foregroundStyle(MagicPalette.parchment).padding(.horizontal, 12).frame(minHeight: 46).magicPanel(corner: 27) }
    func parchmentCard() -> some View {
        background(LinearGradient(colors: [MagicPalette.parchment, Color(red: 0.81, green: 0.68, blue: 0.46)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(MagicPalette.goldGradient, lineWidth: 1.5))
    }
}
private enum MagicPalette {
    static let earth = Color(red: 0.26, green: 0.21, blue: 0.15)
    static let deepTeal = Color(red: 0.025, green: 0.12, blue: 0.115)
    static let teal = Color(red: 0.07, green: 0.34, blue: 0.30)
    static let gold = Color(red: 0.90, green: 0.65, blue: 0.26)
    static let bronze = Color(red: 0.43, green: 0.25, blue: 0.06)
    static let parchment = Color(red: 0.97, green: 0.89, blue: 0.72)
    static let ink = Color(red: 0.13, green: 0.13, blue: 0.09)
    static let leaf = Color(red: 0.61, green: 0.72, blue: 0.20)
    static let mint = Color(red: 0.5, green: 0.93, blue: 0.76)
    static let purple = Color(red: 0.40, green: 0.18, blue: 0.69)
    static let coral = Color(red: 0.69, green: 0.20, blue: 0.12)
    static let goldGradient = LinearGradient(colors: [bronze, parchment, gold, bronze, gold], startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension FixtureKind {
    var assetName: String {
        switch self {
        case .basicDisplayTable: return "BasicDisplayTable"
        case .simpleShelf: return "SimpleShelf"
        case .pottedFern: return "PottedFern"
        case .starRug: return "StarRug"
        case .crystalDisplay: return "CrystalDisplay"
        case .wallClock: return "WallClock"
        case .moonPainting: return "MoonPainting"
        case .brassLantern: return "BrassLantern"
        }
    }
}
extension ProductKind {
    var assetName: String {
        switch self {
        case .glowPotion: return "GlowPotion"
        case .luckyCharm: return "LuckyCharm"
        case .pocketSpellbook: return "PocketSpellbook"
        }
    }
}
private struct ImprovementsPanel: View {
    @EnvironmentObject private var model: AppModel
    @State private var direction: ExpansionDirection = .left
    var body: some View {
        VStack(spacing: 8) {
            PanelHeading(title: "A little better", icon: "sparkles")
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Restore the room").font(.system(.headline, design: .serif))
                    ForEach(RepairCatalog.all) { repair in
                        let finished = model.state.restoration.repairedGroups.contains(repair.id)
                        HStack {
                            Image(systemName: finished ? "checkmark.seal.fill" : "paintbrush.pointed.fill").foregroundStyle(MagicPalette.gold)
                            Text(repair.displayName).font(.system(.subheadline, design: .serif, weight: .bold))
                            Spacer()
                            if finished { Text("Done").font(.caption).foregroundStyle(MagicPalette.mint) }
                            else {
                                Button("$\(repair.price)") { model.repair(repair.id) }
                                    .buttonStyle(GoldButtonStyle()).frame(width: 90)
                                    .disabled(model.repairFailure(repair.id) != nil)
                                    .accessibilityLabel("\(repair.displayName), \(repair.price) dollars")
                            }
                        }.padding(10).background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                    }
                    Text("Every repair clears real space for your displays.").font(.caption)
                    GoldDivider()
                    Text("Make it yours").font(.system(.headline, design: .serif))
                    Text("Plants, starlight, framed moons and warm brass. Pick your favorites in Build → Decor.").font(.callout)
                    Button("Choose decorations") { model.openBuild(); model.selectCategory(.decor) }.buttonStyle(GoldButtonStyle(secondary: true))
                    GoldDivider()
                    if let expansion = model.state.restoration.expansion {
                        Label("\(expansion.direction.displayName) complete", systemImage: "checkmark.seal.fill").foregroundStyle(MagicPalette.mint)
                        Text("Your new room is ready for furniture and visitors.").font(.caption)
                    } else {
                        Text("A room to grow").font(.system(.headline, design: .serif))
                        Text("After repairs, add one cozy room for $250. Choose the side that suits your shop.").font(.callout)
                        Picker("New room position", selection: $direction) {
                            ForEach(ExpansionDirection.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }.pickerStyle(.segmented)
                        if let reason = model.expansionFailure(direction) { Text(reason).font(.caption).foregroundStyle(MagicPalette.gold) }
                        Button("Add \(direction.displayName) · $250") { model.expand(direction) }
                            .buttonStyle(GoldButtonStyle()).disabled(model.expansionFailure(direction) != nil)
                            .accessibilityIdentifier("confirm-expansion")
                    }
                    InlineMessage()
                }.padding(.bottom, 8)
            }
        }.foregroundStyle(MagicPalette.parchment).padding(16).magicPanel().accessibilityIdentifier("improvements-panel")
    }
}

private struct JournalPanel: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        VStack(spacing: 8) {
            PanelHeading(title: "Shop journal", icon: "book.closed.fill")
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if model.state.hasCompletedRestoration {
                        VStack(spacing: 8) {
                            Image(systemName: "star.circle.fill").font(.largeTitle).foregroundStyle(MagicPalette.gold)
                            Text("A little shop, full of magic").font(.system(.title2, design: .serif, weight: .bold))
                            Text("You brought this forgotten place back to life. Keep trading, rearrange your treasures, and enjoy the shop you made.").font(.callout)
                        }.multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.vertical, 10)
                    } else {
                        Text("Bring your little shop back to life").font(.system(.headline, design: .serif))
                    }
                    let progress = model.state.restorationProgress
                    goal("Repair the three worn areas", progress.repairedGroups, 3)
                    goal("Place three different decorations", progress.decorationVariety, 3)
                    goal("Complete three days with sales", progress.successfulTradingDays, 3)
                    goal("Add a cozy new room", progress.hasExpansion ? 1 : 0, 1)
                    GoldDivider()
                    Text("Your rhythm").font(.system(.headline, design: .serif))
                    Text("Prepare for as long as you like. Open from 09:00 to 18:00, with two visitors for each product. Pause or use 2× speed whenever you like. Time stops while the app is away.").font(.callout)
                    Text("One item per display slot. Unsold stock stays overnight. Return items or sell empty furniture at their purchase price whenever you want to try something different.").font(.callout)
                    if !model.state.dayHistory.isEmpty {
                        GoldDivider()
                        Text("Recent days").font(.system(.headline, design: .serif))
                        ForEach(Array(model.state.dayHistory.suffix(7).reversed())) { summary in
                            HStack {
                                Text("Day \(summary.dayNumber) · \(summary.weekdayName)")
                                Spacer()
                                Text("\(summary.customersServed) sold · $\(summary.profit) profit")
                            }.font(.caption)
                        }
                    }
                    Text("Saved on this iPhone · No internet needed").font(.caption).foregroundStyle(MagicPalette.gold).padding(.top, 4)
                }.padding(.bottom, 8)
            }
        }.foregroundStyle(MagicPalette.parchment).padding(16).magicPanel().accessibilityIdentifier("journal-panel")
    }
    private func goal(_ title: String, _ count: Int, _ target: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: count >= target ? "checkmark.circle.fill" : "circle").foregroundStyle(count >= target ? MagicPalette.mint : MagicPalette.gold)
            Text(title).font(.callout)
            Spacer(minLength: 3)
            Text("\(min(count, target))/\(target)").font(.caption.bold()).monospacedDigit()
        }
    }
}
