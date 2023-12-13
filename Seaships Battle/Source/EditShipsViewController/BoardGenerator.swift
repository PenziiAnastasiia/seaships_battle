import Foundation

struct BoardGenerator {
    static var generate: [IndexPath] {
        return (0...9).compactMap { section in
            (0...9).compactMap { item in
                IndexPath(item: item, section: section)
            }
        }.flatMap { $0 }
    }
}
