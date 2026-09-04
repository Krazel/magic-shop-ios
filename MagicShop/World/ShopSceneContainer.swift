import SpriteKit
import SwiftUI
import UIKit

struct ShopSceneContainer: UIViewRepresentable {
    let world: ShopWorldState
    let fixtures: [PlacedFixture]
    let preview: PlacementDraft?
    let previewIsValid: Bool
    let onGridTap: (GridPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.presentScene(context.coordinator.scene)

        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinch.delegate = context.coordinator
        view.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.scene.size = view.bounds.size
        context.coordinator.onGridTap = onGridTap
        context.coordinator.acceptsPlacementTaps = preview != nil
        context.coordinator.scene.render(
            world: world,
            fixtures: fixtures,
            preview: preview,
            previewIsValid: previewIsValid
        )
        context.coordinator.applyCamera()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let scene = ShopScene(size: UIScreen.main.bounds.size)
        var onGridTap: ((GridPoint) -> Void)?
        var acceptsPlacementTaps = false
        private var cameraState = WorldCameraState(zoom: 1.0)

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard recognizer.state == .began || recognizer.state == .changed else { return }
            cameraState.applyPinch(multiplier: Double(recognizer.scale))
            recognizer.scale = 1
            applyCamera()
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view,
                  recognizer.state == .began || recognizer.state == .changed else { return }
            let translation = recognizer.translation(in: view)
            cameraState.panVertically(by: Double(translation.y) * cameraState.zoom)
            recognizer.setTranslation(.zero, in: view)
            applyCamera()
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard acceptsPlacementTaps,
                  recognizer.state == .ended,
                  let view = recognizer.view else { return }
            let location = recognizer.location(in: view)
            let transform = CameraViewportTransform(
                width: Double(view.bounds.width),
                height: Double(view.bounds.height),
                camera: cameraState
            )
            guard let point = scene.gridPoint(
                fromWorldPoint: transform.worldPoint(
                    fromScreen: ScreenPoint(x: Double(location.x), y: Double(location.y))
                )
            ) else { return }
            onGridTap?(point)
        }

        func applyCamera() {
            scene.apply(cameraState)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
