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
}
