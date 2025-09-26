public extension RandomAccessCollection {
    
    subscript(safeIndex index: Index?) -> Element? {
        guard let index, indices.contains(index) else { return nil }
        return self[index]
    }
}
