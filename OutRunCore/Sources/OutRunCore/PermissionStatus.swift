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

/// The authorization status of a system permission needed by the app.
public enum PermissionStatus: Equatable, Sendable, CustomDebugStringConvertible {

    /// The user has not been asked for authorization yet, a system prompt can still be presented.
    case undetermined
    /// Authorization was granted in full.
    case granted
    /// Authorization was granted, but limited in a way that prevents the associated data from being used as intended.
    case limited
    /// Authorization was explicitly denied by the user or is restricted by the system.
    case denied
    /// The underlying capability is unavailable on this device or has failed irrecoverably.
    case unavailable

    /// Indicates whether the granted authorization suffices to use the associated functionality.
    public var isSufficient: Bool {
        self == .granted
    }

    /// Indicates whether a system prompt asking the user for authorization can still be presented.
    public var isRequestable: Bool {
        self == .undetermined
    }

    /// Indicates whether the user has to resolve this status manually outside of the app.
    public var requiresManualResolution: Bool {
        self == .denied || self == .limited
    }

    /// Reduces the given statuses into the least permissive one, ignoring unavailable capabilities.
    /// - returns: `.unavailable` if every given status is unavailable or no status was given.
    static func leastPermissive(of statuses: some Sequence<PermissionStatus>) -> PermissionStatus {
        statuses.filter { $0 != .unavailable }.min { $0.permissiveness < $1.permissiveness } ?? .unavailable
    }

    private var permissiveness: Int {
        switch self {
        case .denied: 0
        case .limited: 1
        case .undetermined: 2
        case .granted: 3
        case .unavailable: 4
        }
    }

    public var debugDescription: String {
        switch self {
        case .undetermined: "PermissionStatus.undetermined"
        case .granted: "PermissionStatus.granted"
        case .limited: "PermissionStatus.limited"
        case .denied: "PermissionStatus.denied"
        case .unavailable: "PermissionStatus.unavailable"
        }
    }
}
