import OutRunCore
import SwiftUI

/// Everything needed to present a single system permission and its current status to the user.
struct PermissionItem: Identifiable {

    let id: String
    let title: String
    let systemImage: String
    let isRequired: Bool
    let reason: LocalizedStringKey
    let status: PermissionStatus
    /// Instructions on how to resolve the ``status``, presented while it ``PermissionStatus/requiresManualResolution``.
    let resolution: LocalizedStringKey
    /// Indicates whether the ``resolution`` can be carried out in the iOS Settings app.
    let resolvableInSystemSettings: Bool
    /// Presents the system authorization prompt, only available while the ``status`` is ``PermissionStatus/isRequestable``.
    let request: (@MainActor () async throws -> Void)?

    @MainActor
    static func recordingItems(for recorder: WorkoutRecorder) -> [PermissionItem] {
        WorkoutRecorderPermission.allCases.filter(recorder.neededPermissions.contains).map { permission in
            let status = recorder.permissionStatuses[permission, default: .undetermined]
            let request: (@MainActor () async throws -> Void)? = if status.isRequestable {
                { try await recorder.requestAuthorization(for: permission) }
            } else {
                nil
            }
            return PermissionItem(
                id: permission.debugDescription,
                title: permission.description,
                systemImage: permission.systemImage,
                isRequired: permission.isRequired,
                reason: permission.reason,
                status: status,
                resolution: permission.resolution(for: status),
                resolvableInSystemSettings: true,
                request: request
            )
        }
    }

    @MainActor
    static func appleHealth(for healthSyncService: HealthSyncService) -> PermissionItem {
        let status = healthSyncService.authorizationStatus
        let request: (@MainActor () async throws -> Void)? = if status.isRequestable {
            { try await healthSyncService.requestAuthorization() }
        } else {
            nil
        }
        let resolution: LocalizedStringKey = if status == .limited {
            "permission_apple_health_limited_resolution"
        } else {
            "permission_apple_health_denied_resolution"
        }
        return PermissionItem(
            id: HealthSyncService.identifier,
            title: .init(localized: "apple_health"),
            systemImage: "heart.fill",
            isRequired: false,
            reason: "permission_apple_health_reason",
            status: status,
            resolution: resolution,
            resolvableInSystemSettings: false,
            request: request
        )
    }
}
