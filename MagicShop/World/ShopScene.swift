import SpriteKit

final class ShopScene: SKScene {
    private enum BackgroundCalibration {
        static let floorWidthFraction: CGFloat = 0.70
        static let floorHeightFraction: CGFloat = 0.31
        static let floorCenterYOffsetFraction: CGFloat = 0.012
    }

    private let worldRoot = SKNode()
    private let backgroundRoot = SKNode()
    private let fixtureRoot = SKNode()
    private let placementRoot = SKNode()
    private let worldCamera = SKCameraNode()

    private var renderedWorld = ShopWorldState.starter
    private var renderedFixtures: [PlacedFixture] = []
    private var renderedPreview: PlacementDraft?
    private var renderedPreviewIsValid = false

    private var backgroundSize: CGSize {
        let textureSize = SKTexture(imageNamed: "StarterShopBackground").size()
        guard textureSize.width > 0, textureSize.height > 0,
              size.width > 0, size.height > 0 else { return size }
        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }

    private var tileSide: CGFloat {
        let layout = renderedWorld.hitMap.layout
        let fittedWidth = backgroundSize.width * BackgroundCalibration.floorWidthFraction
            / CGFloat(layout.width)
        let fittedHeight = backgroundSize.height * BackgroundCalibration.floorHeightFraction
            / CGFloat(layout.depth)
        return max(1, min(fittedWidth, fittedHeight))
    }

    private var gridGeometry: WorldGridGeometry {
        let layout = renderedWorld.hitMap.layout
        let verticalOffset = backgroundSize.height * BackgroundCalibration.floorCenterYOffsetFraction
        return WorldGridGeometry(
            layout: layout,
            tileSide: Double(tileSide),
            origin: WorldPoint(
                x: -Double(layout.width) * Double(tileSide) / 2,
                y: -Double(layout.depth) * Double(tileSide) / 2 + Double(verticalOffset)
            )
        )
    }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.25, green: 0.20, blue: 0.14, alpha: 1)

        addChild(worldRoot)
        worldRoot.addChild(backgroundRoot)
        worldRoot.addChild(fixtureRoot)
        worldRoot.addChild(placementRoot)

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
        backgroundRoot.removeAllChildren()
        fixtureRoot.removeAllChildren()
        placementRoot.removeAllChildren()

        buildApprovedBackground()
        buildFixtures()
        buildPlacement()
    }

    private func buildApprovedBackground() {
        let background = SKSpriteNode(imageNamed: "StarterShopBackground")
        background.size = backgroundSize
        background.position = .zero
        background.zPosition = -100
        backgroundRoot.addChild(background)
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
        placementRoot.addChild(makeFixtureNode(
            kind: preview.kind,
            origin: preview.origin,
            rotation: preview.rotation,
            isPreview: true,
            isValid: renderedPreviewIsValid
        ))
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
        let centerPoint = gridGeometry.center(of: origin)
            ?? WorldPoint(x: 0, y: 0)
        let center = CGPoint(
            x: CGFloat(centerPoint.x) + (CGFloat(footprint.width) - 1) * tileSide / 2,
            y: CGFloat(centerPoint.y) + (CGFloat(footprint.depth) - 1) * tileSide / 2
        )

        let highlight = SKShapeNode(
            rectOf: CGSize(width: footprintSize.width - 2, height: footprintSize.height - 2),
            cornerRadius: 4
        )
        highlight.fillColor = isValid
            ? SKColor(red: 0.12, green: 0.82, blue: 0.56, alpha: isPreview ? 0.20 : 0)
            : SKColor(red: 0.94, green: 0.22, blue: 0.17, alpha: 0.30)
        highlight.strokeColor = isValid
            ? SKColor(red: 0.34, green: 1.0, blue: 0.72, alpha: isPreview ? 0.85 : 0)
            : SKColor(red: 1.0, green: 0.40, blue: 0.30, alpha: 0.90)
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
}
