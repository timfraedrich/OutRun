//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation

enum HealthSyncServiceError: LocalizedError {
    
    /// The queried object could not be found.
    case objectNotFound
    /// The activity type is not supported for syncing.
    case unsupportedActivityType
    /// The type is not supported for the operation.
    case invalidHealthKitType
    /// This error will be thrown when requesting authorization for Apple Health cannot trigger a prompt in the app. In this scenario the
    /// user should be instructed on how to manually adjust the permissions in Settings or the Health app.
    case permissionPromptUnavailable
    case authorizationMissing
    case authorizationDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .objectNotFound: .init(localized: "health_sync_service_error_object_not_found", bundle: .module)
        case .unsupportedActivityType: .init(localized: "health_sync_service_error_unsupported_activity_type", bundle: .module)
        case .invalidHealthKitType: .init(localized: "health_sync_service_error_invalid_health_kit_type", bundle: .module)
        case .permissionPromptUnavailable: .init(localized: "health_sync_service_error_permission_prompt_unavailable", bundle: .module)
        case .authorizationMissing: .init(localized: "health_sync_service_error_authorization_missing", bundle: .module)
        case .authorizationDenied: .init(localized: "health_sync_service_error_authorization_denied", bundle: .module)
        case .unknown: .init(localized: "health_sync_service_error_unknown", bundle: .module)
        }
    }
}
