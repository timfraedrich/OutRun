import Foundation

public extension Date {
    
    /// The Unix timestamp in milliseconds.
    var unixTimestamp: Int { Int(timeIntervalSince1970 * 1000) }
    
    /// Creates a ``Date`` instance from a Unix timestamp in milliseconds.
    init(unixTimestamp: Int) {
        self.init(timeIntervalSince1970: .init(unixTimestamp) / 1000)
    }
}
