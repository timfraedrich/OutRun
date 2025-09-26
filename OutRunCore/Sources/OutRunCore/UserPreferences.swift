import Foundation

/// An observable class that handels the bare preference dictionary of a ``UserProtocol`` object.
///
/// Use the available `value` and `setValue` methods to add a custom preference. To keep consistent with baked in preferences it
/// is recommended to save the key as a static property of ``UserPreferenceKeys`` as described in it's documentation. Currently supported
/// types are any conforming to the ``Codable`` protocol and `Dimension`. Objects of the latter need to be constraint to a set of supported
/// values.
///
/// Below you is an example on how to add a custom ``String`` preference.
///
/// ```swift
/// extension UserPreferences {
///     var myCustomPreference: String? {
///         get { value(for: UserPreferenceKeys.myCustomKey) }
///         set { setValue(newValue, for: UserPreferenceKeys.myCustomKey) }
///     }
/// }
/// ```
@Observable
public class UserPreferences {
    
    /// The bare preference dictionary as saved in a ``UserProtocol`` object under ``UserProtocol/preferences``. This dictionary is
    /// typically not interacted with directly. To get or set custom preference values use the available `value` and `setValue` methods.
    public var preferences: UserProtocol.RawPreferences
    
    /// Initializes with the bare preference dictionary of a ``UserProtocol`` object.
    public init(preferences: UserProtocol.RawPreferences) {
        self.preferences = preferences
    }
    
    /// Sets the provided preferences if they differ from the existing values.
    public func update(basedOn newPreferences: UserProtocol.RawPreferences) {
        guard preferences != newPreferences else { return }
        preferences = newPreferences
    }
    
    // MARK: Getter
    
    public func value<U: Dimension>(for key: String, supportedUnits: [U]) -> U? {
        guard let symbolData = preferences[key] else { return nil }
        let symbol = String(data: symbolData, encoding: .utf8)
        return supportedUnits.first { $0.symbol == symbol }
    }
    
    public func value<T: Codable>(for key: String) -> T? {
        guard let preferenceData = preferences[key] else { return nil }
        return try? JSONDecoder().decode(T.self, from: preferenceData)
    }
    
    // MARK: Setter
    
    public func setValue<U: Dimension>(_ value: U?, for key: String, supportedUnits: [U]) {
        if let value, supportedUnits.contains(value) {
            preferences[key] = value.symbol.data(using: .utf8)
        } else {
            preferences[key] = nil
        }
    }
    
    public func setValue<T: Codable>(_ value: T?, for key: String) {
        preferences[key] = if let value {
            try? JSONEncoder().encode(value)
        } else {
            nil
        }
    }
}
