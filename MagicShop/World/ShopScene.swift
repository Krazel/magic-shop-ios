import SpriteKit

/// The approved starter plate is retained as one sprite. Every interactive
/// point is projected onto its authored floor; no visible grid is constructed.
final class ShopScene: SKScene {
    private enum FloorCalibration {
        // Source: 853x1844 StarterShopBackground. Coordinates are normalized
        // image positions, with image Y increasing downward. This slight
        // trapezoid is the projection of the persistent square 11x11 floor.
        static let nearY: CGFloat = 1172 / 1844
        static let farY: CGFloat = 629 / 1844
        static let nearLeft: CGFloat = 106 / 853
        static let nearRight: CGFloat = 749 / 853
        static let farLeft: CGFloat = 143 / 853
        static let farRight: CGFloat = 701 / 853
    }

    private struct VisitPlan {
        let id: VisitID
        let route: [GridPoint]
        let fixtureID: UUID?
        let product: ProductKind
    }

    private let environmentRoot = SKNode()
    private let furnitureRoot = SKNode()
    private let previewRoot = SKNode()
    private let customerRoot = SKNode()
    private let feedbackRoot = SKNode()
    private let worldCamera = SKCameraNode()
    private var textures: [String: SKTexture] = [:]
    private var renderedState = GameState.initial
    private var renderedPreview: PlacementDraft?
    private var renderedPreviewValid = false
    private var selectedFixtureID: UUID?
    private var reducedMotion = false
    private var needsFirstRender = true
    private var visitPlan: VisitPlan?
    private var targetProgress = 0.0
    private var displayedProgress = 0.0
    private var currentOutcome: VisitOutcome?
    private var displayedOutcomeID: VisitID?
    private var customerSprite: SKSpriteNode?
    private var customerShadow: SKShapeNode?
    private var thoughtNode: SKNode?
    private var carriedProduct: SKSpriteNode?
    private var glowNodes: [SKShapeNode] = []
    private var lastFrameTime: TimeInterval?
    private var cameraState = WorldCameraState()
    private var horizontalOffset: CGFloat = 0
    private var contentLift: CGFloat = 0

    private var starterOrigin: GridPoint {
        renderedState.restoration.expansion?.starterOrigin ?? GridPoint(x: 0, y: 0)
    }

    private var backgroundSize: CGSize {
        let original = texture("StarterShopBackground").size()
        guard original.width > 0, original.height > 0, size.width > 0, size.height > 0 else { return size }
        let base = max(size.width / original.width, size.height / original.height)
        let wingFit: CGFloat = renderedState.restoration.expansion?.direction == .rear
            || renderedState.restoration.expansion == nil ? 1 : 0.84
        return CGSize(width: original.width * base * wingFit, height: original.height * base * wingFit)
    }

    private var tileWidth: CGFloat {
        backgroundSize.width * (FloorCalibration.nearRight - FloorCalibration.nearLeft
            + FloorCalibration.farRight - FloorCalibration.farLeft) / 22
    }

    private var tileHeight: CGFloat {
        backgroundSize.height * (FloorCalibration.nearY - FloorCalibration.farY) / 11
    }

    private var cameraCenterX: CGFloat {
        guard let expansion = renderedState.restoration.expansion, expansion.direction != .rear else { return 0 }
        let originalCenter = project(x: CGFloat(starterOrigin.x) + 5.5, y: 5.5).x
        let roomCenter = project(x: CGFloat(expansion.roomOrigin.x) + 2.5,
                                 y: CGFloat(expansion.roomOrigin.y) + 2.5).x
        return originalCenter + (roomCenter - originalCenter) * 0.29
    }

    var horizontalPanLimit: CGFloat { max(70, backgroundSize.width * 0.46) }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.25, green: 0.20, blue: 0.14, alpha: 1)
        for node in [environmentRoot, furnitureRoot, previewRoot, customerRoot, feedbackRoot] {
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
        rebuildFurniture()
        rebuildPreview()
        rebuildCustomer()
        apply(cameraState, horizontalOffset: horizontalOffset, contentLift: contentLift)
    }

    func apply(_ cameraState: WorldCameraState, horizontalOffset: CGFloat = 0, contentLift: CGFloat = 0) {
        self.cameraState = cameraState
        self.horizontalOffset = horizontalOffset
        self.contentLift = contentLift
        worldCamera.setScale(CGFloat(cameraState.zoom))
        worldCamera.position = CGPoint(
            x: cameraCenterX + horizontalOffset,
            y: CGFloat(cameraState.verticalOffset) - contentLift * CGFloat(cameraState.zoom)
        )
    }

    func render(
        state: GameState,
        preview: PlacementDraft?,
        previewIsValid: Bool,
        selectedFixtureID: UUID?,
        activeVisit: CustomerVisit?,
        visitProgress: Double,
        lastOutcome: VisitOutcome?,
        reduceMotion: Bool
    ) {
        let environmentChanged = needsFirstRender || state.world != renderedState.world
            || state.restoration != renderedState.restoration
        let furnitureChanged = environmentChanged || state.fixtures != renderedState.fixtures
            || state.stock != renderedState.stock || self.selectedFixtureID != selectedFixtureID
            || reducedMotion != reduceMotion
        let previewChanged = environmentChanged || preview != renderedPreview
            || previewIsValid != renderedPreviewValid || reducedMotion != reduceMotion
        let motionChanged = reducedMotion != reduceMotion
        renderedState = state
        renderedPreview = preview
        renderedPreviewValid = previewIsValid
        self.selectedFixtureID = selectedFixtureID
        reducedMotion = reduceMotion
        needsFirstRender = false

        if motionChanged { feedbackRoot.removeAllChildren() }
        if environmentChanged { rebuildEnvironment() }
        if furnitureChanged { rebuildFurniture() }
        if previewChanged { rebuildPreview() }

        if visitPlan?.id != activeVisit?.id {
            if let visit = activeVisit {
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
        targetProgress = visitProgress.isFinite ? max(0, min(1, visitProgress)) : 0
        currentOutcome = lastOutcome?.visitID == activeVisit?.id ? lastOutcome : nil
        updateCustomer(progress: reducedMotion ? targetProgress : displayedProgress)

        if let outcome = currentOutcome, outcome.visitID != displayedOutcomeID {
            displayedOutcomeID = outcome.visitID
            showOutcome(outcome)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = min(0.1, max(0, currentTime - (lastFrameTime ?? currentTime)))
        lastFrameTime = currentTime
        if reducedMotion {
            displayedProgress = targetProgress
        } else {
            displayedProgress += (targetProgress - displayedProgress) * min(1, delta * 24)
        }
        updateCustomer(progress: displayedProgress)
        let warmth = reducedMotion ? 0.12 : 0.12 + 0.025 * sin(currentTime * 1.8)
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
        let fullyRepaired = renderedState.restoration.repairedGroups.count == RestorationGroupID.allCases.count
        let background = SKSpriteNode(texture: texture(fullyRepaired ? "RepairedShopBackground" : "StarterShopBackground"))
        background.size = backgroundSize
        background.zPosition = -100
        environmentRoot.addChild(background)

        if !fullyRepaired {
            for group in renderedState.restoration.repairedGroups { addRepairPatch(group) }
        }
        if let expansion = renderedState.restoration.expansion { addAnnex(expansion) }
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
        crop.zPosition = -95
        environmentRoot.addChild(crop)
    }

    private func addAnnex(_ expansion: ExpansionState) {
        let room = expansion.roomOrigin
        let corners = footprintCorners(origin: room, footprint: GridFootprint(width: 5, depth: 5))
        let rect = bounds(of: corners)
        let asset = expansion.direction == .rear ? "AnnexRoomRearBackground" : "AnnexRoomBackground"
        let annex = SKSpriteNode(texture: texture(asset))
        // The annex asset is authored as a compact room with low walls. Its
        // floor, rather than the transparent outer bounds, defines its size.
        annex.size = CGSize(width: rect.width / 0.82, height: rect.height / 0.74)
        annex.position = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.075)
        if expansion.direction == .left { annex.xScale = -1 }
        annex.zPosition = -92
        environmentRoot.addChild(annex)

        // Removing the shared wall is the one selective alteration to the
        // original room. A painted floor patch opens the same five cells that
        // the domain joins; the original starter image remains untouched.
        let shift = starterOrigin
        let join: [CGPoint]
        switch expansion.direction {
        case .left:
            join = [project(x: CGFloat(shift.x) - 0.35, y: 3),
                    project(x: CGFloat(shift.x) + 0.55, y: 3),
                    project(x: CGFloat(shift.x) + 0.55, y: 8),
                    project(x: CGFloat(shift.x) - 0.35, y: 8)]
        case .right:
            join = [project(x: 10.45, y: 3), project(x: 11.4, y: 3),
                    project(x: 11.4, y: 8), project(x: 10.45, y: 8)]
        case .rear:
            join = [project(x: 3, y: 10.45), project(x: 8, y: 10.45),
                    project(x: 8, y: 11.8), project(x: 3, y: 11.8)]
        }
        let crop = SKCropNode()
        let rectOfJoin = bounds(of: join)
        let floor = SKSpriteNode(texture: texture("AnnexFloorPatch"))
        floor.size = CGSize(width: rectOfJoin.width, height: rectOfJoin.height)
        floor.position = CGPoint(x: rectOfJoin.midX, y: rectOfJoin.midY)
        crop.addChild(floor)
        let mask = SKShapeNode(path: polygon(join))
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        crop.zPosition = -90
        environmentRoot.addChild(crop)
    }

    // MARK: - Furniture, decorations and physical stock

    private func rebuildFurniture() {
        furnitureRoot.removeAllChildren()
        glowNodes.removeAll()
        for fixture in renderedState.fixtures {
            let node = makeFixture(kind: fixture.kind, origin: fixture.origin, rotation: fixture.rotation,
                                   fixtureID: fixture.id, preview: false, valid: true)
            furnitureRoot.addChild(node)
        }
    }

    private func rebuildPreview() {
        previewRoot.removeAllChildren()
        guard let draft = renderedPreview else { return }
        previewRoot.addChild(makeFixture(kind: draft.kind, origin: draft.origin, rotation: draft.rotation,
                                         fixtureID: nil, preview: true, valid: renderedPreviewValid))
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
        group.zPosition = kind == .starRug ? -20 : 500 - base.y * 0.2
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
        case .basicDisplayTable: assetName = "BasicDisplayTable"; desiredWidth = floorBounds.width * 0.88
        case .simpleShelf:
            assetName = rotation.swapsAxes ? "SimpleShelfSide" : "SimpleShelf"
            desiredWidth = floorBounds.width * 0.93
        case .pottedFern: assetName = "PottedFern"; desiredWidth = tileWidth * 0.78
        case .starRug: assetName = "StarRug"; desiredWidth = tileWidth * 0.94
        case .crystalDisplay: assetName = "CrystalDisplay"; desiredWidth = tileWidth * 0.74
        case .wallClock: assetName = "WallClock"; desiredWidth = tileWidth * 0.62
        case .moonPainting: assetName = "MoonPainting"; desiredWidth = tileWidth * 0.84
        case .brassLantern: assetName = "BrassLantern"; desiredWidth = tileWidth * 0.65
        }
        let sprite = SKSpriteNode(texture: texture(assetName))
        setUniformWidth(desiredWidth, on: sprite)
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
            sprite.position.y = tileHeight * 1.05
        }
        if kind == .starRug {
            sprite.position.y = tileHeight * 0.2
            sprite.yScale = 0.78
        }
        group.addChild(sprite)

        if kind == .brassLantern || kind == .crystalDisplay {
            let glow = SKShapeNode(ellipseOf: CGSize(width: tileWidth * 1.3, height: tileHeight * 0.8))
            glow.fillColor = kind == .brassLantern
                ? SKColor(red: 1, green: 0.67, blue: 0.2, alpha: 1)
                : SKColor(red: 0.42, green: 0.72, blue: 1, alpha: 1)
            glow.strokeColor = .clear
            glow.alpha = 0.12
            glow.zPosition = -0.5
            group.addChild(glow)
            if !preview { glowNodes.append(glow) }
        }

        if let fixtureID {
            for unit in renderedState.stock where unit.fixtureID == fixtureID {
                let product = SKSpriteNode(texture: texture(productAsset(unit.product)))
                setUniformWidth(tileWidth * 0.36, on: product)
                if product.size.height > tileHeight * 0.59 {
                    setUniformHeight(tileHeight * 0.59, on: product)
                }
                product.anchorPoint = CGPoint(x: 0.5, y: 0)
                product.position = CGPoint(x: 0, y: sprite.size.height * (kind == .basicDisplayTable ? 0.67 : (unit.slotIndex == 0 ? 0.57 : 0.22)))
                product.zPosition = 2
                group.addChild(product)
            }
        }
        return group
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
        setUniformHeight(tileHeight * 1.38, on: customer)
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
        setUniformHeight(tileHeight * 0.34, on: carried)
        carried.isHidden = true
        customerRoot.addChild(carried)
        carriedProduct = carried
    }

    private func updateCustomer(progress rawProgress: Double) {
        guard let plan = visitPlan, let sprite = customerSprite else { return }
        let progress = max(0, min(1, rawProgress))
        let walkingIn = progress < 0.55
        let walkingOut = progress > 0.73
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
