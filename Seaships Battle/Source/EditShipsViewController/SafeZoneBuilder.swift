import Foundation

struct SafeZoneBuilder {
    public static func createSafeZone(around ship: [IndexPath], state: ShipState) -> [IndexPath] {
        guard let first = ship.first, let last = ship.last else { return [] }
        var array: [IndexPath] = []
        switch state {
        case .horisontal:
            array = first.aslantElements +
                    last.aslantElements +
                    Self.verticalZone(point: first) +
                    Self.verticalZone(point: last) +
                    [first.add(item: -1)] +
                    [last.add(item: 1)]
        case .vertical:
            array = first.aslantElements +
                    last.aslantElements +
                    Self.horizontalZone(point: first) +
                    Self.horizontalZone(point: last) +
                    [first.add(section: -1)] +
                    [last.add(section: 1)]
        }
    
        return Array(Set(array)).filter(startIndex: 0, endIndex: 9)
    }
    
    private static func verticalZone(point: IndexPath) -> [IndexPath] {
        return [point.add(section: -1), point.add(section: 1)]
    }
    
    private static func horizontalZone(point: IndexPath) -> [IndexPath] {
        return [point.add(item: -1), point.add(item: 1)]
    }
}
