import Foundation

enum BackupType: String, CaseIterable, Sendable {
    
    case model = "backup"
    case gpx = "gpx"
    case legacy = "legacy"
    
    var fileExtension: String {
        switch self {
        case .model: "json"
        case .gpx: "gpx"
        case .legacy: "orbup"
        }
    }
    
    /// Indicates whether the data is exported to a zip archive.
    var useZipCompression: Bool {
        switch self {
        case .model: true
        case .gpx, .legacy: false
        }
    }
}
