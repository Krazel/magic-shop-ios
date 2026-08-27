import Foundation

public protocol GameStateStore: Sendable {
    func load() throws -> GameState
    func save(_ state: GameState) throws
}

public struct FileGameStateStore: GameStateStore, Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> GameState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .initial
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(GameState.self, from: data)
    }

    public func save(_ state: GameState) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }

    public static func applicationSupport(
        fileManager: FileManager = .default
    ) throws -> FileGameStateStore {
        let baseURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return FileGameStateStore(
            fileURL: baseURL
                .appendingPathComponent("MagicShop", isDirectory: true)
                .appendingPathComponent("game-state.json", isDirectory: false)
        )
    }
}

public final class InMemoryGameStateStore: GameStateStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storedState: GameState

    public init(initialState: GameState = .initial) {
        storedState = initialState
    }

    public func load() throws -> GameState {
        lock.lock()
        defer { lock.unlock() }
        return storedState
    }

    public func save(_ state: GameState) throws {
        lock.lock()
        defer { lock.unlock() }
        storedState = state
    }
}
