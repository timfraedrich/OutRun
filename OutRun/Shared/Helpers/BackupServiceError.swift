import Foundation

// TODO: Localize
enum BackupServiceError: Error {
    /// The file provided by the user could not be read as a backup.
    case backupNotReadable
    /// There is no data to create a backup with.
    case noDataToBackUp
}
