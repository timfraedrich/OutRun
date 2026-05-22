import Foundation

enum BackupServiceError: LocalizedError {
    
    /// The file provided by the user could not be read as a backup.
    case backupNotReadable
    /// There is no data to create a backup with.
    case noDataToBackUp
    
    var errorDescription: String? {
        switch self {
        case .backupNotReadable: .init(localized: "backup_service_error_backup_not_readable")
        case .noDataToBackUp: .init(localized: "backup_service_error_no_data_to_back_up")
        }
    }
}
