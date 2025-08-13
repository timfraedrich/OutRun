import OSLog

extension Logger {
    
    init(category: String) {
        self.init(subsystem: OutRunCore.moduleIdentifier, category: category)
    }
}
