import Foundation

enum BackupServiceError: LocalizedError {
    
    /// The file provided by the user could not be read as a backup.
    case backupNotReadable
    /// There is no data to create a backup with.
    case noDataToBackUp
    /// There was an error while encoding the workout data to create a backup.
    case couldNotEncodeData
    /// Could not restore workout data from the provided file, because it is not supported.
    case unsupportedFile
    
    var errorDescription: String? {
        switch self {
        case .backupNotReadable: .init(localized: "backup_service_error_backup_not_readable")
        case .noDataToBackUp: .init(localized: "backup_service_error_no_data_to_back_up")
        case .couldNotEncodeData: .init(localized: "backup_service_error_could_not_encode_data")
        case .unsupportedFile: .init(localized: "backup_service_error_unsupported_file")
        }
    }
}
