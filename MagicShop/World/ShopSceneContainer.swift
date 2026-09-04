import SpriteKit
import SwiftUI
import UIKit

/// Native overlays own purchases and the simulated clock. This view renders
/// immutable snapshots and never advances a visit or changes the save.
struct ShopSceneContainer: UIViewRepresentable {
    let state: GameState
    let preview: PlacementDraft?
    let previewIsValid: Bool
    let selectedFixtureID: UUID?
    let activeVisit: CustomerVisit?
    let visitProgress: Double
    let lastOutcome: VisitOutcome?
    let reduceMotion: Bool
    let isPaused: Bool
    let cameraResetID: Int
    let contentLift: CGFloat
    let onGridTap: (GridPoint) -> Void
    let onFixtureTap: (UUID) -> Void

    init(
        state: GameState,
        preview: PlacementDraft? = nil,
        previewIsValid: Bool = false,
        selectedFixtureID: UUID? = nil,
        activeVisit: CustomerVisit? = nil,
        visitProgress: Double = 0,
        lastOutcome: VisitOutcome? = nil,
        reduceMotion: Bool = false,
        isPaused: Bool = false,
        cameraResetID: Int = 0,
        contentLift: CGFloat = 0,
        onGridTap: @escaping (GridPoint) -> Void = { _ in },
        onFixtureTap: @escaping (UUID) -> Void = { _ in }
    ) {
        self.state = state
        self.preview = preview
        self.previewIsValid = previewIsValid
        self.selectedFixtureID = selectedFixtureID
        self.activeVisit = activeVisit
        self.visitProgress = visitProgress
        self.lastOutcome = lastOutcome
        self.reduceMotion = reduceMotion
        self.isPaused = isPaused
        self.cameraResetID = cameraResetID
        self.contentLift = contentLift
        self.onGridTap = onGridTap
        self.onFixtureTap = onFixtureTap
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ShopAccessibleView {
        let view = ShopAccessibleView(frame: .zero)
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.presentScene(context.coordinator.scene)
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Shop floor"
        view.accessibilityTraits = [.image, .adjustable]
        view.accessibilityHint = "Swipe up or down to zoom. More actions move or reset the camera. Furniture is also available in the Build and Stock controls."
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

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        view.addGestureRecognizer(pinch)
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.require(toFail: pan)
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ view: ShopAccessibleView, context: Context) {
        let coordinator = context.coordinator
        if view.bounds.width > 0, view.bounds.height > 0,
           coordinator.scene.size != view.bounds.size {
            coordinator.scene.size = view.bounds.size
        }
        coordinator.onGridTap = onGridTap
        coordinator.onFixtureTap = onFixtureTap
        coordinator.acceptsPlacementTaps = preview != nil
        coordinator.hasExpansion = state.restoration.expansion != nil
        coordinator.contentLift = contentLift
        coordinator.scene.render(
            state: state, preview: preview, previewIsValid: previewIsValid,
            selectedFixtureID: selectedFixtureID, activeVisit: activeVisit,
            visitProgress: visitProgress, lastOutcome: lastOutcome, reduceMotion: reduceMotion
        )
        if coordinator.resetID != cameraResetID {
            coordinator.resetID = cameraResetID
            coordinator.resetCamera()
        }
        coordinator.applyCamera()
        view.isPaused = isPaused
        view.accessibilityValue = "\(state.fixtures.count) pieces of furniture, \(state.stock.count) items stocked. Zoom \(Int(100 / coordinator.cameraState.zoom)) percent."
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let scene = ShopScene(size: UIScreen.main.bounds.size)
        var onGridTap: ((GridPoint) -> Void)?
        var onFixtureTap: ((UUID) -> Void)?
        var acceptsPlacementTaps = false
        var hasExpansion = false
        var contentLift: CGFloat = 0
        var resetID = 0
        private(set) var cameraState = WorldCameraState()
        private var horizontalOffset: CGFloat = 0

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard recognizer.state == .began || recognizer.state == .changed else { return }
            zoom(Double(recognizer.scale))
            recognizer.scale = 1
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view,
                  recognizer.state == .began || recognizer.state == .changed else { return }
            let translation = recognizer.translation(in: view)
            cameraState.panVertically(by: Double(translation.y) * cameraState.zoom)
            if hasExpansion {
                horizontalOffset -= translation.x * CGFloat(cameraState.zoom)
                horizontalOffset = min(max(horizontalOffset, -scene.horizontalPanLimit), scene.horizontalPanLimit)
            }
            recognizer.setTranslation(.zero, in: view)
            applyCamera()
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, let view = recognizer.view else { return }
            // SpriteKit supplies the actual camera transform, including expansion
            // centering and native-panel framing. Projection inversion is shared
            // with the rendering geometry in ShopScene.
            let point = scene.convertPoint(fromView: recognizer.location(in: view))
            if !acceptsPlacementTaps, let fixtureID = scene.fixtureID(at: point) {
                onFixtureTap?(fixtureID)
                return
            }
            guard let cell = scene.gridPoint(fromWorldPoint: WorldPoint(x: Double(point.x), y: Double(point.y))) else { return }
            onGridTap?(cell)
        }

        func zoom(_ multiplier: Double) {
            cameraState.applyPinch(multiplier: multiplier)
            applyCamera()
        }

        func resetCamera() {
            cameraState = WorldCameraState()
            horizontalOffset = 0
            applyCamera()
        }

        func applyCamera() {
            scene.apply(cameraState, horizontalOffset: hasExpansion ? horizontalOffset : 0, contentLift: contentLift)
        }

        @objc func zoomIn() -> Bool { zoom(1.15); return true }
        @objc func zoomOut() -> Bool { zoom(1 / 1.15); return true }
        @objc func lookRear() -> Bool { cameraState.panVertically(by: 70); applyCamera(); return true }
        @objc func lookEntrance() -> Bool { cameraState.panVertically(by: -70); applyCamera(); return true }
        @objc func resetCameraAction() -> Bool { resetCamera(); return true }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            gestureRecognizer is UIPinchGestureRecognizer || otherGestureRecognizer is UIPinchGestureRecognizer
        }
    }
}

final class ShopAccessibleView: SKView {
    var adjustZoom: ((Bool) -> Void)?
    override func accessibilityIncrement() { adjustZoom?(true) }
    override func accessibilityDecrement() { adjustZoom?(false) }
}
