import Foundation

/// Customer routing uses the same saved hitmap and furniture occupancy as
/// placement. No SpriteKit coordinates or visual assumptions enter the rules.
public enum ShopAccess {
    public static func reachableCells(in state: GameState) -> Set<GridPoint> {
        Set(traversal(in: state).order)
    }

    public static func isReachable(_ fixture: PlacedFixture, in state: GameState) -> Bool {
        let reachable = reachableCells(in: state)
        return PlacementRules.occupiedCells(for: fixture).contains { cell in
            neighbors(of: cell).contains { reachable.contains($0) }
        }
    }

    /// A deterministic shortest walk from an entrance to a free cardinal
    /// neighbor of the furniture. The occupied furniture itself is never walked.
    public static func path(to fixture: PlacedFixture, in state: GameState) -> [GridPoint]? {
        let search = traversal(in: state)
        let adjacent = Set(PlacementRules.occupiedCells(for: fixture).flatMap { neighbors(of: $0) })
        guard let destination = search.order.first(where: { adjacent.contains($0) }) else {
            return nil
        }
        var route = [destination]
        var current = destination
        while let previous = search.parents[current] {
            route.append(previous)
            current = previous
        }
        return route.reversed()
    }

    private static func traversal(in state: GameState)
        -> (order: [GridPoint], parents: [GridPoint: GridPoint]) {
        let map = state.world.hitMap
        let occupied = map.dynamicOccupancy(fixtures: state.fixtures)
        let walkable = Set(map.cells.filter {
            $0.staticBlocker == nil && occupied[$0.point] == nil
        }.map(\.point))
        let entranceCells: [WorldCellMetadata] = map.cells.filter { cell in
            cell.zone == .entrance && walkable.contains(cell.point)
        }
        let entrancePoints: [GridPoint] = entranceCells.map { $0.point }
        let entrances: [GridPoint] = entrancePoints.sorted { left, right in
            if left.y == right.y { return left.x < right.x }
            return left.y < right.y
        }
        var queue = entrances
        var visited = Set(entrances)
        var parents: [GridPoint: GridPoint] = [:]
        var cursor = 0
        while cursor < queue.count {
            let point = queue[cursor]
            cursor += 1
            for next in neighbors(of: point) where walkable.contains(next) {
                if visited.insert(next).inserted {
                    parents[next] = point
                    queue.append(next)
                }
            }
        }
        return (queue, parents)
    }

    private static func neighbors(of point: GridPoint) -> [GridPoint] {
        [
            GridPoint(x: point.x, y: point.y + 1),
            GridPoint(x: point.x - 1, y: point.y),
            GridPoint(x: point.x + 1, y: point.y),
            GridPoint(x: point.x, y: point.y - 1)
        ]
    }
}
