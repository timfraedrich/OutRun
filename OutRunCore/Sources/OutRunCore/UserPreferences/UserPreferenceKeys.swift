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
