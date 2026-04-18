import Foundation

enum LegacyBackupError: LocalizedError {
    
    /// The provided backup file does not have the correct format, it might be corrupted.
    case corruptedData
    /// The backup is missing a version.
    case missingVersion
    /// The backup version is not supported by this app.
    case invalidVersion
    
    var errorDescription: String? {
        switch self {
        case .corruptedData: .init(localized:"legacy_backup_error_corrupted_data")
        case .missingVersion: .init(localized:"legacy_backup_error_missing_version")
        case .invalidVersion: .init(localized:"legacy_backup_error_invalid_version")
        }
    }
}
