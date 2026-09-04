import Foundation

/// A single owner commits each command to disk before making it visible.
/// Failed commands and failed writes leave the live engine unchanged.
public final class GameSession {
    public private(set) var engine: GameEngine
    private let store: any GameStateStore

    public init(store: any GameStateStore) throws {
        self.store = store
        let state = try store.load()
        try state.validateIntegrity()
        engine = GameEngine(state: state)
    }

    @discardableResult
    public func commit<Result>(_ command: (inout GameEngine) throws -> Result) throws -> Result {
        var candidate = engine
        let result = try command(&candidate)
        try candidate.state.validateIntegrity()
        try store.save(candidate.state)
        engine = candidate
        return result
    }
}