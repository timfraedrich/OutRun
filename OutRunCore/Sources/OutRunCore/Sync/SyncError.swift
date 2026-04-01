// TODO: Localize
public enum SyncError: Error {
    /// The workout has conflicting changes. Requires manual user intervention.
    case conflict
    /// The sync service is temporarily unavailable. Will retry on next sync attempt.
    case serviceUnavailable
    /// The sync service requires re-authentication or setup.
    case authenticationRequired
    /// A network error occurred while communicating with the service.
    case networkError
    /// An unknown error occurred during sync.
    case unknown
}
