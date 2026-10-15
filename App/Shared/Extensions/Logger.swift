import OSLog

extension Logger {

    init(category: String) {
        self.init(subsystem: OutRun.identifier, category: category)
    }
}
