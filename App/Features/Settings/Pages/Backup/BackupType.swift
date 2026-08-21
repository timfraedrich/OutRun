import Foundation
import SwiftUI

enum BackupType: String, CaseIterable, Sendable, Identifiable {
    
    case model = "backup"
    case gpx = "gpx"
    case legacy = "legacy"
    
    var id: Int {
        hashValue
    }
    
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
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .model: "backup_type_title_model"
        case .gpx: "backup_type_title_gpx"
        case .legacy: "backup_type_title_legacy"
        }
    }
    
    static let exportableCases: [BackupType] = [.model, .gpx]
}
