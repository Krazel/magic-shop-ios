import Foundation

public struct WorldCameraState: Equatable, Sendable {
    public static let minimumZoom = 0.65
    public static let maximumZoom = 1.25
    public static let maximumVerticalOffset = 220.0

    public var zoom: Double
    public var verticalOffset: Double

    public init(zoom: Double = 1.0, verticalOffset: Double = 0.0) {
        self.zoom = Self.clampZoom(zoom)
        self.verticalOffset = Self.clampVerticalOffset(verticalOffset)
    }

    public mutating func applyPinch(multiplier: Double) {
        guard multiplier.isFinite, multiplier > 0 else { return }
        zoom = Self.clampZoom(zoom / multiplier)
    }

    public mutating func panVertically(by delta: Double) {
        guard delta.isFinite else { return }
        verticalOffset = Self.clampVerticalOffset(verticalOffset + delta)
    }

    private static func clampZoom(_ value: Double) -> Double {
        min(max(value, minimumZoom), maximumZoom)
    }

    private static func clampVerticalOffset(_ value: Double) -> Double {
        min(max(value, -maximumVerticalOffset), maximumVerticalOffset)
    }
}
