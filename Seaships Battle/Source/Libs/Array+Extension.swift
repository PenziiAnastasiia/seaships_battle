import Foundation

extension Array where Element: Equatable {
    
    @discardableResult
    mutating func remove(object: Element) -> Element? {
        self.firstIndex(of: object)
            .map { index in
                self.remove(at: index)
            }
    }
    
    func object(at index: Int) -> Element? {
        return index < self.count ? self[index] : nil
    }
    
    func filter(startIndex: Int, endIndex: Int) -> [Element] where Element == IndexPath {
        self.reduce([IndexPath]()) { result, indexPath in
            var indexPaths = result
            if !(indexPath.item < startIndex ||
                 indexPath.item > endIndex ||
                 indexPath.section < startIndex ||
                 indexPath.section > endIndex)
            {
                indexPaths.append(indexPath)
            }
            
            return indexPaths
        }
    }
}
