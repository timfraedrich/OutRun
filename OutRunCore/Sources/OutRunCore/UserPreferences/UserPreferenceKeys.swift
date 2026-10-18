//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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

/// A collection of preference keys saved to the user object.
///
/// To add a custom key, an application may extend this enum as follows.
///
/// ```swift
/// extension UserPreferenceKeys {
///     static let myCustomKey = "customKey"
/// }
/// ```
/// - warning: Please thoroughly check for collisions. Incorrect usage of existing keys might cause unexpected behaviour when used.
public enum UserPreferenceKeys {
    
    static func preferenceKey(for name: String) -> String {
        OutRunCore.moduleIdentifier + ".\(name)"
    }
    
    // MARK: Unit Preferences
    
    public static let distanceUnit = preferenceKey(for: "distanceUnit")
    public static let altitudeUnit = preferenceKey(for: "altitudeUnit")
    public static let speedUnit = preferenceKey(for: "speedUnit")
    public static let energyUnit = preferenceKey(for: "energyUnit")
    public static let weightUnit = preferenceKey(for: "weightUnit")
    
    // MARK: Recording Preferences
    
    public static let defaultWorkoutType = preferenceKey(for: "defaultWorkoutType")
    public static let requiredGPSAccuracy = preferenceKey(for: "requiredGPSAccuracy")
    public static let calculateRollingSpeed = preferenceKey(for: "calculateRollingSpeed")
    public static let pauseAutomatically = preferenceKey(for: "pauseAutomatically")
}
