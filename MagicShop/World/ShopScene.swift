import SpriteKit

/// The approved starter plate is retained as one sprite. Every interactive
/// point is projected onto its authored floor; no visible grid is constructed.
final class ShopScene: SKScene {
    private enum FloorCalibration {
        // Source: 853x1844 StarterShopBackground. Coordinates are normalized
        // image positions, with image Y increasing downward. This slight
        // trapezoid is the projection of the persistent square 11x11 floor.
        static let nearY: CGFloat = 1172.0 / 1844.0
        static let farY: CGFloat = 629.0 / 1844.0
        static let nearLeft: CGFloat = 106.0 / 853.0
        static let nearRight: CGFloat = 749.0 / 853.0
        static let farLeft: CGFloat = 143.0 / 853.0
        static let farRight: CGFloat = 701.0 / 853.0
    }

    private struct VisitPlan {
        let id: VisitID
        let route: [GridPoint]
        let fixtureID: UUID?
        let product: ProductKind
    }

    private final class LivingCustomerArt {
        let root = SKNode()
        let body = SKSpriteNode()
        let shadow: SKShapeNode
        let bubble = SKNode()
        let bubbleShape: SKShapeNode
        let icon = SKSpriteNode()
        let caption = SKLabelNode(fontNamed: "Georgia")
        let carried = SKSpriteNode()
        var imageName = ""
        var bubbleKey = ""

        init(tileWidth: CGFloat, tileHeight: CGFloat) {
            shadow = SKShapeNode(ellipseOf: CGSize(width: tileWidth * 0.62, height: tileHeight * 0.22))
            shadow.fillColor = SKColor(white: 0, alpha: 0.20)
            shadow.strokeColor = .clear
            shadow.zPosition = 0
            body.anchorPoint = CGPoint(x: 0.5, y: 0.045)
            body.zPosition = 1
            carried.zPosition = 2
            bubbleShape = SKShapeNode(path: Self.cloudPath(width: tileWidth * 1.85, height: tileHeight * 1.35))
            bubbleShape.fillColor = SKColor(red: 0.98, green: 0.93, blue: 0.80, alpha: 0.96)
            bubbleShape.strokeColor = SKColor(red: 0.69, green: 0.48, blue: 0.22, alpha: 0.90)
            bubbleShape.lineWidth = 0.8
            bubble.addChild(bubbleShape)
            icon.position = CGPoint(x: 0, y: tileHeight * 0.25)
            bubble.addChild(icon)
            caption.fontSize = max(7, tileWidth * 0.30)
            caption.fontColor = SKColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1)
            caption.verticalAlignmentMode = .center
            caption.position = CGPoint(x: 0, y: -tileHeight * 0.27)
            bubble.addChild(caption)
            for index in 0..<2 {
                let dot = SKShapeNode(circleOfRadius: tileHeight * (index == 0 ? 0.08 : 0.045))
                dot.fillColor = bubbleShape.fillColor
                dot.strokeColor = bubbleShape.strokeColor
                dot.lineWidth = 0.45
                dot.position = CGPoint(x: -tileWidth * (index == 0 ? 0.25 : 0.16),
                                       y: -tileHeight * (index == 0 ? 0.68 : 0.85))
                bubble.addChild(dot)
            }
            bubble.zPosition = 4
            root.addChild(shadow)
            root.addChild(body)
            root.addChild(carried)
            root.addChild(bubble)
        }
        private static func cloudPath(width: CGFloat, height: CGFloat) -> CGPath {
            let path = CGMutablePath()
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * width, y: y * height) }
            path.move(to: point(-0.38, -0.38))
            path.addCurve(to: point(-0.50, -0.05), control1: point(-0.56, -0.36), control2: point(-0.60, -0.15))
            path.addCurve(to: point(-0.34, 0.29), control1: point(-0.58, 0.16), control2: point(-0.49, 0.32))
            path.addCurve(to: point(0, 0.46), control1: point(-0.31, 0.49), control2: point(-0.10, 0.53))
            path.addCurve(to: point(0.34, 0.29), control1: point(0.17, 0.57), control2: point(0.33, 0.45))
            path.addCurve(to: point(0.50, -0.05), control1: point(0.55, 0.32), control2: point(0.60, 0.12))
            path.addCurve(to: point(0.36, -0.38), control1: point(0.59, -0.20), control2: point(0.52, -0.39))
            path.addCurve(to: point(-0.38, -0.38), control1: point(0.12, -0.48), control2: point(-0.13, -0.47))
            path.closeSubpath()
            return path
        }

    }

    private let plateEdgeShader = SKShader(source: """
        void main() {
            vec2 distanceToEdge = min(v_tex_coord, vec2(1.0) - v_tex_coord);
            vec2 feather = smoothstep(vec2(0.0), vec2(0.025, 0.09), distanceToEdge);
            gl_FragColor = texture2D(u_texture, v_tex_coord) * feather.x * feather.y;
        }
        """)
    private let environmentRoot = SKNode()
    private let floorRoot = SKNode()
    private let floorPreviewRoot = SKNode()
    private let dirtRoot = SKNode()
    private let furnitureRoot = SKNode()
    private let previewRoot = SKNode()
    private let customerRoot = SKNode()
    private let livingRoot = SKNode()
    private let feedbackRoot = SKNode()
    private let worldCamera = SKCameraNode()
    private var textures: [String: SKTexture] = [:]
    private var renderedState = GameState.initial
    private var renderedPreview: PlacementDraft?
    private var renderedFloorPreview: [GridPoint] = []
    private var renderedFloorPreviewStyle: FloorStyleID?
    private var renderedPreviewValid = false
    private var selectedFixtureID: UUID?
    private var reducedMotion = false
    private var presentationPaused = false
    private var animatesInsertions: Bool { !reducedMotion && !presentationPaused }
    private var needsFirstRender = true
    private var insertedFixtureIDs = Set<UUID>()
    private var insertedStockIDs = Set<UUID>()
    private var visitPlan: VisitPlan?
    private var targetProgress = 0.0
    private var displayedProgress = 0.0
    private var currentOutcome: VisitOutcome?
    private var displayedOutcomeID: VisitID?
    private var customerSprite: SKSpriteNode?
    private var customerFacingOut = false
    private var customerShadow: SKShapeNode?
    private var thoughtNode: SKNode?
    private var carriedProduct: SKSpriteNode?
    private var glowNodes: [SKShapeNode] = []
    private var livingDayID: UUID?
    private var livingCustomers: [VisitID: LivingCustomerArt] = [:]
    private var handledLivingOutcomes = Set<VisitID>()
    private var targetLivingMinute = 540.0
    private var displayedLivingMinute = 540.0
    private var lastFrameTime: TimeInterval?
    private var cameraState = WorldCameraState()
    private var horizontalOffset: CGFloat = 0
    private var contentLift: CGFloat = 0

    private var starterOrigin: GridPoint {
        renderedState.restoration.expansion?.starterOrigin ?? GridPoint(x: 0, y: 0)
    }

    /// Pixel-space bounds use the same authored floor landmarks as project().
    /// They include the wall height independently of the five floor rows.
    private var expandedArchitectureBounds: CGRect? {
        guard let expansion = renderedState.restoration.expansion else { return nil }
        func floorPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            let depth = y / 11
            let left = 106 + 37 * depth, right = 749 - 48 * depth
            return CGPoint(x: left + (right - left) * x / 11 - 426.5,
                           y: 922 - (1172 - 543 * depth))
        }
        let x = CGFloat(expansion.roomOrigin.x - expansion.starterOrigin.x)
        let y = CGFloat(expansion.roomOrigin.y)
        let nearLeft = floorPoint(x, y), nearRight = floorPoint(x + 5, y)
        let farLeft = floorPoint(x, y + 5), farRight = floorPoint(x + 5, y + 5)
        // Original exterior, then annex wall thickness/caps. The facade below
        // the floor may continue beneath the controls, as in the starter view.
        return bounds(of: [CGPoint(x: -405, y: -264), CGPoint(x: 405, y: 535),
                           CGPoint(x: nearLeft.x - 18, y: nearLeft.y - 14),
                           CGPoint(x: nearRight.x + 18, y: nearRight.y - 14),
                           CGPoint(x: farLeft.x - 46, y: farLeft.y + 240),
                           CGPoint(x: farRight.x + 46, y: farRight.y + 240)])
    }

    private var backgroundSize: CGSize {
        let original = texture("StarterShopBackground").size()
        guard original.width > 0, original.height > 0, size.width > 0, size.height > 0 else { return size }
        var scale = max(size.width / original.width, size.height / original.height)
        if let architecture = expandedArchitectureBounds {
            scale = min(scale, min(max(1, size.width - 24) / architecture.width,
                            max(1, size.height * 0.43) / architecture.height))
        }
        return CGSize(width: original.width * scale, height: original.height * scale)
    }

    private var tileWidth: CGFloat {
        backgroundSize.width * (FloorCalibration.nearRight - FloorCalibration.nearLeft
            + FloorCalibration.farRight - FloorCalibration.farLeft) / 22
    }

    private var tileHeight: CGFloat {
        backgroundSize.height * (FloorCalibration.nearY - FloorCalibration.farY) / 11
    }

    private var architecturalCameraCenter: CGPoint {
        guard let architecture = expandedArchitectureBounds else { return .zero }
        let scale = backgroundSize.width / 853
        // Reserve the upper HUD and the lower preparation card. In particular,
        // the rear room's cap must not be framed beneath the calendar.
        return CGPoint(x: architecture.midX * scale,
                       y: architecture.midY * scale - size.height * 0.06)
    }

    var horizontalPanLimit: CGFloat { max(70, backgroundSize.width * 0.46) }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.25, green: 0.20, blue: 0.14, alpha: 1)
        for node in [environmentRoot, floorRoot, floorPreviewRoot, dirtRoot, furnitureRoot, previewRoot, customerRoot, livingRoot, feedbackRoot] {
            addChild(node)
        }
        addChild(worldCamera)
        camera = worldCamera
    }

    required init?(coder aDecoder: NSCoder) { nil }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard !needsFirstRender, size.width > 0, size.height > 0 else { return }
        rebuildEnvironment()
        rebuildFloorCare()
        rebuildFloorPreview()
        rebuildDirt()
        rebuildFurniture()
        rebuildPreview()
        rebuildCustomer()
        prepareLivingDay(presentationMinute: targetLivingMinute, rebuild: true)
        apply(cameraState, horizontalOffset: horizontalOffset, contentLift: contentLift)
    }

    func apply(_ cameraState: WorldCameraState, horizontalOffset: CGFloat = 0, contentLift: CGFloat = 0) {
        self.cameraState = cameraState
        self.horizontalOffset = horizontalOffset
        self.contentLift = contentLift
        let zoom = CGFloat(cameraState.zoom)
        worldCamera.setScale(zoom)
        var position = architecturalCameraCenter
        position.y -= contentLift * zoom
        if renderedState.restoration.expansion != nil, contentLift > 0,
           let selectedFixtureID,
           renderedPreview == nil || renderedPreview?.fixtureID == selectedFixtureID,
           let fixture = renderedState.fixtures.first(where: { $0.id == selectedFixtureID }) {
            // Correct the automatic panel lift before applying the user's pan.
            // Otherwise a selected rear-room display moves behind the HUD.
            // Keep the persisted anchor during an existing-fixture drag so
            // the camera and finger-to-cell mapping do not jump at touch-down.
            let item = center(of: fixture.origin)
            let screenY = size.height * 0.5 - (item.y + tileHeight * 0.55 - position.y) / zoom
            let visibleY = min(max(screenY, size.height * 0.28), size.height * 0.47)
            position.y += (visibleY - screenY) * zoom
        }
        position.x += horizontalOffset
        position.y += CGFloat(cameraState.verticalOffset)
        worldCamera.position = position
    }

    func render(
        state: GameState,
        preview: PlacementDraft?,
        previewIsValid: Bool,
        selectedFixtureID: UUID?,
        activeVisit: CustomerVisit?,
        visitProgress: Double,
        lastOutcome: VisitOutcome?,
        reduceMotion: Bool,
        presentationPaused: Bool = false,
        presentationMinute: Double? = nil,
        floorPreview: [GridPoint] = [],
        floorPreviewStyle: FloorStyleID? = nil
    ) {
        insertedFixtureIDs = needsFirstRender ? [] : Set(state.fixtures.map(\.id)).subtracting(Set(renderedState.fixtures.map(\.id)))
        insertedStockIDs = needsFirstRender ? [] : Set(state.stock.map(\.id)).subtracting(Set(renderedState.stock.map(\.id)))
        let environmentChanged = needsFirstRender || state.world != renderedState.world
            || state.restoration != renderedState.restoration
            || state.manualRepairProgress != renderedState.manualRepairProgress
        let floorPreviewChanged = environmentChanged || floorPreview != renderedFloorPreview
            || floorPreviewStyle != renderedFloorPreviewStyle
        let dirtChanged = environmentChanged || state.dirt != renderedState.dirt
        let furnitureChanged = environmentChanged || preview?.fixtureID != renderedPreview?.fixtureID || state.fixtures != renderedState.fixtures
            || state.stock != renderedState.stock || self.selectedFixtureID != selectedFixtureID
            || reducedMotion != reduceMotion
            // Finish any insertion that was in flight before SpriteKit pauses.
            || (presentationPaused && !self.presentationPaused)
        let previewChanged = environmentChanged || preview != renderedPreview
            || previewIsValid != renderedPreviewValid || reducedMotion != reduceMotion
        let motionChanged = reducedMotion != reduceMotion
        renderedState = state
        renderedPreview = preview
        renderedFloorPreview = floorPreview
        renderedFloorPreviewStyle = floorPreviewStyle
        renderedPreviewValid = previewIsValid
        self.selectedFixtureID = selectedFixtureID
        reducedMotion = reduceMotion
        if self.presentationPaused != presentationPaused { lastFrameTime = nil }
        self.presentationPaused = presentationPaused
        // Pause actions on the scene tree, not SKView's framebuffer. Direct
        // stock, cleaning and camera changes must still be drawn while paused.
        isPaused = presentationPaused
        needsFirstRender = false

        if motionChanged { feedbackRoot.removeAllChildren() }
        if environmentChanged { rebuildEnvironment(); rebuildFloorCare() }
        if floorPreviewChanged { rebuildFloorPreview() }
        if dirtChanged { rebuildDirt() }
        if furnitureChanged { rebuildFurniture() }
        if previewChanged { rebuildPreview() }

        let legacyVisit = state.livingDay == nil ? activeVisit : nil
        if visitPlan?.id != legacyVisit?.id {
            if let visit = legacyVisit {
                visitPlan = makeVisitPlan(visit, outcome: lastOutcome)
                displayedProgress = max(0, min(1, visitProgress))
            } else {
                visitPlan = nil
                displayedProgress = 0
            }
            rebuildCustomer()
        } else if environmentChanged || motionChanged {
            rebuildCustomer()
        }
        prepareLivingDay(presentationMinute: presentationMinute, rebuild: environmentChanged || motionChanged)
        targetProgress = visitProgress.isFinite ? max(0, min(1, visitProgress)) : 0
        currentOutcome = lastOutcome?.visitID == legacyVisit?.id ? lastOutcome : nil
        updateCustomer(progress: reducedMotion ? targetProgress : displayedProgress)

        if let outcome = currentOutcome, outcome.visitID != displayedOutcomeID {
            displayedOutcomeID = outcome.visitID
            showOutcome(outcome)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard !presentationPaused else {
            lastFrameTime = nil
            return
        }
        let delta = min(0.1, max(0, currentTime - (lastFrameTime ?? currentTime)))
        lastFrameTime = currentTime
        if reducedMotion {
            displayedProgress = targetProgress
        } else {
            displayedProgress += (targetProgress - displayedProgress) * min(1, delta * 24)
        }
        if reducedMotion { displayedLivingMinute = targetLivingMinute }
        else { displayedLivingMinute += (targetLivingMinute - displayedLivingMinute) * min(1, delta * 20) }
        updateLivingCustomers(at: displayedLivingMinute)
        updateCustomer(progress: displayedProgress)
        let warmth = reducedMotion ? 0.035 : 0.035 + 0.009 * sin(currentTime * 1.8)
        for glow in glowNodes { glow.alpha = CGFloat(warmth) }
    }

    // MARK: - Authored floor projection

    private func project(x: CGFloat, y: CGFloat) -> CGPoint {
        let localX = x - CGFloat(starterOrigin.x)
        let localY = y - CGFloat(starterOrigin.y)
        let depth = localY / 11
        let left = FloorCalibration.nearLeft + (FloorCalibration.farLeft - FloorCalibration.nearLeft) * depth
        let right = FloorCalibration.nearRight + (FloorCalibration.farRight - FloorCalibration.nearRight) * depth
        let imageX = left + (right - left) * localX / 11
        let imageY = FloorCalibration.nearY + (FloorCalibration.farY - FloorCalibration.nearY) * depth
        return CGPoint(x: (imageX - 0.5) * backgroundSize.width,
                       y: (0.5 - imageY) * backgroundSize.height)
    }

    private func center(of point: GridPoint) -> CGPoint {
        project(x: CGFloat(point.x) + 0.5, y: CGFloat(point.y) + 0.5)
    }

    func gridPoint(fromWorldPoint point: WorldPoint) -> GridPoint? {
        guard backgroundSize.width > 0, backgroundSize.height > 0 else { return nil }
        let imageX = CGFloat(point.x) / backgroundSize.width + 0.5
        let imageY = 0.5 - CGFloat(point.y) / backgroundSize.height
        let depth = (imageY - FloorCalibration.nearY) / (FloorCalibration.farY - FloorCalibration.nearY)
        let left = FloorCalibration.nearLeft + (FloorCalibration.farLeft - FloorCalibration.nearLeft) * depth
        let right = FloorCalibration.nearRight + (FloorCalibration.farRight - FloorCalibration.nearRight) * depth
        guard right > left else { return nil }
        let x = (imageX - left) / (right - left) * 11 + CGFloat(starterOrigin.x)
        let y = depth * 11 + CGFloat(starterOrigin.y)
        let layout = renderedState.world.hitMap.layout
        guard x.isFinite, y.isFinite, x >= 0, y >= 0,
              x < CGFloat(layout.width), y < CGFloat(layout.depth) else { return nil }
        let cell = GridPoint(x: Int(floor(x)), y: Int(floor(y)))
        guard let metadata = renderedState.world.hitMap.cell(at: cell), metadata.zone != .outside else { return nil }
        return cell
    }

    /// Unbounded inverse used only by drag previews. Invalid drops remain
    /// invalid instead of silently sticking to the last valid floor cell.
    func dragGridPoint(at point: CGPoint) -> GridPoint? {
        guard backgroundSize.width > 0, backgroundSize.height > 0 else { return nil }
        let imageX = point.x / backgroundSize.width + 0.5
        let imageY = 0.5 - point.y / backgroundSize.height
        let depth = (imageY - FloorCalibration.nearY) / (FloorCalibration.farY - FloorCalibration.nearY)
        let left = FloorCalibration.nearLeft + (FloorCalibration.farLeft - FloorCalibration.nearLeft) * depth
        let right = FloorCalibration.nearRight + (FloorCalibration.farRight - FloorCalibration.nearRight) * depth
        guard right > left else { return nil }
        let x = (imageX - left) / (right - left) * 11 + CGFloat(starterOrigin.x)
        let y = depth * 11 + CGFloat(starterOrigin.y)
        guard x.isFinite, y.isFinite, abs(x) < 10_000, abs(y) < 10_000 else { return nil }
        return GridPoint(x: Int(floor(x)), y: Int(floor(y)))
    }

    func previewContains(_ point: CGPoint) -> Bool {
        guard renderedPreview != nil else { return false }
        return nodes(at: point).contains { hit in
            var node: SKNode? = hit
            while let candidate = node {
                if candidate === previewRoot { return true }
                node = candidate.parent
            }
            return false
        }
    }

    func accessibilityCellFrames() -> [(GridPoint, CGRect)] {
        renderedState.world.hitMap.cells.filter { $0.zone != .outside }.map {
            let corners = footprintCorners(origin: $0.point, footprint: GridFootprint(width: 1, depth: 1))
            return ($0.point, viewRect(for: bounds(of: corners)))
        }
    }

    func accessibilityFixtureFrames() -> [(UUID, CGRect)] {
        furnitureRoot.children.compactMap { node in
            guard let name = node.name, name.hasPrefix("fixture:"),
                  let id = UUID(uuidString: String(name.dropFirst(8))) else { return nil }
            return (id, viewRect(for: node.calculateAccumulatedFrame()))
        }
    }

    /// Read the actual presentation node so accessibility never describes an
    /// invisible, paused insertion as already displayed. The value is queried
    /// live, including when an ordinary insertion finishes between App updates.
    func accessibilityStockValue(for fixtureID: UUID) -> String? {
        guard let fixture = renderedState.fixtures.first(where: { $0.id == fixtureID }),
              FixtureCatalog.definition(for: fixture.kind).stockCapacity > 0,
              let group = furnitureRoot.childNode(withName: "fixture:\(fixtureID.uuidString)") else { return nil }
        let units = renderedState.stock.filter { $0.fixtureID == fixtureID }
            .sorted { $0.slotIndex < $1.slotIndex }
        guard !units.isEmpty else { return "Empty display" }
        return units.map { unit in
            let node = group.childNode(withName: "stock:\(unit.id.uuidString)")
            let displayed = node.map {
                !$0.isHidden && !group.isHidden && $0.alpha * group.alpha >= 0.99
                    && abs($0.xScale * group.xScale) >= 0.99
            } ?? false
            return ProductCatalog.definition(for: unit.product).displayName
                + (displayed ? " displayed" : " arriving")
        }.joined(separator: ", ")
    }

    func accessibilityPreviewFrame() -> CGRect? {
        guard !previewRoot.children.isEmpty else { return nil }
        return viewRect(for: previewRoot.calculateAccumulatedFrame())
    }

    private func viewRect(for rect: CGRect) -> CGRect {
        let first = convertPoint(toView: CGPoint(x: rect.minX, y: rect.minY))
        let second = convertPoint(toView: CGPoint(x: rect.maxX, y: rect.maxY))
        return CGRect(x: min(first.x, second.x), y: min(first.y, second.y),
                      width: abs(second.x - first.x), height: abs(second.y - first.y))
    }

    func fixtureID(at point: CGPoint) -> UUID? {
        for hitNode in nodes(at: point) {
            var candidate: SKNode? = hitNode
            while let node = candidate {
                if let name = node.name, name.hasPrefix("fixture:"),
                   let id = UUID(uuidString: String(name.dropFirst(8))) { return id }
                candidate = node.parent
            }
        }
        guard let cell = gridPoint(fromWorldPoint: WorldPoint(x: Double(point.x), y: Double(point.y))) else { return nil }
        return renderedState.world.hitMap.dynamicOccupancy(fixtures: renderedState.fixtures)[cell]
    }

    private func footprintCorners(origin: GridPoint, footprint: GridFootprint) -> [CGPoint] {
        let x = CGFloat(origin.x), y = CGFloat(origin.y)
        let width = CGFloat(footprint.width), depth = CGFloat(footprint.depth)
        return [project(x: x, y: y), project(x: x + width, y: y),
                project(x: x + width, y: y + depth), project(x: x, y: y + depth)]
    }

    private func polygon(_ corners: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = corners.first else { return path }
        path.move(to: first)
        for point in corners.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    private func bounds(of corners: [CGPoint]) -> CGRect {
        let xs = corners.map(\.x), ys = corners.map(\.y)
        return CGRect(x: xs.min() ?? 0, y: ys.min() ?? 0,
                      width: (xs.max() ?? 0) - (xs.min() ?? 0),
                      height: (ys.max() ?? 0) - (ys.min() ?? 0))
    }

    // MARK: - Environment and finite restoration

    private func rebuildEnvironment() {
        environmentRoot.removeAllChildren()
        addGroundBackdrop()
        let fullyRepaired = renderedState.restoration.repairedGroups.count == RestorationGroupID.allCases.count
        let background = SKSpriteNode(texture: texture(fullyRepaired ? "RepairedShopBackground" : "StarterShopBackground"))
        background.size = backgroundSize
        background.zPosition = -100
        background.shader = renderedState.restoration.expansion == nil ? nil : plateEdgeShader
        if let expansion = renderedState.restoration.expansion {
            let openedPlate = SKCropNode()
            background.zPosition = 0
            openedPlate.addChild(background)
            openedPlate.maskNode = makeOpenedPlateMask(expansion)
            openedPlate.zPosition = -100
            environmentRoot.addChild(openedPlate)
        } else {
            environmentRoot.addChild(background)
        }

        if !fullyRepaired {
            for group in RestorationGroupID.allCases where renderedState.repairProgress(for: group) > 0 {
                addRepairPatch(group)
            }
        }
        if let expansion = renderedState.restoration.expansion { addAnnex(expansion) }
    }

    private func addGroundBackdrop() {
        let earth = SKTexture(rect: CGRect(x: 0.05, y: 0.80, width: 0.9, height: 0.18),
                              in: texture("StarterShopBackground"))
        let backdrop = SKSpriteNode(texture: earth)
        backdrop.size = CGSize(width: size.width * 4, height: size.height * 4)
        backdrop.zPosition = -110
        environmentRoot.addChild(backdrop)
    }

    private func addRepairPatch(_ group: RestorationGroupID) {
        let sourceRect: CGRect
        switch group {
        case .rubble: sourceRect = CGRect(x: 145, y: 870, width: 105, height: 105)
        case .brokenBoards: sourceRect = CGRect(x: 585, y: 882, width: 124, height: 78)
        case .discardedPapers: sourceRect = CGRect(x: 599, y: 977, width: 92, height: 115)
        }
        let crop = SKCropNode()
        let patch = SKSpriteNode(texture: texture("RepairedShopBackground"))
        patch.size = backgroundSize
        crop.addChild(patch)
        let mask = SKNode()
        let patchCenter = CGPoint(x: (sourceRect.midX / 853 - 0.5) * backgroundSize.width,
                                  y: (0.5 - sourceRect.midY / 1844) * backgroundSize.height)
        let patchSize = CGSize(width: sourceRect.width / 853 * backgroundSize.width,
                               height: sourceRect.height / 1844 * backgroundSize.height)
        // Native alpha feather avoids a hard rectangular repair seam.
        for inset in 0..<6 {
            let amount = CGFloat(inset)
            let shape = SKShapeNode(rectOf: CGSize(width: max(1, patchSize.width - amount * 1.5),
                                                  height: max(1, patchSize.height - amount * 1.5)),
                                    cornerRadius: max(1, 7 - amount))
            shape.fillColor = .white
            shape.strokeColor = .clear
            shape.alpha = inset == 5 ? 1 : 0.13
            shape.position = patchCenter
            mask.addChild(shape)
        }
        crop.maskNode = mask
        crop.alpha = CGFloat(renderedState.repairProgress(for: group)) / CGFloat(ShopCare.repairStrokesRequired)
        crop.zPosition = -95
        environmentRoot.addChild(crop)
    }

    private func imagePoint(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: (x / 853 - 0.5) * backgroundSize.width,
                y: (0.5 - y / 1844) * backgroundSize.height)
    }

    private func makeOpenedPlateMask(_ expansion: ExpansionState) -> SKShapeNode {
        let opening: [CGPoint]
        switch expansion.direction {
        case .left, .right:
            let leftSide = expansion.direction == .left
            func edge(_ depth: CGFloat, outer: Bool) -> CGPoint {
                let t = depth / 11
                let x: CGFloat
                if leftSide { x = outer ? 32 + 56 * t : 106 + 37 * t }
                else { x = outer ? 822 - 57 * t : 749 - 48 * t }
                let y = 1172 - (outer ? 767 : 543) * t
                return imagePoint(x: x, y: y)
            }
            opening = [edge(3, outer: false), edge(8, outer: false),
                       edge(8, outer: true), edge(3, outer: true)]
        case .rear:
            // The full painted rear wall, including its cap and baked lamp,
            // is removed across the same five cells as the persisted opening.
            opening = [imagePoint(x: 143 + 558 * 3 / 11, y: 629),
                       imagePoint(x: 143 + 558 * 8 / 11, y: 629),
                       imagePoint(x: 105 + 620 * 8 / 11, y: 402),
                       imagePoint(x: 105 + 620 * 3 / 11, y: 402)]
        }
        let path = CGMutablePath()
        let width = backgroundSize.width * 0.5, height = backgroundSize.height * 0.5
        path.addPath(polygon([CGPoint(x: -width, y: -height), CGPoint(x: width, y: -height),
                              CGPoint(x: width, y: height), CGPoint(x: -width, y: height)]))
        var hole = opening
        let area = hole.indices.reduce(CGFloat.zero) { value, index in
            let next = hole[(index + 1) % hole.count]
            return value + hole[index].x * next.y - next.x * hole[index].y
        }
        if area > 0 { hole.reverse() }
        // Opposite winding cuts an actual alpha hole, rather than painting
        // another floor strip over an upright wall.
        path.addPath(polygon(hole))
        let mask = SKShapeNode(path: path)
        mask.fillColor = .white
        mask.strokeColor = .clear
        return mask
    }

    /// Corners are bottom-left, bottom-right, top-right, top-left in the source
    /// material. World projection is independent for each horizontal/vertical plane.
    private func texturedQuad(_ image: SKTexture, corners: [CGPoint], shade: CGFloat = 0) -> SKSpriteNode {
        let rect = bounds(of: corners)
        let sprite = SKSpriteNode(texture: image)
        sprite.size = rect.size
        sprite.position = CGPoint(x: rect.midX, y: rect.midY)
        guard rect.width > 0, rect.height > 0 else { return sprite }
        let source: [SIMD2<Float>] = [SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1), SIMD2(1, 1)]
        let destination = [corners[0], corners[1], corners[3], corners[2]].map {
            SIMD2<Float>(Float(($0.x - rect.minX) / rect.width), Float(($0.y - rect.minY) / rect.height))
        }
        sprite.warpGeometry = SKWarpGeometryGrid(columns: 1, rows: 1,
                                                 sourcePositions: source, destinationPositions: destination)
        sprite.color = SKColor(red: 0.28, green: 0.22, blue: 0.14, alpha: 1)
        sprite.colorBlendFactor = shade
        return sprite
    }

    private var annexWallHeight: CGFloat { backgroundSize.height * 224 / 1844 }
    private var paintedScale: CGFloat { backgroundSize.width / 853 }
    private var annexFaceHeight: CGFloat { annexWallHeight - paintedScale * 38 }

    private func paintedTexture(_ rect: CGRect) -> SKTexture {
        SKTexture(rect: CGRect(x: rect.minX / 853, y: 1 - rect.maxY / 1844,
                               width: rect.width / 853, height: rect.height / 1844),
                  in: texture("RepairedShopBackground"))
    }

    private func annexSideHeight(at depth: CGFloat, expansion: ExpansionState) -> CGFloat {
        if expansion.direction == .rear { return annexFaceHeight }
        let t = min(1, max(0, (depth - CGFloat(expansion.roomOrigin.y)) / 5))
        return tileHeight * 0.22 + (annexFaceHeight - tileHeight * 0.22) * t
    }

    private func makePaintedAnnexFloor(_ expansion: ExpansionState) -> SKCropNode {
        // The authored plate contains about six painted tiles per five domain
        // cells. Preserve that decorative frequency and its rounded tile edges.
        let sourceRect = CGRect(x: 284, y: 776, width: 284, height: 249)
        let divisions = 8
        var source: [SIMD2<Float>] = []
        var projected: [CGPoint] = []
        for row in 0...divisions {
            for column in 0...divisions {
                let u = CGFloat(column) / CGFloat(divisions), v = CGFloat(row) / CGFloat(divisions)
                let imageX = (sourceRect.minX + u * sourceRect.width) / 853
                let imageY = (sourceRect.maxY - v * sourceRect.height) / 1844
                let depth = (imageY - FloorCalibration.nearY) / (FloorCalibration.farY - FloorCalibration.nearY)
                let left = FloorCalibration.nearLeft + (FloorCalibration.farLeft - FloorCalibration.nearLeft) * depth
                let right = FloorCalibration.nearRight + (FloorCalibration.farRight - FloorCalibration.nearRight) * depth
                let floorX = (imageX - left) / (right - left) * 11
                source.append(SIMD2(Float(u), Float(v)))
                projected.append(project(x: CGFloat(expansion.roomOrigin.x) + floorX - 3,
                                         y: CGFloat(expansion.roomOrigin.y) + depth * 11 - 3))
            }
        }
        let rect = bounds(of: projected)
        let destination = projected.map {
            SIMD2<Float>(Float(($0.x - rect.minX) / rect.width), Float(($0.y - rect.minY) / rect.height))
        }
        let sprite = SKSpriteNode(texture: paintedTexture(sourceRect))
        sprite.size = rect.size
        sprite.position = CGPoint(x: rect.midX, y: rect.midY)
        sprite.warpGeometry = SKWarpGeometryGrid(columns: divisions, rows: divisions,
                                                 sourcePositions: source, destinationPositions: destination)
        sprite.color = SKColor(red: 0.36, green: 0.26, blue: 0.16, alpha: 1)
        sprite.colorBlendFactor = 0.06
        let crop = SKCropNode()
        crop.addChild(sprite)
        let mask = SKShapeNode(path: polygon(footprintCorners(origin: expansion.roomOrigin,
                                                            footprint: GridFootprint(width: 5, depth: 5))))
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        return crop
    }

    private func addAnnex(_ expansion: ExpansionState) {
        let x = CGFloat(expansion.roomOrigin.x), y = CGFloat(expansion.roomOrigin.y)
        let leftOpen = expansion.direction == .right
        let rightOpen = expansion.direction == .left
        let floor = makePaintedAnnexFloor(expansion)
        floor.zPosition = -92
        environmentRoot.addChild(floor)

        // The crop retains the original warm plaster, top contact shadow,
        // shaded rail and wainscot. It deliberately excludes the baked lamp.
        let wallMaterial = paintedTexture(CGRect(x: 148, y: 446, width: 245, height: 183))
        let backLeft = project(x: x, y: y + 5), backRight = project(x: x + 5, y: y + 5)
        let topLeft = CGPoint(x: backLeft.x - (leftOpen ? 0 : annexFaceHeight * 0.14),
                              y: backLeft.y + annexFaceHeight)
        let topRight = CGPoint(x: backRight.x + (rightOpen ? 0 : annexFaceHeight * 0.14),
                               y: backRight.y + annexFaceHeight)
        let wall = texturedQuad(wallMaterial, corners: [backLeft, backRight, topRight, topLeft])
        wall.zPosition = -91
        environmentRoot.addChild(wall)
        addWallCap(innerStart: topLeft, innerEnd: topRight,
                   outerStart: CGPoint(x: topLeft.x, y: topLeft.y + 1),
                   outerEnd: CGPoint(x: topRight.x, y: topRight.y + 1))
        addContactShadow(from: backLeft, to: backRight)

        for side in [WallSide.left, .right] {
            guard !(side == .left && leftOpen), !(side == .right && rightOpen) else { continue }
            let edgeX = side == .left ? x : x + 5
            let sign: CGFloat = side == .left ? -1 : 1
            let near = project(x: edgeX, y: y), far = project(x: edgeX, y: y + 5)
            let nearHeight = annexSideHeight(at: y, expansion: expansion)
            let nearTop = CGPoint(x: near.x + sign * nearHeight * 0.14, y: near.y + nearHeight)
            let farTop = side == .left ? topLeft : topRight
            let face = texturedQuad(wallMaterial, corners: [near, far, farTop, nearTop], shade: 0.07)
            face.zPosition = -90
            environmentRoot.addChild(face)
            addWallCap(innerStart: nearTop, innerEnd: farTop,
                       outerStart: CGPoint(x: nearTop.x + sign, y: nearTop.y),
                       outerEnd: CGPoint(x: farTop.x + sign, y: farTop.y))
            addPaintedCorner(at: farTop, right: side == .right, front: false)
            addContactShadow(from: near, to: far)
        }
        if expansion.direction != .rear {
            let nearLeft = project(x: x, y: y), nearRight = project(x: x + 5, y: y)
            let capLeft = CGPoint(x: nearLeft.x, y: nearLeft.y + tileHeight * 0.22)
            let capRight = CGPoint(x: nearRight.x, y: nearRight.y + tileHeight * 0.22)
            addWallCap(innerStart: capLeft, innerEnd: capRight,
                       outerStart: CGPoint(x: capLeft.x, y: capLeft.y - 1),
                       outerEnd: CGPoint(x: capRight.x, y: capRight.y - 1))
            addPaintedCorner(at: leftOpen ? capRight : capLeft, right: leftOpen, front: true)
        }
        addAnnexThreshold(expansion)
        addAnnexJambs(expansion)
    }

    private func addWallCap(innerStart: CGPoint, innerEnd: CGPoint, outerStart: CGPoint, outerEnd: CGPoint) {
        let dx = innerEnd.x - innerStart.x, dy = innerEnd.y - innerStart.y
        let length = max(0.001, hypot(dx, dy))
        var normal = CGPoint(x: -dy / length, y: dx / length)
        let expected = CGPoint(x: outerStart.x - innerStart.x, y: outerStart.y - innerStart.y)
        if normal.x * expected.x + normal.y * expected.y < 0 { normal.x *= -1; normal.y *= -1 }
        let thickness = paintedScale * 38
        let farStart = CGPoint(x: innerStart.x + normal.x * thickness, y: innerStart.y + normal.y * thickness)
        let farEnd = CGPoint(x: innerEnd.x + normal.x * thickness, y: innerEnd.y + normal.y * thickness)
        let cap = texturedQuad(paintedTexture(CGRect(x: 148, y: 406, width: 546, height: 40)),
                               corners: [innerStart, innerEnd, farEnd, farStart])
        cap.zPosition = -87
        environmentRoot.addChild(cap)
    }

    private func addPaintedCorner(at point: CGPoint, right: Bool, front: Bool) {
        // Real painted corner pixels retain the rounded moulding, highlight and
        // dark fascia. A curved alpha mask removes the original earth/floor.
        let rect = front ? CGRect(x: 30, y: 1117, width: 80, height: 91)
                         : CGRect(x: 83, y: 405, width: 70, height: 78)
        let anchor = front ? CGPoint(x: 104, y: 1172) : CGPoint(x: 145, y: 446)
        let sign: CGFloat = right ? -1 : 1
        let shift: CGFloat = front ? 24 : 22
        func convert(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: point.x + sign * (x - anchor.x + shift) * paintedScale,
                    y: point.y - (y - anchor.y) * paintedScale)
        }
        let corners = [convert(rect.minX, rect.maxY), convert(rect.maxX, rect.maxY),
                       convert(rect.maxX, rect.minY), convert(rect.minX, rect.minY)]
        let sprite = texturedQuad(paintedTexture(rect), corners: corners)
        let path = CGMutablePath()
        if front {
            path.move(to: convert(34, 1117))
            path.addLine(to: convert(31, 1163))
            path.addCurve(to: convert(63, 1207), control1: convert(27, 1193), control2: convert(38, 1207))
            path.addLine(to: convert(108, 1207)); path.addLine(to: convert(108, 1171))
            path.addLine(to: convert(85, 1169))
            path.addCurve(to: convert(61, 1141), control1: convert(64, 1168), control2: convert(58, 1158))
            path.addLine(to: convert(64, 1117))
        } else {
            path.move(to: convert(153, 405)); path.addLine(to: convert(125, 405))
            path.addCurve(to: convert(86, 446), control1: convert(100, 405), control2: convert(88, 418))
            path.addLine(to: convert(83, 483)); path.addLine(to: convert(112, 483))
            path.addLine(to: convert(115, 461))
            path.addCurve(to: convert(145, 446), control1: convert(116, 449), control2: convert(129, 446))
            path.addLine(to: convert(153, 446))
        }
        path.closeSubpath()
        let mask = SKShapeNode(path: path)
        mask.fillColor = .white; mask.strokeColor = .clear
        let crop = SKCropNode()
        crop.maskNode = mask; crop.addChild(sprite)
        crop.zPosition = -86
        environmentRoot.addChild(crop)
    }

    private func addContactShadow(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start); path.addLine(to: end)
        let shadow = SKShapeNode(path: path)
        shadow.strokeColor = SKColor(red: 0.13, green: 0.10, blue: 0.06, alpha: 0.14)
        shadow.lineWidth = max(1, tileHeight * 0.13)
        shadow.glowWidth = tileHeight * 0.12
        shadow.zPosition = -84
        environmentRoot.addChild(shadow)
    }
    private func addAnnexThreshold(_ expansion: ExpansionState) {
        let corners: [CGPoint]
        switch expansion.direction {
        case .left:
            let x = CGFloat(expansion.starterOrigin.x)
            corners = [project(x: x - 0.12, y: 3), project(x: x + 0.12, y: 3),
                       project(x: x + 0.12, y: 8), project(x: x - 0.12, y: 8)]
        case .right:
            corners = [project(x: 10.88, y: 3), project(x: 11.12, y: 3),
                       project(x: 11.12, y: 8), project(x: 10.88, y: 8)]
        case .rear:
            corners = [project(x: 3, y: 10.88), project(x: 8, y: 10.88),
                       project(x: 8, y: 11.12), project(x: 3, y: 11.12)]
        }
        let threshold = texturedQuad(texture("AnnexThresholdStone"), corners: corners, shade: 0.12)
        // Architectural trim sits above floor overrides but below dirt/fixtures.
        threshold.zPosition = -82
        environmentRoot.addChild(threshold)
    }

    private func addAnnexJambs(_ expansion: ExpansionState) {
        // Painted posts stay wholly outside the five-cell opening. Their alpha
        // already includes the shaped cap, inset plaster panel and teal foot.
        let posts: [(CGPoint, Bool, Bool)]
        switch expansion.direction {
        case .left:
            let x = CGFloat(expansion.starterOrigin.x)
            posts = [(project(x: x, y: 8), true, false), (project(x: x, y: 3), true, true)]
        case .right:
            posts = [(project(x: 11, y: 8), false, false), (project(x: 11, y: 3), false, true)]
        case .rear:
            posts = [(project(x: 3, y: 11), true, false), (project(x: 8, y: 11), false, false)]
        }
        for (position, onLeft, low) in posts {
            let image = low ? SKTexture(rect: CGRect(x: 0, y: 0.79, width: 1, height: 0.21),
                                       in: texture("FacadeCornerPost")) : texture("FacadeCornerPost")
            let post = SKSpriteNode(texture: image)
            setUniformHeight(low ? paintedScale * 38 : annexWallHeight, on: post)
            post.anchorPoint = CGPoint(x: onLeft ? 1 : 0, y: 0)
            post.position = position
            post.zPosition = -83
            environmentRoot.addChild(post)
        }
    }
    // MARK: - Persisted floor care

    private func rebuildFloorCare() {
        floorRoot.removeAllChildren()
        for tile in renderedState.world.floor.tiles where tile.styleID != .wornTerracotta {
            guard let cell = renderedState.world.hitMap.cell(at: tile.point),
                  cell.zone != .outside, cell.staticBlocker == nil else { continue }
            floorRoot.addChild(makeFloorTile(style: tile.styleID, at: tile.point, preview: false))
        }
        floorRoot.zPosition = -85
    }

    private func rebuildFloorPreview() {
        floorPreviewRoot.removeAllChildren()
        guard let style = renderedFloorPreviewStyle else { return }
        for point in Set(renderedFloorPreview) {
            guard let cell = renderedState.world.hitMap.cell(at: point),
                  cell.zone != .outside, cell.staticBlocker == nil else { continue }
            floorPreviewRoot.addChild(makeFloorTile(style: style, at: point, preview: true))
        }
        floorPreviewRoot.zPosition = -75
    }

    private func makeFloorTile(style: FloorStyleID, at point: GridPoint, preview: Bool) -> SKNode {
        let corners = footprintCorners(origin: point, footprint: GridFootprint(width: 1, depth: 1))
        let rect = bounds(of: corners)
        let group = SKNode()
        let asset = FloorStyleCatalog.definition(for: style)?.textureAssetName ?? "WornTerracottaTile"
        let sprite = SKSpriteNode(texture: texture(asset))
        sprite.size = rect.size
        sprite.position = CGPoint(x: rect.midX, y: rect.midY)
        let source: [SIMD2<Float>] = [SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1), SIMD2(1, 1)]
        let destination = [corners[0], corners[1], corners[3], corners[2]].map {
            SIMD2<Float>(Float(($0.x - rect.minX) / rect.width),
                         Float(($0.y - rect.minY) / rect.height))
        }
        sprite.warpGeometry = SKWarpGeometryGrid(columns: 1, rows: 1,
                                                  sourcePositions: source, destinationPositions: destination)
        sprite.alpha = preview ? 0.60 : 1
        group.addChild(sprite)
        if preview {
            let outline = SKShapeNode(path: polygon(corners))
            outline.fillColor = .clear
            outline.strokeColor = SKColor(red: 1, green: 0.77, blue: 0.30, alpha: 0.9)
            outline.lineWidth = max(0.8, tileWidth * 0.025)
            outline.zPosition = 1
            group.addChild(outline)
        }
        return group
    }

    private func rebuildDirt() {
        dirtRoot.removeAllChildren()
        dirtRoot.zPosition = -60
        for (point, level) in renderedState.dirt {
            guard level > 0, let cell = renderedState.world.hitMap.cell(at: point),
                  cell.zone != .outside else { continue }
            let dust = SKSpriteNode(texture: texture("DustPatch"))
            setUniformWidth(tileWidth * 0.80, on: dust)
            dust.yScale = 0.68
            dust.position = center(of: point)
            dust.alpha = min(0.42, 0.12 + CGFloat(level) * 0.10)
            dirtRoot.addChild(dust)
        }
    }

    // MARK: - Furniture, decorations and physical stock

    private func rebuildFurniture() {
        furnitureRoot.removeAllChildren()
        glowNodes.removeAll()
        for fixture in renderedState.fixtures {
            if fixture.id == renderedPreview?.fixtureID { continue }
            let node = makeFixture(kind: fixture.kind, origin: fixture.origin, rotation: fixture.rotation,
                                   fixtureID: fixture.id, preview: false, valid: true)
            furnitureRoot.addChild(node)
            if insertedFixtureIDs.contains(fixture.id), animatesInsertions {
                node.setScale(0.92)
                let settle = SKAction.scale(to: 1, duration: 0.18)
                settle.timingMode = .easeOut
                node.run(settle)
            }
        }
    }

    private func rebuildPreview() {
        previewRoot.removeAllChildren()
        guard let draft = renderedPreview else { return }
        previewRoot.addChild(makeFixture(kind: draft.kind, origin: draft.origin, rotation: draft.rotation,
                                         fixtureID: draft.fixtureID, preview: true, valid: renderedPreviewValid))
    }

    private func makeFixture(kind: FixtureKind, origin: GridPoint, rotation: FixtureRotation,
                             fixtureID: UUID?, preview: Bool, valid: Bool) -> SKNode {
        let definition = FixtureCatalog.definition(for: kind)
        let footprint = definition.footprint.rotated(rotation)
        let corners = footprintCorners(origin: origin, footprint: footprint)
        let floorBounds = bounds(of: corners)
        let base = CGPoint(x: floorBounds.midX, y: floorBounds.midY - tileHeight * 0.2)
        let group = SKNode()
        if let fixtureID { group.name = "fixture:\(fixtureID.uuidString)" }
        group.position = base
        group.zPosition = preview ? 1000 : (kind == .starRug ? -20 : 500 - base.y * 0.2)
        group.alpha = preview ? 0.78 : 1

        if preview || fixtureID == selectedFixtureID {
            let selection = SKShapeNode(path: polygon(corners.map { CGPoint(x: $0.x - base.x, y: $0.y - base.y) }))
            selection.fillColor = preview && !valid
                ? SKColor(red: 0.94, green: 0.22, blue: 0.17, alpha: 0.25)
                : SKColor(red: 0.19, green: 0.8, blue: 0.58, alpha: 0.15)
            selection.strokeColor = preview && !valid ? .systemRed : SKColor(red: 1, green: 0.78, blue: 0.31, alpha: 0.95)
            selection.lineWidth = max(1.2, tileWidth * 0.055)
            selection.glowWidth = reducedMotion ? 0 : 1.2
            selection.zPosition = -1
            group.addChild(selection)
        }

        let assetName: String
        let desiredWidth: CGFloat
        switch kind {
        case .basicDisplayTable: assetName = "BasicDisplayTable"; desiredWidth = floorBounds.width * 1.16
        case .simpleShelf:
            assetName = rotation.swapsAxes ? "SimpleShelfSide" : "SimpleShelf"
            desiredWidth = floorBounds.width * 0.93
        case .pottedFern: assetName = "PottedFern"; desiredWidth = tileWidth * 1.30
        case .starRug: assetName = "StarRug"; desiredWidth = tileWidth * 1.82
        case .crystalDisplay: assetName = "CrystalDisplay"; desiredWidth = tileWidth * 1.38
        case .wallClock: assetName = "WallClock"; desiredWidth = tileWidth * 1.12
        case .moonPainting: assetName = "MoonPainting"; desiredWidth = tileWidth * 1.38
        case .brassLantern: assetName = "BrassLantern"; desiredWidth = tileWidth * 1.72
        }
        let sprite = SKSpriteNode(texture: texture(assetName))
        setUniformWidth(desiredWidth, on: sprite)
        if kind == .simpleShelf, rotation.swapsAxes {
            // Side art has a narrower silhouette and transparent margins.
            // Keep the upright shelf the same height as its rear-wall view.
            setUniformHeight(tileHeight * 2.8, on: sprite)
        }
        sprite.anchorPoint = CGPoint(x: 0.5, y: kind == .starRug ? 0.5 : 0.06)
        sprite.position = .zero
        sprite.zPosition = 1
        // Rotating a painted upright object rotates its feet into the air.
        // Alternate side art and a horizontal mirror preserve its upright pose.
        if kind == .simpleShelf, rotation.swapsAxes,
           renderedState.world.hitMap.cell(at: origin)?.adjacentWalls.contains(.right) == true {
            sprite.xScale = -1
        }
        if kind == .wallClock || kind == .moonPainting {
            mountWallDecoration(sprite, origin: origin, rotation: rotation, base: base)
        }
        if kind == .starRug {
            sprite.position.y = tileHeight * 0.2
            sprite.yScale = 0.78
        }
        group.addChild(sprite)

        if kind == .brassLantern || kind == .crystalDisplay {
            let glow = SKShapeNode(ellipseOf: CGSize(width: tileWidth * 0.82, height: tileHeight * 0.35))
            glow.fillColor = kind == .brassLantern
                ? SKColor(red: 1, green: 0.67, blue: 0.2, alpha: 1)
                : SKColor(red: 0.42, green: 0.72, blue: 1, alpha: 1)
            glow.strokeColor = .clear
            glow.alpha = 0.035
            glow.zPosition = -0.5
            group.addChild(glow)
            if !preview { glowNodes.append(glow) }
        }

        if let fixtureID {
            for unit in renderedState.stock where unit.fixtureID == fixtureID {
                let product = SKSpriteNode(texture: texture(productAsset(unit.product)))
                product.name = "stock:\(unit.id.uuidString)"
                setUniformWidth(tileWidth * 0.68, on: product)
                if product.size.height > tileHeight * 0.82 {
                    setUniformHeight(tileHeight * 0.82, on: product)
                }
                product.anchorPoint = CGPoint(x: 0.5, y: 0)
                let sideShelf = kind == .simpleShelf && rotation.swapsAxes
                let productX = sideShelf ? sprite.size.width * 0.08 * sprite.xScale : 0
                product.position = CGPoint(x: productX, y: sprite.size.height
                    * (kind == .basicDisplayTable ? 0.67 : (unit.slotIndex == 0 ? 0.45 : 0.15)))
                product.zPosition = 2
                group.addChild(product)
                if insertedStockIDs.contains(unit.id), animatesInsertions {
                    product.setScale(0.65)
                    product.alpha = 0
                    let settle = SKAction.scale(to: 1, duration: 0.20)
                    settle.timingMode = .easeOut
                    product.run(.group([settle, .fadeIn(withDuration: 0.15)]))
                }
            }
        }
        return group
    }

    private func mountWallDecoration(_ sprite: SKSpriteNode, origin: GridPoint,
                                     rotation: FixtureRotation, base: CGPoint) {
        let walls = renderedState.world.hitMap.cell(at: origin)?.adjacentWalls ?? []
        let preferred: WallSide
        switch rotation {
        case .north: preferred = .rear
        case .east: preferred = .right
        case .south: preferred = .front
        case .west: preferred = .left
        }
        // At corners rotation chooses the wall; away from corners the actual
        // adjacent wall takes precedence over a stored generic orientation.
        guard let wall = walls.contains(preferred) ? preferred
            : [WallSide.rear, .left, .right, .front].first(where: walls.contains) else { return }
        let x = CGFloat(origin.x), y = CGFloat(origin.y)
        let annex = renderedState.restoration.expansion.flatMap { expansion -> ExpansionState? in
            let start = expansion.roomOrigin
            return origin.x >= start.x && origin.x < start.x + ExpansionState.roomSize
                && origin.y >= start.y && origin.y < start.y + ExpansionState.roomSize ? expansion : nil
        }
        var position: CGPoint
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        switch wall {
        case .rear:
            position = project(x: x + 0.5, y: y + 1)
            position.y += annex == nil ? tileHeight * 2.25 : annexFaceHeight * 0.56
            if annex == nil, renderedState.restoration.expansion?.direction == .rear {
                // The saved cell stays put, but its artwork must fit the wall
                // segment remaining beside the new opening and painted jamb.
                let postSize = texture("FacadeCornerPost").size()
                let postWidth = annexWallHeight * postSize.width / max(1, postSize.height)
                let inset = postWidth * 0.92 + sprite.size.width * 0.5 + tileWidth * 0.04
                let outerInset = sprite.size.width * 0.5 + tileWidth * 0.08
                if origin.x >= 8 {
                    position.x = min(max(position.x, project(x: 8, y: 11).x + inset),
                                     project(x: 11, y: 11).x - outerInset)
                } else if origin.x < 3 {
                    position.x = max(min(position.x, project(x: 3, y: 11).x - inset),
                                     project(x: 0, y: 11).x + outerInset)
                }
            }
        case .front:
            position = project(x: x + 0.5, y: y)
            if annex != nil {
                // Front walls stay cut away. Mount on their real low fascia;
                // a saved decoration must not float above an absent wall.
                setUniformHeight(tileHeight * 0.18, on: sprite)
                position.y += tileHeight * 0.10
            } else {
                position.y -= tileHeight * 0.83
            }
        case .left, .right:
            position = project(x: wall == .left ? x : x + 1, y: y + 0.5)
            if let annex {
                let height = annexSideHeight(at: y + 0.5, expansion: annex)
                if sprite.size.height > height * 0.65 { setUniformHeight(height * 0.65, on: sprite) }
                position.x += height * (wall == .left ? -0.077 : 0.077)
                position.y += height * 0.55
            } else {
                position.x += tileWidth * (wall == .left ? -0.24 : 0.24)
                position.y += tileHeight * 0.30
            }
            // A shallow, upright quadrilateral lies on the painted side wall.
            // Pixel art is never rotated onto its side or turned upside down.
            let source: [SIMD2<Float>] = [
                SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1), SIMD2(1, 1)
            ]
            let destination: [SIMD2<Float>] = wall == .left
                ? [SIMD2(0.29, 0), SIMD2(0.71, 0.20), SIMD2(0.29, 0.80), SIMD2(0.71, 1)]
                : [SIMD2(0.29, 0.20), SIMD2(0.71, 0), SIMD2(0.29, 1), SIMD2(0.71, 0.80)]
            sprite.warpGeometry = SKWarpGeometryGrid(columns: 1, rows: 1,
                                                     sourcePositions: source,
                                                     destinationPositions: destination)
        }
        sprite.position = CGPoint(x: position.x - base.x, y: position.y - base.y)
    }

    // MARK: - Persistent simultaneous visitors

    private func prepareLivingDay(presentationMinute: Double?, rebuild: Bool) {
        guard let day = renderedState.livingDay else {
            livingRoot.removeAllChildren()
            livingCustomers.removeAll()
            livingDayID = nil
            handledLivingOutcomes.removeAll()
            return
        }
        let requested = presentationMinute ?? Double(day.minute)
        targetLivingMinute = requested.isFinite
            ? min(Double(ShopCalendar.closingMinute), max(Double(day.minute), requested))
            : Double(day.minute)
        if day.id != livingDayID {
            livingDayID = day.id
            livingRoot.removeAllChildren()
            livingCustomers.removeAll()
            displayedLivingMinute = targetLivingMinute
            // A restored save must not replay historical sale effects.
            handledLivingOutcomes = Set(day.visitors.filter { $0.outcome != nil }.map(\.id))
        } else if rebuild {
            livingRoot.removeAllChildren()
            livingCustomers.removeAll()
        }
        updateLivingCustomers(at: reducedMotion ? targetLivingMinute : displayedLivingMinute)
        for visitor in day.visitors where visitor.outcome != nil {
            guard handledLivingOutcomes.insert(visitor.id).inserted,
                  let sale = visitor.sale,
                  targetLivingMinute < Double(visitor.departureMinute) else { continue }
            let location = livingPosition(visitor, minute: targetLivingMinute)
            showReceipt(sale, at: location)
        }
    }

    private func livingPosition(_ visitor: LivingVisitor, minute: Double) -> CGPoint {
        let location = visitor.position(at: minute)
        let first = center(of: location.from)
        let second = center(of: location.to)
        let fraction = CGFloat(min(1, max(0, location.progress)))
        return CGPoint(x: first.x + (second.x - first.x) * fraction,
                       y: first.y + (second.y - first.y) * fraction)
    }

    private func updateLivingCustomers(at minute: Double) {
        guard let day = renderedState.livingDay else { return }
        let visible = day.visitors.filter {
            minute >= Double($0.arrivalMinute) && minute < Double($0.departureMinute)
        }
        let ids = Set(visible.map(\.id))
        for id in Array(livingCustomers.keys) where !ids.contains(id) {
            livingCustomers.removeValue(forKey: id)?.root.removeFromParent()
        }
        for visitor in visible {
            let art: LivingCustomerArt
            if let existing = livingCustomers[visitor.id] { art = existing }
            else {
                art = LivingCustomerArt(tileWidth: tileWidth, tileHeight: tileHeight)
                livingCustomers[visitor.id] = art
                livingRoot.addChild(art.root)
            }
            let location = visitor.position(at: minute)
            let status = visitor.status(at: Int(minute))
            let walking = location.from != location.to
            var position = livingPosition(visitor, minute: minute)
            if reducedMotion {
                let destination = visitor.stops.first { minute < Double($0.departureMinute) }?.path.last
                    ?? visitor.exitPath.last
                if let destination { position = center(of: destination) }
            }
            // Small stable lanes keep two visitors from drawing precisely on
            // top of one another while remaining inside their walkable cells.
            let lane = CGFloat(visitor.id.index % 3 - 1)
            position.x += lane * tileWidth * 0.10
            position.y += CGFloat(visitor.id.index % 2) * tileHeight * 0.07
            art.root.position = position
            art.root.zPosition = 500 - position.y * 0.2 + 0.3 + CGFloat(visitor.id.index) * 0.001
            let arrivingFade = (minute - Double(visitor.arrivalMinute)) / 1.8
            let leavingFade = (Double(visitor.departureMinute) - minute) / 1.8
            art.root.alpha = reducedMotion ? 1 : CGFloat(min(1, max(0, min(arrivingFade, leavingFade))))

            let lookFront = location.to.y < location.from.y || status == .leaving
            let baseName = visitor.id.index.isMultiple(of: 2) ? "CustomerPlum" : "CustomerGreen"
            let imageName = lookFront ? baseName + "Front" : baseName
            if art.imageName != imageName {
                art.imageName = imageName
                art.body.texture = texture(imageName)
                setUniformHeight(tileHeight * 1.65, on: art.body)
            }
            if location.to.x != location.from.x {
                art.body.xScale = location.to.x < location.from.x ? -1 : 1
            }
            art.body.position.y = reducedMotion || !walking ? 0
                : CGFloat(sin(minute * 2.4 + Double(visitor.id.index))) * tileHeight * 0.025

            let stop = visitor.stops.first {
                minute >= Double($0.arrivalMinute) && minute < Double($0.departureMinute)
            }
            let displayedUnit = stop.flatMap { stop in
                renderedState.stock.first { $0.fixtureID == stop.fixtureID
                    && ($0.product == visitor.preferredProduct || $0.product == visitor.secondaryProduct) }
                    ?? renderedState.stock.first { $0.fixtureID == stop.fixtureID }
            }
            let product = visitor.sale?.product ?? displayedUnit?.product ?? visitor.preferredProduct
            let caption: String
            if visitor.sale != nil { caption = "Thank you" }
            else if visitor.outcome != nil { caption = "Maybe later" }
            else if let unit = displayedUnit { caption = "$\(renderedState.price(for: unit.product))" }
            else { caption = status == .comparing ? "Comparing" : "Browsing" }
            let key = product.rawValue + caption
            if art.bubbleKey != key {
                art.bubbleKey = key
                art.icon.texture = texture(productAsset(product))
                setUniformHeight(tileHeight * 0.48, on: art.icon)
                art.caption.text = caption
                art.carried.texture = texture(productAsset(product))
                setUniformHeight(tileHeight * 0.46, on: art.carried)
            }
            art.bubble.position = CGPoint(x: lane * tileWidth * 0.32,
                                          y: art.body.size.height + tileHeight * 0.85)
            art.bubble.isHidden = walking && visitor.outcome == nil
            art.carried.isHidden = visitor.sale == nil
            art.carried.position = CGPoint(x: tileWidth * 0.15, y: art.body.size.height * 0.52)
        }
    }

    // MARK: - One paced, replay-safe customer presentation

    private func makeVisitPlan(_ visit: CustomerVisit, outcome: VisitOutcome?) -> VisitPlan {
        let matchingUnit = renderedState.stock.first { unit in
            guard unit.product == visit.requestedProduct,
                  let fixture = renderedState.fixtures.first(where: { $0.id == unit.fixtureID }) else { return false }
            return ShopAccess.isReachable(fixture, in: renderedState)
        }
        let receiptFixtureID = outcome?.visitID == visit.id ? outcome?.sale?.fixtureID : nil
        let destinationID = matchingUnit?.fixtureID ?? receiptFixtureID
        if let destinationID,
           let fixture = renderedState.fixtures.first(where: { $0.id == destinationID }),
           let route = ShopAccess.path(to: fixture, in: renderedState) {
            return VisitPlan(id: visit.id, route: route, fixtureID: destinationID, product: visit.requestedProduct)
        }
        let entrance = renderedState.world.hitMap.cells.first { $0.zone == .entrance }?.point
            ?? GridPoint(x: starterOrigin.x + 5, y: starterOrigin.y)
        let reachable = ShopAccess.reachableCells(in: renderedState)
        let inside = GridPoint(x: entrance.x, y: entrance.y + 1)
        let route = reachable.contains(inside) ? [entrance, inside] : [entrance]
        return VisitPlan(id: visit.id, route: route, fixtureID: nil, product: visit.requestedProduct)
    }

    private func rebuildCustomer() {
        customerRoot.removeAllChildren()
        customerSprite = nil
        customerFacingOut = false
        customerShadow = nil
        thoughtNode = nil
        carriedProduct = nil
        guard let plan = visitPlan else { return }
        let shadow = SKShapeNode(ellipseOf: CGSize(width: tileWidth * 0.58, height: tileHeight * 0.24))
        shadow.fillColor = SKColor(white: 0, alpha: 0.25)
        shadow.strokeColor = .clear
        customerRoot.addChild(shadow)
        customerShadow = shadow

        let customer = SKSpriteNode(texture: texture(plan.id.index.isMultiple(of: 2) ? "CustomerPlum" : "CustomerGreen"))
        setUniformHeight(tileHeight * 1.65, on: customer)
        customer.anchorPoint = CGPoint(x: 0.5, y: 0.045)
        customerRoot.addChild(customer)
        customerSprite = customer

        let thought = SKNode()
        let bubble = SKShapeNode(ellipseOf: CGSize(width: tileWidth * 0.66, height: tileWidth * 0.60))
        bubble.fillColor = SKColor(red: 0.98, green: 0.93, blue: 0.8, alpha: 0.96)
        bubble.strokeColor = SKColor(red: 0.78, green: 0.54, blue: 0.23, alpha: 0.85)
        bubble.lineWidth = 0.8
        thought.addChild(bubble)
        let icon = SKSpriteNode(texture: texture(productAsset(plan.product)))
        setUniformHeight(tileHeight * 0.40, on: icon)
        thought.addChild(icon)
        customerRoot.addChild(thought)
        thoughtNode = thought

        let carried = SKSpriteNode(texture: texture(productAsset(plan.product)))
        setUniformHeight(tileHeight * 0.46, on: carried)
        carried.isHidden = true
        customerRoot.addChild(carried)
        carriedProduct = carried
    }

    private func updateCustomer(progress rawProgress: Double) {
        guard let plan = visitPlan, let sprite = customerSprite else { return }
        let progress = max(0, min(1, rawProgress))
        let walkingIn = progress < 0.55
        let walkingOut = progress > 0.73
        if customerFacingOut != walkingOut {
            customerFacingOut = walkingOut
            let name = plan.id.index.isMultiple(of: 2) ? "CustomerPlum" : "CustomerGreen"
            sprite.texture = texture(walkingOut ? name + "Front" : name)
            setUniformHeight(tileHeight * 1.65, on: sprite)
        }
        let routeFraction: Double
        if reducedMotion { routeFraction = 1 }
        else if walkingIn { routeFraction = progress / 0.55 }
        else if walkingOut { routeFraction = 1 - (progress - 0.73) / 0.27 }
        else { routeFraction = 1 }
        let route = plan.route.map { center(of: $0) }
        let position = point(on: route, fraction: routeFraction)
        let bob: CGFloat = reducedMotion || (!walkingIn && !walkingOut)
            ? 0 : CGFloat(sin(progress * .pi * 34)) * tileHeight * 0.025
        sprite.position = CGPoint(x: position.x, y: position.y + bob)
        sprite.zPosition = 500 - position.y * 0.2 + 0.5
        sprite.alpha = reducedMotion ? (progress >= 0.99 ? 0 : 1) : CGFloat(min(1, min(progress / 0.04, (1 - progress) / 0.04)))
        customerShadow?.position = position
        customerShadow?.zPosition = sprite.zPosition - 0.1
        customerShadow?.alpha = sprite.alpha
        thoughtNode?.position = CGPoint(x: position.x + tileWidth * 0.33, y: position.y + sprite.size.height + tileHeight * 0.28)
        thoughtNode?.zPosition = sprite.zPosition + 2
        thoughtNode?.isHidden = progress >= 0.67
        carriedProduct?.position = CGPoint(x: position.x + tileWidth * 0.16, y: position.y + sprite.size.height * 0.53)
        carriedProduct?.zPosition = sprite.zPosition + 1
        carriedProduct?.isHidden = currentOutcome?.sale == nil || progress < 0.65
        carriedProduct?.alpha = sprite.alpha
    }

    private func point(on route: [CGPoint], fraction: Double) -> CGPoint {
        guard let first = route.first else { return .zero }
        guard route.count > 1 else { return first }
        let scaled = max(0, min(1, fraction)) * Double(route.count - 1)
        let segment = min(route.count - 2, Int(scaled))
        let offset = CGFloat(scaled - Double(segment))
        return CGPoint(x: route[segment].x + (route[segment + 1].x - route[segment].x) * offset,
                       y: route[segment].y + (route[segment + 1].y - route[segment].y) * offset)
    }

    private func showOutcome(_ outcome: VisitOutcome) {
        guard let sale = outcome.sale, let plan = visitPlan else { return }
        let position = plan.route.last.map { center(of: $0) } ?? .zero
        showReceipt(sale, at: position)
    }

    private func showReceipt(_ sale: SaleReceipt, at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "Georgia-Bold")
        label.text = "+$\(sale.revenue)"
        label.fontSize = max(12, tileWidth * 0.5)
        label.fontColor = SKColor(red: 1, green: 0.83, blue: 0.36, alpha: 1)
        label.position = CGPoint(x: position.x, y: position.y + tileHeight * 1.9)
        label.zPosition = 1500
        feedbackRoot.addChild(label)
        if reducedMotion {
            label.run(.sequence([.wait(forDuration: 1.1), .removeFromParent()]))
        } else {
            label.run(.sequence([
                .group([.moveBy(x: 0, y: tileHeight * 0.65, duration: 1.1),
                        .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 0.6)])]),
                .removeFromParent()
            ]))
        }
    }

    private func texture(_ name: String) -> SKTexture {
        if let existing = textures[name] { return existing }
        let result = SKTexture(imageNamed: name)
        result.filteringMode = .linear
        textures[name] = result
        return result
    }

    private func productAsset(_ product: ProductKind) -> String {
        switch product {
        case .glowPotion: return "GlowPotion"
        case .luckyCharm: return "LuckyCharm"
        case .pocketSpellbook: return "PocketSpellbook"
        }
    }

    private func setUniformWidth(_ width: CGFloat, on sprite: SKSpriteNode) {
        let original = sprite.texture?.size() ?? CGSize(width: 1, height: 1)
        sprite.size = CGSize(width: width, height: width * original.height / max(1, original.width))
    }

    private func setUniformHeight(_ height: CGFloat, on sprite: SKSpriteNode) {
        let original = sprite.texture?.size() ?? CGSize(width: 1, height: 1)
        sprite.size = CGSize(width: height * original.width / max(1, original.height), height: height)
    }
}
