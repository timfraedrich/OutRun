import Foundation

// TODO: Localize
enum HealthSyncServiceError: Error {
    case objectNotFound
    /// This error will be thrown when requesting authorization for Apple Health cannot trigger a prompt in the app. In this scenario the
    /// user should be instructed on how to manually adjust the permissions in Settings or the Health app.
    case permissionPromptUnavailable
    case authorizationMissing
    case authorizationDenied
    case unknown
}
