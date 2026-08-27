import SwiftUI

struct ProvisionalRootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            MagicPalette.earth
                .ignoresSafeArea()

            ShopSceneContainer(
                world: model.state.world,
                fixtures: model.state.fixtures,
                preview: model.placementDraft,
                previewIsValid: model.isPlacementValid,
                onGridTap: model.setPlacementOrigin
            )
            .ignoresSafeArea()
            .accessibilityLabel("Shop floor")
            .accessibilityHint("Pinch to zoom or drag vertically. While placing furniture, tap a floor tile to move it.")

            VStack(spacing: 10) {
                ShopHUD(
                    shopName: model.state.shopName,
                    balance: model.state.balance,
                    showsName: model.flow.route != .onboarding
                )

                Spacer(minLength: 8)

                if model.flow.route == .buildCatalog {
                    BuildCatalogPanel()
                        .environmentObject(model)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if model.placementDraft != nil {
                    PlacementPanel()
                        .environmentObject(model)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if model.flow.route != .onboarding {
                    BottomNavigation()
                        .environmentObject(model)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 8)

            if model.flow.route == .onboarding {
                OnboardingOverlay()
                    .environmentObject(model)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: model.flow.route)
        .preferredColorScheme(.dark)
    }
}

private struct ShopHUD: View {
    let shopName: String?
    let balance: Int
    let showsName: Bool

    var body: some View {
        HStack(spacing: 12) {
            if showsName {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(MagicPalette.leaf)
                    Text(shopName ?? "My Shop")
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Image(systemName: "leaf.fill")
                        .scaleEffect(x: -1, y: 1)
                        .foregroundStyle(MagicPalette.leaf)
                }
                .frame(maxWidth: .infinity)
                .hudCapsule()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Shop name, \(shopName ?? "My Shop")")
            } else {
                Spacer()
            }

            HStack(spacing: 7) {
                CoinMark()
                Text("$\(balance)")
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .monospacedDigit()
            }
            .hudCapsule()
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Balance, \(balance) dollars")
        }
    }
}

private struct OnboardingOverlay: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var nameFieldFocused: Bool

    private let story = """
    At the end of a quiet street stands an old shop no one has opened in years.
    The windows are dusty, the walls are worn, and every shelf is gone. But you have always dreamed of owning a shop of curious things.

    With $500 and a name above the door, this forgotten room can become yours.
    """

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { nameFieldFocused = false }

            ScrollView {
                VStack(spacing: 14) {
                    ZStack {
                        Image(systemName: "door.left.hand.closed")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(MagicPalette.gold)

                        HStack(spacing: 5) {
                            CoinMark(size: 22)
                            Text("$\(model.state.balance)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(MagicPalette.parchment)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(MagicPalette.deepTeal, in: Capsule())
                        .overlay { Capsule().stroke(MagicPalette.gold, lineWidth: 2) }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .accessibilityHidden(true)

                    Text("A Shop of Your Own")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(MagicPalette.parchment)

                    GoldDivider()

                    Text(story)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(MagicPalette.parchment)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    GoldDivider()

                    Text("What will you call your shop?")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(MagicPalette.parchment)

                    TextField("My Shop", text: $model.shopNameInput)
                        .focused($nameFieldFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .submitLabel(.done)
                        .onSubmit(openDoor)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Color.black.opacity(0.82))
                        .padding(.horizontal, 15)
                        .frame(minHeight: 52)
                        .background(MagicPalette.parchment, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MagicPalette.gold, lineWidth: 3)
                        }
                        .accessibilityLabel("Shop name")
                        .accessibilityHint("Enter between 2 and 24 characters")
                        .accessibilityIdentifier("shop-name-field")

                    if let message = model.inlineMessage {
                        Text(message)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.76, blue: 0.64))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("shop-name-error")
                    }

                    Button(action: openDoor) {
                        Text("Open the Door")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TealGoldButtonStyle())
                    .accessibilityHint("Saves your shop name and enters the shop")
                    .accessibilityIdentifier("open-the-door-button")
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: 560, maxHeight: 690)
            .background(MagicPalette.deepTeal.opacity(0.98), in: RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(MagicPalette.gold, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.55), radius: 18, y: 9)
            .padding(.horizontal, 22)
            .padding(.top, 96)
            .padding(.bottom, 32)
        }
    }

    private func openDoor() {
        nameFieldFocused = false
        _ = model.submitOnboarding()
    }
}

private struct BuildCatalogPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Label("Build", systemImage: "hammer.fill")
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(MagicPalette.parchment)
                Spacer()
                Button(action: model.closeBuild) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(MagicPalette.parchment)
                .accessibilityLabel("Close Build")
            }

            HStack(spacing: 6) {
                ForEach(FixtureCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: model.selectedCategory == category,
                        action: { model.selectCategory(category) }
                    )
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FixtureCatalog.firstSlice, id: \.kind) { definition in
                        FixtureCatalogCard(definition: definition) {
                            model.beginPlacement(kind: definition.kind)
                        }
                    }
                }
                .padding(.horizontal, 3)
            }

            if let message = model.inlineMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MagicPalette.parchment.opacity(0.86))
                    .accessibilityIdentifier("build-inline-message")
            }
        }
        .padding(14)
        .background(MagicPalette.deepTeal.opacity(0.98), in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(MagicPalette.gold, lineWidth: 3)
        }
        .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
        .accessibilityIdentifier("build-catalog")
    }
}

private struct CategoryButton: View {
    let category: FixtureCategory
    let isSelected: Bool
    let action: () -> Void

    private var title: String {
        switch category {
        case .tables: return "Tables"
        case .shelves: return "Shelves"
        case .decor: return "Decor"
        case .walls: return "Walls"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(.subheadline, design: .serif, weight: .bold))
                    .lineLimit(1)
                if !category.isAvailableInFirstSlice {
                    Text("Coming soon")
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 45)
            .foregroundStyle(category.isAvailableInFirstSlice ? MagicPalette.parchment : .gray)
            .background(
                isSelected ? MagicPalette.teal : Color.black.opacity(0.24),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? MagicPalette.gold : Color.white.opacity(0.16), lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(category.isAvailableInFirstSlice ? (isSelected ? "Selected" : "") : "Coming soon")
    }
}

private struct FixtureCatalogCard: View {
    let definition: FixtureDefinition
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                FixtureThumbnail(kind: definition.kind)
                    .frame(height: 82)

                Text(definition.displayName)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color.black.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("Holds \(definition.stockCapacity) \(definition.stockCapacity == 1 ? "item" : "items")")
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.66))

                HStack(spacing: 6) {
                    CoinMark(size: 22)
                    Text("$\(definition.price)")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
                .foregroundStyle(MagicPalette.parchment)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .background(MagicPalette.deepTeal, in: Capsule())
                .overlay { Capsule().stroke(MagicPalette.gold, lineWidth: 2) }
            }
            .padding(12)
            .frame(width: 166)
            .background(MagicPalette.parchment, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(MagicPalette.gold.opacity(0.78), lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(definition.displayName)
        .accessibilityValue("\(definition.price) dollars. Holds \(definition.stockCapacity) \(definition.stockCapacity == 1 ? "item" : "items")")
        .accessibilityHint("Starts placement. Your balance will not change until you confirm.")
        .accessibilityIdentifier("fixture-\(definition.kind.rawValue)")
    }
}

private struct FixtureThumbnail: View {
    let kind: FixtureKind

    var body: some View {
        switch kind {
        case .basicDisplayTable:
            Image("BasicDisplayTable")
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        case .simpleShelf:
            Image("SimpleShelf")
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        }
    }
}

private struct PlacementPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if let definition = model.placementDefinition {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(definition.displayName)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(MagicPalette.parchment)
                        Text("$\(definition.price) · \(model.placementMessage ?? "")")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(model.isPlacementValid ? MagicPalette.mint : Color.orange)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    PlacementMoveMenu()
                        .environmentObject(model)

                    Button("Cancel", action: model.cancelCurrentPlacement)
                        .buttonStyle(ParchmentButtonStyle())

                    Button("Place") {
                        _ = model.confirmCurrentPlacement()
                    }
                    .buttonStyle(TealGoldButtonStyle(compact: true))
                    .disabled(!model.isPlacementValid)
                    .opacity(model.isPlacementValid ? 1 : 0.58)
                    .accessibilityHint(model.isPlacementValid
                        ? "Confirms the purchase and spends \(definition.price) dollars"
                        : (model.placementMessage ?? "Choose a valid position"))
                    .accessibilityIdentifier("confirm-placement")
                }

                if let message = model.inlineMessage {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(MagicPalette.deepTeal.opacity(0.98), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(MagicPalette.gold, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
            .accessibilityIdentifier("placement-panel")
        }
    }
}

private struct PlacementMoveMenu: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Menu {
            Button("Move toward rear wall", systemImage: "arrow.up") {
                model.movePlacement(deltaX: 0, deltaY: 1)
            }
            Button("Move toward entrance", systemImage: "arrow.down") {
                model.movePlacement(deltaX: 0, deltaY: -1)
            }
            Button("Move left", systemImage: "arrow.left") {
                model.movePlacement(deltaX: -1, deltaY: 0)
            }
            Button("Move right", systemImage: "arrow.right") {
                model.movePlacement(deltaX: 1, deltaY: 0)
            }
            Button("Rotate clockwise", systemImage: "rotate.right") {
                model.rotatePlacement()
            }
        } label: {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(MagicPalette.parchment, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Color.black.opacity(0.8))
        }
        .accessibilityLabel("Move or rotate fixture")
        .accessibilityHint("Provides an accessible alternative to tapping the floor")
    }
}

private struct BottomNavigation: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 9) {
            NavigationButton(
                title: "BUILD",
                systemImage: "hammer.fill",
                color: MagicPalette.purple,
                isActive: model.flow.route != .shop,
                action: model.openBuild
            )

            NavigationButton(
                title: "STOCK",
                systemImage: "shippingbox.fill",
                color: MagicPalette.coral,
                isEnabled: false,
                action: {}
            )
            .accessibilityHint("Not available in this version")

            NavigationButton(
                title: "OPEN",
                systemImage: "storefront.fill",
                color: MagicPalette.green,
                isEnabled: false,
                action: {}
            )
            .accessibilityHint("Not available in this version")
        }
    }
}

private struct NavigationButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var isEnabled = true
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.headline.weight(.heavy))
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(MagicPalette.parchment)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(color.opacity(isEnabled ? 0.96 : 0.48), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isActive ? Color.white : MagicPalette.gold, lineWidth: isActive ? 3 : 2)
            }
            .shadow(color: isActive ? MagicPalette.gold.opacity(0.55) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title.capitalized)
        .accessibilityValue(isEnabled ? (isActive ? "Selected" : "") : "Disabled")
    }
}

private struct CoinMark: View {
    var size: CGFloat = 28

    var body: some View {
        Text("$")
            .font(.system(size: size * 0.58, weight: .black, design: .serif))
            .foregroundStyle(Color(red: 0.52, green: 0.27, blue: 0.03))
            .frame(width: size, height: size)
            .background(MagicPalette.coin, in: Circle())
            .overlay { Circle().stroke(MagicPalette.gold, lineWidth: 2) }
            .accessibilityHidden(true)
    }
}

private struct GoldDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().frame(height: 1)
            Image(systemName: "diamond.fill").font(.caption2)
            Rectangle().frame(height: 1)
        }
        .foregroundStyle(MagicPalette.gold.opacity(0.75))
        .frame(maxWidth: 280)
        .accessibilityHidden(true)
    }
}

private struct TealGoldButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(compact ? .headline : .title2, design: .serif, weight: .bold))
            .foregroundStyle(MagicPalette.parchment)
            .padding(.horizontal, compact ? 14 : 18)
            .frame(minHeight: compact ? 46 : 54)
            .background(MagicPalette.teal.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MagicPalette.gold, lineWidth: 3)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct ParchmentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .serif, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.8))
            .padding(.horizontal, 13)
            .frame(minHeight: 46)
            .background(MagicPalette.parchment.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(MagicPalette.gold, lineWidth: 2)
            }
    }
}

private extension View {
    func hudCapsule() -> some View {
        self
            .foregroundStyle(MagicPalette.parchment)
            .padding(.horizontal, 15)
            .frame(minHeight: 48)
            .background(MagicPalette.deepTeal.opacity(0.97), in: Capsule())
            .overlay { Capsule().stroke(MagicPalette.gold, lineWidth: 3) }
            .shadow(color: .black.opacity(0.35), radius: 5, y: 3)
    }
}

private enum MagicPalette {
    static let earth = Color(red: 0.26, green: 0.21, blue: 0.15)
    static let deepTeal = Color(red: 0.035, green: 0.17, blue: 0.17)
    static let teal = Color(red: 0.08, green: 0.39, blue: 0.36)
    static let gold = Color(red: 0.88, green: 0.59, blue: 0.20)
    static let coin = Color(red: 1.0, green: 0.69, blue: 0.20)
    static let parchment = Color(red: 0.96, green: 0.89, blue: 0.74)
    static let leaf = Color(red: 0.55, green: 0.70, blue: 0.18)
    static let mint = Color(red: 0.38, green: 0.89, blue: 0.71)
    static let purple = Color(red: 0.40, green: 0.18, blue: 0.73)
    static let coral = Color(red: 0.72, green: 0.20, blue: 0.16)
    static let green = Color(red: 0.08, green: 0.47, blue: 0.40)
}
