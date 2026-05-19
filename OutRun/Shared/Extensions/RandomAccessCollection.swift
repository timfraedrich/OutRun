import Foundation

extension RandomAccessCollection {
    
    /// Finds the index of the element where the predicate is false and true for all elements up to it. This method assumes that the
    /// RandomAccessCollection is sorted and an element for which the predicate is false exists. The behavior is undefined if there is no
    /// such element.
    func binarySearch(predicate: (Element) -> Bool) -> Index {
        var low = startIndex, high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}
