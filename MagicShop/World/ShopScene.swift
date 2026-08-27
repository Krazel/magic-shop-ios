import SpriteKit

final class ShopScene: SKScene {
    private enum MountingCalibration {
        static let rearWallHeightInTiles: CGFloat = 2.0
        static let facadeWidthFraction: CGFloat = 0.315
        static let facadeEntranceWidthInTiles: CGFloat = 2.05
        static let facadeHeightInTiles: CGFloat = 2.88
        static let sideDepthScale: CGFloat = 1.02
    }

    private let worldRoot = SKNode()
    private let environmentRoot = SKNode()
    private let floorRoot = SKNode()
    private let staticBlockerRoot = SKNode()
    private let fixtureRoot = SKNode()
    private let placementRoot = SKNode()
    private let foregroundArchitectureRoot = SKNode()
    private let worldCamera = SKCameraNode()

    private var renderedWorld = ShopWorldState.starter
    private var renderedFixtures: [PlacedFixture] = []
    private var renderedPreview: PlacementDraft?
    private var renderedPreviewIsValid = false

    private var tileSide: CGFloat {
        min(38, max(30, size.width / 11.8))
    }

    private var gridGeometry: WorldGridGeometry {
        WorldGridGeometry(
            layout: renderedWorld.hitMap.layout,
            tileSide: Double(tileSide)
        )
    }

    private var floorRect: CGRect {
        let width = CGFloat(renderedWorld.hitMap.layout.width) * tileSide
        let depth = CGFloat(renderedWorld.hitMap.layout.depth) * tileSide
        return CGRect(x: -width / 2, y: -depth / 2, width: width, height: depth)
    }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.25, green: 0.20, blue: 0.14, alpha: 1)

        addChild(worldRoot)
        worldRoot.addChild(environmentRoot)
        worldRoot.addChild(floorRoot)
        worldRoot.addChild(staticBlockerRoot)
        worldRoot.addChild(fixtureRoot)
        worldRoot.addChild(placementRoot)
        worldRoot.addChild(foregroundArchitectureRoot)

        addChild(worldCamera)
        camera = worldCamera
        rebuildWorld()
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildWorld()
    }

    func apply(_ cameraState: WorldCameraState) {
        worldCamera.setScale(CGFloat(cameraState.zoom))
        worldCamera.position = CGPoint(x: 0, y: CGFloat(cameraState.verticalOffset))
    }

    func render(
        world: ShopWorldState,
        fixtures: [PlacedFixture],
        preview: PlacementDraft?,
        previewIsValid: Bool
    ) {
        renderedWorld = world
        renderedFixtures = fixtures
        renderedPreview = preview
        renderedPreviewIsValid = previewIsValid
        rebuildWorld()
    }

    func gridPoint(fromWorldPoint point: WorldPoint) -> GridPoint? {
        gridGeometry.cell(at: point)
    }

    private func rebuildWorld() {
        environmentRoot.removeAllChildren()
        floorRoot.removeAllChildren()
        staticBlockerRoot.removeAllChildren()
        fixtureRoot.removeAllChildren()
        placementRoot.removeAllChildren()
        foregroundArchitectureRoot.removeAllChildren()

        buildEnvironment()
        buildFloor()
        buildStaticBlockers()
        buildFixtures()
        buildPlacement()
        buildForegroundArchitecture()
    }

    private func buildEnvironment() {
        let backing = SKShapeNode(
            rectOf: CGSize(width: max(size.width * 1.8, 680), height: max(size.height * 1.8, 1_300))
        )
        backing.fillColor = SKColor(red: 0.27, green: 0.22, blue: 0.16, alpha: 1)
        backing.strokeColor = .clear
        backing.zPosition = -100
        environmentRoot.addChild(backing)

        let pavement = SKShapeNode(
            rect: CGRect(
                x: floorRect.minX - 34,
                y: floorRect.minY - 112,
                width: floorRect.width + 68,
                height: 70
            ),
            cornerRadius: 8
        )
        pavement.fillColor = SKColor(red: 0.28, green: 0.27, blue: 0.23, alpha: 1)
        pavement.strokeColor = SKColor(red: 0.13, green: 0.12, blue: 0.10, alpha: 1)
        pavement.lineWidth = 3
        pavement.zPosition = -20
        environmentRoot.addChild(pavement)

        let panelCount = renderedWorld.hitMap.layout.width
        let panelWidth = floorRect.width / CGFloat(panelCount)
        for index in 0..<panelCount {
            let panel = SKSpriteNode(imageNamed: "RearPlasterPanel")
            panel.size = CGSize(
                width: panelWidth + 0.6,
                height: tileSide * MountingCalibration.rearWallHeightInTiles
            )
            panel.position = CGPoint(
                x: floorRect.minX + panelWidth * (CGFloat(index) + 0.5),
                y: floorRect.maxY + tileSide * MountingCalibration.rearWallHeightInTiles / 2
            )
            panel.xScale = index.isMultiple(of: 2) ? 1 : -1
            panel.zPosition = -8
            environmentRoot.addChild(panel)
        }

        let tealDado = SKSpriteNode(imageNamed: "TealBaseboardRear")
        tealDado.size = CGSize(width: floorRect.width + tileSide, height: tileSide * 0.72)
        tealDado.position = CGPoint(x: 0, y: floorRect.maxY + tileSide * 0.34)
        tealDado.zPosition = -5
        environmentRoot.addChild(tealDado)

        let rearCap = SKSpriteNode(imageNamed: "CutawayCapRear")
        rearCap.size = CGSize(width: floorRect.width + tileSide * 1.12, height: tileSide * 0.45)
        rearCap.position = CGPoint(
            x: 0,
            y: floorRect.maxY + tileSide * MountingCalibration.rearWallHeightInTiles
        )
        rearCap.zPosition = -2
        environmentRoot.addChild(rearCap)

        let lampGlow = SKShapeNode(circleOfRadius: tileSide * 0.95)
        lampGlow.fillColor = SKColor(red: 1.0, green: 0.64, blue: 0.20, alpha: 0.13)
        lampGlow.strokeColor = .clear
        lampGlow.position = CGPoint(x: 0, y: floorRect.maxY + tileSide * 1.65)
        lampGlow.zPosition = -4
        environmentRoot.addChild(lampGlow)

        let lamp = SKSpriteNode(imageNamed: "HangingLamp")
        lamp.size = CGSize(width: tileSide * 0.78, height: tileSide * 1.60)
        lamp.position = lampGlow.position
        lamp.zPosition = -2
        environmentRoot.addChild(lamp)
    }

    private func buildFloor() {
        let sortedTiles = renderedWorld.floor.tiles.sorted {
            $0.point.y == $1.point.y ? $0.point.x < $1.point.x : $0.point.y < $1.point.y
        }
        for tile in sortedTiles {
            guard let center = gridGeometry.center(of: tile.point) else { continue }
            let style = FloorStyleCatalog.definition(for: tile.styleID)
                ?? FloorStyleCatalog.wornTerracotta
            let selector = abs(tile.point.x * 17 + tile.point.y * 31) % 20
            let assetName: String
            if selector >= 11 && selector < 16,
               let firstVariant = style.variantAssetNames.first {
                assetName = firstVariant
            } else if selector >= 16, style.variantAssetNames.count > 1 {
                assetName = style.variantAssetNames[1]
            } else {
                assetName = style.textureAssetName
            }
            let sprite = SKSpriteNode(imageNamed: assetName)
            sprite.size = CGSize(width: tileSide - 0.8, height: tileSide - 0.8)
            sprite.position = CGPoint(x: center.x, y: center.y)
            sprite.zPosition = 0
            floorRoot.addChild(sprite)

            let stainCells: Set<GridPoint> = [
                GridPoint(x: 3, y: 5), GridPoint(x: 8, y: 6), GridPoint(x: 6, y: 1)
            ]
            let crackCells: Set<GridPoint> = [
                GridPoint(x: 2, y: 7), GridPoint(x: 7, y: 8), GridPoint(x: 4, y: 3)
            ]
            if stainCells.contains(tile.point), let stainAsset = style.stainDecalAssetName {
                let stain = SKSpriteNode(imageNamed: stainAsset)
                stain.size = CGSize(width: tileSide * 0.78, height: tileSide * 0.70)
                stain.position = CGPoint(x: center.x, y: center.y)
                stain.alpha = 0.40
                stain.zPosition = 1
                floorRoot.addChild(stain)
            } else if crackCells.contains(tile.point), let crackAsset = style.crackDecalAssetName {
                let crack = SKSpriteNode(imageNamed: crackAsset)
                crack.size = CGSize(width: tileSide * 0.66, height: tileSide * 0.82)
                crack.position = CGPoint(x: center.x, y: center.y)
                crack.alpha = 0.48
                crack.zPosition = 1
                floorRoot.addChild(crack)
            }
        }
    }

    private func buildStaticBlockers() {
        for cell in renderedWorld.hitMap.cells {
            guard let blocker = cell.staticBlocker,
                  let center = gridGeometry.center(of: cell.point) else { continue }
            let node: SKNode
            switch blocker {
            case .rubble:
                node = makeDebrisSprite(named: "DebrisPlaster", width: tileSide * 0.94)
            case .brokenBoards:
                node = makeDebrisSprite(named: "DebrisWoodSlats", width: tileSide * 0.96)
            case .discardedPapers:
                node = makeDebrisSprite(named: "DebrisPapers", width: tileSide * 0.82)
            case .frontColumn:
                node = SKNode()
            }
            node.position = CGPoint(x: center.x, y: center.y)
            node.zPosition = 45 + CGFloat(renderedWorld.hitMap.layout.depth - cell.point.y)
            staticBlockerRoot.addChild(node)
        }
    }

    private func buildFixtures() {
        for fixture in renderedFixtures {
            fixtureRoot.addChild(makeFixtureNode(
                kind: fixture.kind,
                origin: fixture.origin,
                rotation: fixture.rotation,
                isPreview: false,
                isValid: true
            ))
        }
    }

    private func buildPlacement() {
        guard let preview = renderedPreview else { return }
        addPlacementGrid(isValid: renderedPreviewIsValid)
        placementRoot.addChild(makeFixtureNode(
            kind: preview.kind,
            origin: preview.origin,
            rotation: preview.rotation,
            isPreview: true,
            isValid: renderedPreviewIsValid
        ))
    }

    private func buildForegroundArchitecture() {
        addSideWall(named: "SideWallLeft", capName: "CutawayCapLeft", isLeft: true)
        addSideWall(named: "SideWallRight", capName: "CutawayCapRight", isLeft: false)

        let facadeHeight = tileSide * MountingCalibration.facadeHeightInTiles
        let facadeCenterY = floorRect.minY - facadeHeight * 0.49
        let windowWidth = floorRect.width * MountingCalibration.facadeWidthFraction
        let entranceWidth = tileSide * MountingCalibration.facadeEntranceWidthInTiles
        let overlap = tileSide * 0.16

        let entrance = sprite(named: "FacadeEntranceBay", targetWidth: entranceWidth)
        entrance.position = CGPoint(x: 0, y: facadeCenterY)
        entrance.zPosition = 184
        foregroundArchitectureRoot.addChild(entrance)

        for isRight in [false, true] {
            let window = sprite(named: "FacadeWindowBay", targetWidth: windowWidth)
            window.xScale = isRight ? -1 : 1
            let direction: CGFloat = isRight ? 1 : -1
            window.position = CGPoint(
                x: direction * (entranceWidth / 2 + windowWidth / 2 - overlap),
                y: facadeCenterY + tileSide * 0.02
            )
            window.zPosition = 182
            foregroundArchitectureRoot.addChild(window)
        }

        for isRight in [false, true] {
            let post = sprite(named: "FacadeCornerPost", targetHeight: facadeHeight)
            post.xScale = isRight ? -1 : 1
            let direction: CGFloat = isRight ? 1 : -1
            post.position = CGPoint(
                x: direction * (floorRect.width / 2 + post.size.width * 0.18),
                y: facadeCenterY
            )
            post.zPosition = 188
            foregroundArchitectureRoot.addChild(post)
        }
    }

    private func addPlacementGrid(isValid: Bool) {
        let lineColor = isValid
            ? SKColor(red: 0.25, green: 0.95, blue: 0.68, alpha: 0.68)
            : SKColor(red: 1.0, green: 0.35, blue: 0.25, alpha: 0.68)

        for x in 0...renderedWorld.hitMap.layout.width {
            let offset = floorRect.minX + CGFloat(x) * tileSide
            addGridLine(
                from: CGPoint(x: offset, y: floorRect.minY),
                to: CGPoint(x: offset, y: floorRect.maxY),
                color: lineColor
            )
        }
        for y in 0...renderedWorld.hitMap.layout.depth {
            let offset = floorRect.minY + CGFloat(y) * tileSide
            addGridLine(
                from: CGPoint(x: floorRect.minX, y: offset),
                to: CGPoint(x: floorRect.maxX, y: offset),
                color: lineColor
            )
        }
    }

    private func makeFixtureNode(
        kind: FixtureKind,
        origin: GridPoint,
        rotation: FixtureRotation,
        isPreview: Bool,
        isValid: Bool
    ) -> SKNode {
        let definition = FixtureCatalog.definition(for: kind)
        let footprint = definition.footprint.rotated(rotation)
        let footprintSize = CGSize(
            width: CGFloat(footprint.width) * tileSide,
            height: CGFloat(footprint.depth) * tileSide
        )
        let center = CGPoint(
            x: floorRect.minX + (CGFloat(origin.x) + CGFloat(footprint.width) / 2) * tileSide,
            y: floorRect.minY + (CGFloat(origin.y) + CGFloat(footprint.depth) / 2) * tileSide
        )

        let highlight = SKShapeNode(
            rectOf: CGSize(width: footprintSize.width - 2, height: footprintSize.height - 2),
            cornerRadius: 4
        )
        highlight.fillColor = isValid
            ? SKColor(red: 0.12, green: 0.82, blue: 0.56, alpha: isPreview ? 0.28 : 0)
            : SKColor(red: 0.94, green: 0.22, blue: 0.17, alpha: 0.34)
        highlight.strokeColor = isValid
            ? SKColor(red: 0.34, green: 1.0, blue: 0.72, alpha: isPreview ? 0.95 : 0)
            : SKColor(red: 1.0, green: 0.40, blue: 0.30, alpha: 0.95)
        highlight.lineWidth = isPreview ? 2 : 0
        highlight.position = center
        highlight.zPosition = 80

        let sprite: SKSpriteNode
        switch kind {
        case .basicDisplayTable:
            sprite = SKSpriteNode(imageNamed: "BasicDisplayTable")
            sprite.size = CGSize(width: tileSide * 0.84, height: tileSide * 0.89)
        case .simpleShelf:
            sprite = SKSpriteNode(imageNamed: "SimpleShelf")
            sprite.size = CGSize(
                width: footprintSize.width * 0.93,
                height: max(tileSide * 1.38, footprintSize.height * 0.93)
            )
        }
        sprite.position = CGPoint(
            x: center.x,
            y: center.y + (kind == .simpleShelf ? tileSide * 0.42 : tileSide * 0.20)
        )
        sprite.zRotation = CGFloat(rotation.rawValue) * .pi / 180
        sprite.alpha = isPreview ? 0.74 : 1
        sprite.zPosition = 82 + CGFloat(renderedWorld.hitMap.layout.depth - origin.y)

        let group = SKNode()
        group.addChild(highlight)
        group.addChild(sprite)
        return group
    }

    private func addSideWall(named wallName: String, capName: String, isLeft: Bool) {
        let targetHeight = floorRect.height * MountingCalibration.sideDepthScale
        let wall = sprite(named: wallName, targetHeight: targetHeight)
        let cap = sprite(named: capName, targetHeight: targetHeight)
        let direction: CGFloat = isLeft ? -1 : 1
        wall.position = CGPoint(
            x: direction * (floorRect.width / 2 + wall.size.width * 0.34),
            y: floorRect.midY
        )
        wall.zPosition = 140
        cap.position = CGPoint(
            x: direction * (floorRect.width / 2 + cap.size.width * 0.31),
            y: floorRect.midY
        )
        cap.zPosition = 156
        foregroundArchitectureRoot.addChild(wall)
        foregroundArchitectureRoot.addChild(cap)
    }

    private func addGridLine(from start: CGPoint, to end: CGPoint, color: SKColor) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        let line = SKShapeNode(path: path)
        line.strokeColor = color
        line.lineWidth = 1
        line.zPosition = 70
        placementRoot.addChild(line)
    }

    private func makeDebrisSprite(named name: String, width: CGFloat) -> SKSpriteNode {
        let debris = sprite(named: name, targetWidth: width)
        debris.alpha = 0.96
        return debris
    }

    private func sprite(named name: String, targetWidth: CGFloat) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: name)
        let naturalSize = texture.size()
        let aspect = naturalSize.width > 0 ? naturalSize.height / naturalSize.width : 1
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: targetWidth, height: targetWidth * aspect)
        return sprite
    }

    private func sprite(named name: String, targetHeight: CGFloat) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: name)
        let naturalSize = texture.size()
        let aspect = naturalSize.height > 0 ? naturalSize.width / naturalSize.height : 1
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: targetHeight * aspect, height: targetHeight)
        return sprite
    }
}
