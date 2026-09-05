import SpriteKit
import SwiftUI
import UIKit

enum ShopWorldTool: Equatable {
    case none
    case clean
    case paint
}

/// App owns transactions. Gestures only propose a draft, a drop, or one cell
/// of a tool stroke; they never move saved furniture or spend money directly.
struct ShopSceneContainer: UIViewRepresentable {
    let state: GameState
    let preview: PlacementDraft?
    let previewIsValid: Bool
    let selectedFixtureID: UUID?
    let activeVisit: CustomerVisit?
    let visitProgress: Double
    let lastOutcome: VisitOutcome?
    let presentationMinute: Double?
    let interactionTool: ShopWorldTool
    let floorPreview: [GridPoint]
    let floorPreviewStyle: FloorStyleID?
    let reduceMotion: Bool
    let isPaused: Bool
    let cameraResetID: Int
    let contentLift: CGFloat
    let onGridTap: (GridPoint) -> Void
    let onFixtureTap: (UUID) -> Void
    let onDragStart: (UUID) -> Bool
    let onDragMove: (GridPoint) -> Void
    let onDragEnd: (Bool) -> Void
    let onToolStroke: (GridPoint) -> Void

    init(
        state: GameState,
        preview: PlacementDraft? = nil,
        previewIsValid: Bool = false,
        selectedFixtureID: UUID? = nil,
        activeVisit: CustomerVisit? = nil,
        visitProgress: Double = 0,
        lastOutcome: VisitOutcome? = nil,
        presentationMinute: Double? = nil,
        interactionTool: ShopWorldTool = .none,
        floorPreview: [GridPoint] = [],
        floorPreviewStyle: FloorStyleID? = nil,
        reduceMotion: Bool = false,
        isPaused: Bool = false,
        cameraResetID: Int = 0,
        contentLift: CGFloat = 0,
        onGridTap: @escaping (GridPoint) -> Void = { _ in },
        onFixtureTap: @escaping (UUID) -> Void = { _ in },
        onDragStart: @escaping (UUID) -> Bool = { _ in false },
        onDragMove: @escaping (GridPoint) -> Void = { _ in },
        onDragEnd: @escaping (Bool) -> Void = { _ in },
        onToolStroke: @escaping (GridPoint) -> Void = { _ in }
    ) {
        self.state = state
        self.preview = preview
        self.previewIsValid = previewIsValid
        self.selectedFixtureID = selectedFixtureID
        self.activeVisit = activeVisit
        self.visitProgress = visitProgress
        self.lastOutcome = lastOutcome
        self.presentationMinute = presentationMinute
        self.interactionTool = interactionTool
        self.floorPreview = floorPreview
        self.floorPreviewStyle = floorPreviewStyle
        self.reduceMotion = reduceMotion
        self.isPaused = isPaused
        self.cameraResetID = cameraResetID
        self.contentLift = contentLift
        self.onGridTap = onGridTap
        self.onFixtureTap = onFixtureTap
        self.onDragStart = onDragStart
        self.onDragMove = onDragMove
        self.onDragEnd = onDragEnd
        self.onToolStroke = onToolStroke
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ShopAccessibleView {
        let view = ShopAccessibleView(frame: .zero)
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.presentScene(context.coordinator.scene)
        view.isAccessibilityElement = false
        view.accessibilityIdentifier = "shop-world"
        context.coordinator.accessibleView = view
        view.accessibilityLabel = "Shop floor"
        view.accessibilityTraits = []
        view.accessibilityHint = "Swipe up or down to zoom. More actions move or reset the camera. Build, Stock and Care also provide buttons for arranging and cleaning."
        view.adjustZoom = { [weak coordinator = context.coordinator] increase in
            coordinator?.zoom(increase ? 1.15 : 1 / 1.15)
        }
        view.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Zoom in", target: context.coordinator, selector: #selector(Coordinator.zoomIn)),
            UIAccessibilityCustomAction(name: "Zoom out", target: context.coordinator, selector: #selector(Coordinator.zoomOut)),
            UIAccessibilityCustomAction(name: "Look toward rear wall", target: context.coordinator, selector: #selector(Coordinator.lookRear)),
            UIAccessibilityCustomAction(name: "Look toward entrance", target: context.coordinator, selector: #selector(Coordinator.lookEntrance)),
            UIAccessibilityCustomAction(name: "Reset camera", target: context.coordinator, selector: #selector(Coordinator.resetCameraAction))
        ]
        context.coordinator.installGestures(on: view)
        return view
    }

    func updateUIView(_ view: ShopAccessibleView, context: Context) {
        let coordinator = context.coordinator
        if view.bounds.width > 0, view.bounds.height > 0,
           coordinator.scene.size != view.bounds.size {
            coordinator.scene.size = view.bounds.size
        }
        if (isPaused && !coordinator.wasPaused) || coordinator.tool != interactionTool {
            coordinator.cancelInteraction(deferred: true)
        }
        coordinator.wasPaused = isPaused
        coordinator.onGridTap = onGridTap
        coordinator.onFixtureTap = onFixtureTap
        coordinator.onDragStart = onDragStart
        coordinator.onDragMove = onDragMove
        coordinator.onDragEnd = onDragEnd
        coordinator.onToolStroke = onToolStroke
        coordinator.preview = preview
        coordinator.fixtureOrigins = Dictionary(uniqueKeysWithValues: state.fixtures.map { ($0.id, $0.origin) })
        coordinator.tool = interactionTool
        coordinator.hasExpansion = state.restoration.expansion != nil
        coordinator.contentLift = contentLift
        coordinator.scene.render(
            state: state, preview: preview, previewIsValid: previewIsValid,
            selectedFixtureID: selectedFixtureID, activeVisit: activeVisit,
            visitProgress: visitProgress, lastOutcome: lastOutcome,
            reduceMotion: reduceMotion, presentationMinute: presentationMinute,
            floorPreview: floorPreview, floorPreviewStyle: floorPreviewStyle
        )
        if coordinator.resetID != cameraResetID {
            coordinator.resetID = cameraResetID
            coordinator.resetCamera()
        }
        coordinator.applyCamera()
        view.isPaused = isPaused
        view.updateWorldAccessibility(scene: coordinator.scene, fixtures: state.fixtures,
                                      preview: preview, tool: interactionTool,
                                      onFixtureTap: onFixtureTap, onToolStroke: onToolStroke)
        view.worldDescription = "\(state.fixtures.count) pieces of furniture, \(state.stock.count) items stocked. Zoom \(Int(100 / coordinator.cameraState.zoom)) percent."
    }

    static func dismantleUIView(_ view: ShopAccessibleView, coordinator: Coordinator) {
        coordinator.cancelInteraction(deferred: true)
        view.presentScene(nil)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let scene = ShopScene(size: UIScreen.main.bounds.size)
        weak var accessibleView: ShopAccessibleView?
        var onGridTap: ((GridPoint) -> Void)?
        var onFixtureTap: ((UUID) -> Void)?
        var onDragStart: ((UUID) -> Bool)?
        var onDragMove: ((GridPoint) -> Void)?
        var onDragEnd: ((Bool) -> Void)?
        var onToolStroke: ((GridPoint) -> Void)?
        var preview: PlacementDraft?
        var fixtureOrigins: [UUID: GridPoint] = [:]
        var tool: ShopWorldTool = .none
        var hasExpansion = false
        var wasPaused = false
        var contentLift: CGFloat = 0
        var resetID = 0
        private(set) var cameraState = WorldCameraState()
        private var horizontalOffset: CGFloat = 0
        private weak var singlePan: UIPanGestureRecognizer?
        private weak var cameraPan: UIPanGestureRecognizer?
        private weak var fixturePress: UILongPressGestureRecognizer?
        private var singleTouchStart = CGPoint.zero
        private var dragging = false
        private var pressingFixture = false
        private var dragContentLift: CGFloat?
        private var dragOffset = GridPoint(x: 0, y: 0)
        private var lastDragOrigin: GridPoint?
        private var strokeCells = Set<GridPoint>()
        private var lastStrokeCell: GridPoint?
        private var singleMode: SingleMode = .none

        private enum SingleMode: Equatable { case none, camera, drag, stroke }

        func installGestures(on view: UIView) {
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.delegate = self
            view.addGestureRecognizer(pinch)

            let twoPan = UIPanGestureRecognizer(target: self, action: #selector(handleCameraPan(_:)))
            twoPan.minimumNumberOfTouches = 2
            twoPan.maximumNumberOfTouches = 2
            twoPan.delegate = self
            view.addGestureRecognizer(twoPan)
            cameraPan = twoPan

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSinglePan(_:)))
            pan.maximumNumberOfTouches = 1
            pan.delegate = self
            view.addGestureRecognizer(pan)
            singlePan = pan

            let press = UILongPressGestureRecognizer(target: self, action: #selector(handleFixturePress(_:)))
            press.minimumPressDuration = 0.18
            press.allowableMovement = 14
            press.numberOfTouchesRequired = 1
            press.delegate = self
            view.addGestureRecognizer(press)
            fixturePress = press

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.require(toFail: pan)
            tap.require(toFail: press)
            tap.delegate = self
            view.addGestureRecognizer(tap)
        }

        @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            if recognizer.state == .began { cancelInteraction() }
            guard recognizer.state == .began || recognizer.state == .changed else { return }
            zoom(Double(recognizer.scale))
            recognizer.scale = 1
        }

        @objc private func handleCameraPan(_ recognizer: UIPanGestureRecognizer) {
            if recognizer.state == .began { cancelInteraction() }
            guard recognizer.state == .began || recognizer.state == .changed else { return }
            panCamera(recognizer)
        }

        @objc private func handleSinglePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let point = scene.convertPoint(fromView: recognizer.location(in: view))
            if recognizer.state == .began {
                if tool != .none {
                    singleMode = .stroke
                    strokeCells.removeAll()
                    lastStrokeCell = nil
                    stroke(at: scene.convertPoint(fromView: singleTouchStart))
                } else if let draft = preview {
                    let initial = scene.convertPoint(fromView: singleTouchStart)
                    singleMode = beginDrag(id: draft.fixtureID, origin: draft.origin, at: initial) ? .drag : .none
                } else {
                    singleMode = .camera
                }
            }
            if recognizer.state == .began || recognizer.state == .changed {
                switch singleMode {
                case .drag: moveDrag(to: point)
                case .stroke: stroke(at: point)
                case .camera: panCamera(recognizer)
                case .none: break
                }
            } else if recognizer.state == .ended {
                if singleMode == .drag { moveDrag(to: point); finishDrag(drop: true) }
                if singleMode == .stroke { stroke(at: point) }
                clearStroke()
                singleMode = .none
            } else if recognizer.state == .cancelled || recognizer.state == .failed {
                if singleMode != .none { cancelInteraction() }
            }
        }

        @objc private func handleFixturePress(_ recognizer: UILongPressGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let point = scene.convertPoint(fromView: recognizer.location(in: view))
            switch recognizer.state {
            case .began:
                guard let id = scene.fixtureID(at: point), let origin = fixtureOrigins[id] else { return }
                pressingFixture = beginDrag(id: id, origin: origin, at: point)
            case .changed:
                if pressingFixture { moveDrag(to: point) }
            case .ended:
                if pressingFixture { moveDrag(to: point); finishDrag(drop: true) }
            case .cancelled, .failed:
                if pressingFixture { finishDrag(drop: false) }
            default: break
            }
        }

        private func beginDrag(id: UUID, origin: GridPoint, at point: CGPoint) -> Bool {
            guard let cell = scene.dragGridPoint(at: point), onDragStart?(id) == true else { return false }
            dragging = true
            dragContentLift = contentLift
            dragOffset = GridPoint(x: cell.x - origin.x, y: cell.y - origin.y)
            lastDragOrigin = origin
            return true
        }

        private func moveDrag(to point: CGPoint) {
            guard dragging, let cell = scene.dragGridPoint(at: point) else { return }
            let origin = GridPoint(x: cell.x - dragOffset.x, y: cell.y - dragOffset.y)
            guard origin != lastDragOrigin else { return }
            lastDragOrigin = origin
            onDragMove?(origin)
        }

        private func finishDrag(drop: Bool, deferred: Bool = false) {
            guard dragging else { return }
            dragging = false
            pressingFixture = false
            dragContentLift = nil
            lastDragOrigin = nil
            let callback = onDragEnd
            if deferred { DispatchQueue.main.async { callback?(drop) } }
            else { callback?(drop) }
        }

        func cancelInteraction(deferred: Bool = false) {
            finishDrag(drop: false, deferred: deferred)
            clearStroke()
            singleMode = .none
        }

        private func clearStroke() {
            strokeCells.removeAll()
            lastStrokeCell = nil
        }

        private func stroke(at point: CGPoint) {
            guard let cell = scene.gridPoint(fromWorldPoint: WorldPoint(x: Double(point.x), y: Double(point.y))) else {
                lastStrokeCell = nil
                return
            }
            let start = lastStrokeCell ?? cell
            let steps = max(abs(cell.x - start.x), abs(cell.y - start.y))
            // Fill gaps in fast strokes. Each cell is proposed once per gesture;
            // Core independently validates placement, price and remaining funds.
            for step in 0...max(1, steps) {
                let fraction = steps == 0 ? 0 : Double(step) / Double(steps)
                let next = GridPoint(x: Int((Double(start.x) + Double(cell.x - start.x) * fraction).rounded()),
                                     y: Int((Double(start.y) + Double(cell.y - start.y) * fraction).rounded()))
                if strokeCells.insert(next).inserted { onToolStroke?(next) }
            }
            lastStrokeCell = cell
        }

        private func panCamera(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let translation = recognizer.translation(in: view)
            cameraState.panVertically(by: Double(translation.y) * cameraState.zoom)
            if hasExpansion {
                horizontalOffset -= translation.x * CGFloat(cameraState.zoom)
                horizontalOffset = min(max(horizontalOffset, -scene.horizontalPanLimit), scene.horizontalPanLimit)
            }
            recognizer.setTranslation(.zero, in: view)
            applyCamera()
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, let view = recognizer.view else { return }
            let point = scene.convertPoint(fromView: recognizer.location(in: view))
            guard !dragging else { return }
            if tool != .none {
                if let cell = scene.gridPoint(fromWorldPoint: WorldPoint(x: Double(point.x), y: Double(point.y))) {
                    onToolStroke?(cell)
                }
            } else if preview == nil, let id = scene.fixtureID(at: point) {
                onFixtureTap?(id)
            } else if let cell = scene.gridPoint(fromWorldPoint: WorldPoint(x: Double(point.x), y: Double(point.y))) {
                onGridTap?(cell)
            }
        }

        func zoom(_ multiplier: Double) {
            cameraState.applyPinch(multiplier: multiplier)
            applyCamera()
        }

        func resetCamera() {
            cancelInteraction()
            cameraState = WorldCameraState()
            horizontalOffset = 0
            applyCamera()
        }

        func applyCamera() {
            scene.apply(cameraState, horizontalOffset: hasExpansion ? horizontalOffset : 0,
                        contentLift: dragContentLift ?? contentLift)
            accessibleView?.updateCameraFrames(scene: scene)
        }

        @objc func zoomIn() -> Bool { zoom(1.15); return true }
        @objc func zoomOut() -> Bool { zoom(1 / 1.15); return true }
        @objc func lookRear() -> Bool { cameraState.panVertically(by: 70); applyCamera(); return true }
        @objc func lookEntrance() -> Bool { cameraState.panVertically(by: -70); applyCamera(); return true }
        @objc func resetCameraAction() -> Bool { resetCamera(); return true }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if gestureRecognizer === singlePan { singleTouchStart = touch.location(in: gestureRecognizer.view) }
            return true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let view = gestureRecognizer.view else { return false }
            let point = scene.convertPoint(fromView: gestureRecognizer === singlePan
                ? singleTouchStart : gestureRecognizer.location(in: view))
            if gestureRecognizer === fixturePress {
                return tool == .none && preview == nil && scene.fixtureID(at: point) != nil
            }
            if gestureRecognizer === singlePan {
                if tool != .none { return true }
                if preview != nil { return scene.previewContains(point) }
                return scene.fixtureID(at: point) == nil
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            gestureRecognizer is UIPinchGestureRecognizer || other is UIPinchGestureRecognizer
                || gestureRecognizer === cameraPan || other === cameraPan
        }
    }
}

// SKView exposes its own scene-node accessibility tree and overrides custom
// container children. A UIKit host keeps real fixture/tile targets authoritative.
final class ShopAccessibleView: UIView {
    private let spriteView = SKView()
    var worldDescription = ""
    var ignoresSiblingOrder: Bool {
        get { spriteView.ignoresSiblingOrder }
        set { spriteView.ignoresSiblingOrder = newValue }
    }
    var preferredFramesPerSecond: Int {
        get { spriteView.preferredFramesPerSecond }
        set { spriteView.preferredFramesPerSecond = newValue }
    }
    var isPaused: Bool {
        get { spriteView.isPaused }
        set { spriteView.isPaused = newValue }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        spriteView.isMultipleTouchEnabled = true
        isAccessibilityElement = false
        spriteView.frame = bounds
        spriteView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        spriteView.backgroundColor = .clear
        spriteView.isAccessibilityElement = false
        spriteView.accessibilityElementsHidden = true
        addSubview(spriteView)
    }
    required init?(coder: NSCoder) { nil }
    func presentScene(_ scene: SKScene?) { spriteView.presentScene(scene) }
    override func layoutSubviews() {
        super.layoutSubviews()
        spriteView.frame = bounds
        if let scene = spriteView.scene as? ShopScene {
            if bounds.width > 0, bounds.height > 0, scene.size != bounds.size { scene.size = bounds.size }
            updateCameraFrames(scene: scene)
        }
    }

    var adjustZoom: ((Bool) -> Void)?
    private lazy var cameraElement = ShopWorldAccessibilityElement(accessibilityContainer: self)
    private var fixtureElements: [UUID: ShopWorldAccessibilityElement] = [:]
    private let previewElementLabel = "Placement preview"
    private lazy var previewElement = ShopWorldAccessibilityElement(accessibilityContainer: self)
    private var currentFixtures: [PlacedFixture] = []
    private var currentTool: ShopWorldTool = .none
    private var cellElements: [GridPoint: ShopWorldAccessibilityElement] = [:]
    private var applyTool: ((GridPoint) -> Void)?
    private var currentPreview: PlacementDraft?
    private var selectFixture: ((UUID) -> Void)?

    func updateWorldAccessibility(scene: ShopScene, fixtures: [PlacedFixture], preview: PlacementDraft?,
                                  tool: ShopWorldTool, onFixtureTap: @escaping (UUID) -> Void,
                                  onToolStroke: @escaping (GridPoint) -> Void) {
        currentFixtures = fixtures
        currentTool = tool
        applyTool = onToolStroke
        currentPreview = preview
        selectFixture = onFixtureTap
        updateCameraFrames(scene: scene)
    }

    func updateCameraFrames(scene: ShopScene) {
        let frames = Dictionary(uniqueKeysWithValues: scene.accessibilityFixtureFrames())
        var elements: [UIAccessibilityElement] = []
        if currentTool != .none {
            for (point, frame) in scene.accessibilityCellFrames() {
                let visible = frame.intersection(bounds)
                guard !visible.isNull, visible.width > 1, visible.height > 1 else { continue }
                let element = cellElements[point] ?? ShopWorldAccessibilityElement(accessibilityContainer: self)
                cellElements[point] = element
                element.accessibilityIdentifier = "world-cell-\(point.x)-\(point.y)"
                element.accessibilityLabel = "Floor tile \(point.x), \(point.y)"
                element.accessibilityHint = currentTool == .clean ? "Clean this tile" : "Select this tile for the new floor"
                element.accessibilityTraits = .button
                element.accessibilityFrameInContainerSpace = visible
                element.activate = { [weak self] in self?.applyTool?(point); return true }
                elements.append(element)
            }
        }
        fixtureElements = fixtureElements.filter { frames[$0.key] != nil }
        for fixture in currentFixtures where currentTool == .none {
            guard let frame = frames[fixture.id] else { continue }
            let visible = frame.intersection(bounds)
            guard !visible.isNull, visible.width > 1, visible.height > 1 else { continue }
            let element = fixtureElements[fixture.id]
                ?? ShopWorldAccessibilityElement(accessibilityContainer: self)
            fixtureElements[fixture.id] = element
            element.accessibilityIdentifier = "fixture-world-\(fixture.id.uuidString)"
            element.accessibilityLabel = FixtureCatalog.definition(for: fixture.kind).displayName
            element.accessibilityHint = "Select to open furniture controls. Touch and hold to drag."
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace = visible
            element.activate = { [weak self] in self?.selectFixture?(fixture.id); return true }
            elements.append(element)
        }
        if let preview = currentPreview, let frame = scene.accessibilityPreviewFrame() {
            previewElement.accessibilityIdentifier = "world-placement-preview"
            previewElement.accessibilityLabel = "\(previewElementLabel), \(FixtureCatalog.definition(for: preview.kind).displayName)"
            previewElement.accessibilityHint = "Drag to arrange, or use the placement direction buttons."
            previewElement.accessibilityTraits = .image
            previewElement.accessibilityFrameInContainerSpace = frame.intersection(bounds)
            elements.append(previewElement)
        }
        cameraElement.accessibilityIdentifier = "world-camera"
        cameraElement.accessibilityLabel = "Shop floor camera"
        cameraElement.accessibilityTraits = [.image, .adjustable]
        cameraElement.accessibilityHint = "Swipe up or down to zoom. More actions move or reset the camera. Build, Stock and Care also provide buttons for arranging and cleaning."
        cameraElement.accessibilityValue = worldDescription
        cameraElement.accessibilityFrameInContainerSpace = bounds
        cameraElement.accessibilityCustomActions = accessibilityCustomActions
        cameraElement.adjust = { [weak self] in self?.adjustZoom?($0) }
        elements.append(cameraElement)
        accessibilityElements = elements
    }

    override func accessibilityIncrement() { adjustZoom?(true) }
    override func accessibilityDecrement() { adjustZoom?(false) }
}

final class ShopWorldAccessibilityElement: UIAccessibilityElement {
    var activate: (() -> Bool)?
    var adjust: ((Bool) -> Void)?
    override func accessibilityActivate() -> Bool { activate?() ?? false }
    override func accessibilityIncrement() { adjust?(true) }
    override func accessibilityDecrement() { adjust?(false) }
}
