import CoreLocation
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
    public var preferences: RawPreferences
    
    /// Initializes with the bare preference dictionary of a ``UserProtocol`` object.
    public init(preferences: RawPreferences) {
        self.preferences = preferences
    }
    
    /// Sets the provided preferences if they differ from the existing values.
    public func update(basedOn newPreferences: RawPreferences) {
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
    
    /// - note: returns `false` in the event of a decoding failure or the value missing from the bare preferences dictionary.
    public func value(for key: String) -> Bool {
        guard let preferenceData = preferences[key] else { return false }
        return (try? JSONDecoder().decode(Bool.self, from: preferenceData)) ?? false
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
    
    // MARK: - Unit Preferences
    
    /// The user preferred unit for distances. A `nil` value indicates the user has not provided a preference. In such a case a system
    /// default should be used.
    /// - warning: Setting an unsupported value leads to the deletion of the previously set value. Supported values can be accessed through
    /// the static ``supportedDistanceUnits`` property.
    public var distanceUnit: UnitLength? {
        get { value(for: UserPreferenceKeys.distanceUnit, supportedUnits: Self.supportedDistanceUnits) }
        set { setValue(newValue, for: UserPreferenceKeys.distanceUnit, supportedUnits: Self.supportedDistanceUnits) }
    }
    
    /// Provides a safe value to use for distance related measurements based on the user preference or provided locale as a fallback.
    public func safeDistanceUnit(for locale: Locale = .current) -> UnitLength {
        distanceUnit ?? Self.fallbackDistanceUnit(for: locale)
    }
    
    /// The user preferred unit for altitudes. A `nil` value indicates the user has not provided a preference. In such a case a system
    /// default should be used.
    /// - warning: Setting an unsupported value leads to the deletion of the previously set value. Supported values can be accessed through
    /// the static ``supportedAltitudeUnits`` property.
    public var altitudeUnit: UnitLength? {
        get { value(for: UserPreferenceKeys.altitudeUnit, supportedUnits: Self.supportedAltitudeUnits) }
        set { setValue(newValue, for: UserPreferenceKeys.altitudeUnit, supportedUnits: Self.supportedAltitudeUnits) }
    }
    
    /// Provides a safe value to use for altitude related measurements based on the user preference or provided locale as a fallback.
    public func safeAltitudeUnit(for locale: Locale = .current) -> UnitLength {
        altitudeUnit ?? Self.fallbackAltitudeUnit(for: locale)
    }
    
    /// The user preferred unit for speeds. A `nil` value indicates the user has not provided a preference. In such a case a system
    /// default should be used.
    /// - warning: Setting an unsupported value leads to the deletion of the previously set value. Supported values can be accessed through
    /// the static ``supportedSpeedUnits`` property.
    public var speedUnit: UnitSpeed? {
        get { value(for: UserPreferenceKeys.speedUnit, supportedUnits: Self.supportedSpeedUnits) }
        set { setValue(newValue, for: UserPreferenceKeys.speedUnit, supportedUnits: Self.supportedSpeedUnits) }
    }
    
    /// Provides a safe value to use for speed related measurements based on the user preference or provided locale as a fallback.
    public func safeSpeedUnit(for locale: Locale = .current) -> UnitSpeed {
        speedUnit ?? Self.fallbackSpeedUnit(for: locale)
    }
    
    /// The user preferred unit for energy. A `nil` value indicates the user has not provided a preference. In such a case a system
    /// default should be used.
    /// - warning: Setting an unsupported value leads to the deletion of the previously set value. Supported values can be accessed through
    /// the static ``supportedEnergyUnits`` property.
    public var energyUnit: UnitEnergy? {
        get { value(for: UserPreferenceKeys.energyUnit, supportedUnits: Self.supportedEnergyUnits) }
        set { setValue(newValue, for: UserPreferenceKeys.energyUnit, supportedUnits: Self.supportedEnergyUnits) }
    }
    
    /// Provides a safe value to use for energy related measurements based on the user preference or provided locale as a fallback.
    public func safeEnergyUnit(for locale: Locale = .current) -> UnitEnergy {
        energyUnit ?? Self.fallbackEnergyUnit(for: locale)
    }
    
    /// The user preferred unit for body weight. A `nil` value indicates the user has not provided a preference. In such a case a system
    /// default should be used.
    /// - warning: Setting an unsupported value leads to the deletion of the previously set value. Supported values can be accessed through
    /// the static ``supportedWeightUnits`` property.
    public var weightUnit: UnitMass? {
        get { value(for: UserPreferenceKeys.weightUnit, supportedUnits: Self.supportedWeightUnits) }
        set { setValue(newValue, for: UserPreferenceKeys.weightUnit, supportedUnits: Self.supportedWeightUnits) }
    }
    
    /// Provides a safe value to use for weight related measurements based on the user preference or provided locale as a fallback.
    public func safeWeightUnit(for locale: Locale = .current) -> UnitMass {
        weightUnit ?? Self.fallbackWeightUnit(for: locale)
    }
    
    /// The supported values for ``UserPreferences/distanceUnit``.
    public static let supportedDistanceUnits: [UnitLength] = [.kilometers, .miles]
    /// The supported values for ``UserPreferences/altitudeUnit``.
    public static let supportedAltitudeUnits: [UnitLength] = [.meters, .feet]
    /// The supported values for ``UserPreferences/speedUnit``.
    public static let supportedSpeedUnits: [UnitSpeed] = [.kilometersPerHour, .milesPerHour]
    /// The supported values for ``UserPreferences/energyUnit``.
    public static let supportedEnergyUnits: [UnitEnergy] = [.kilocalories, .kilojoules]
    /// The supported values for ``UserPreferences/weightUnit``.
    public static let supportedWeightUnits: [UnitMass] = [.kilograms, .pounds, .stones]
    
    /// The locale based fallback value for ``UserPreferences/distanceUnit``.
    public static func fallbackDistanceUnit(for locale: Locale = .current) -> UnitLength {
        .init(forLocale: locale, usage: .road)
    }
    
    /// The locale based fallback value for ``UserPreferences/altitudeUnit``.
    public static func fallbackAltitudeUnit(for locale: Locale = .current) -> UnitLength {
        .init(forLocale: locale, usage: .general)
    }
    
    /// The locale based fallback value for ``UserPreferences/speedUnit``.
    public static func fallbackSpeedUnit(for locale: Locale = .current) -> UnitSpeed {
        .init(forLocale: locale, usage: .general)
    }
    
    /// The locale based fallback value for ``UserPreferences/energyUnit``.
    public static func fallbackEnergyUnit(for locale: Locale = .current) -> UnitEnergy {
        .init(forLocale: locale, usage: .workout)
    }
    
    /// The locale based fallback value for ``UserPreferences/weightUnit``.
    public static func fallbackWeightUnit(for locale: Locale = .current) -> UnitMass {
        .init(forLocale: locale, usage: .personWeight)
    }
    
    // MARK: - Recording Preferences
    
    /// The default workout type to use for recording a workout.
    /// - note: If not set the ``WorkoutRecorder`` will default to type of the most recent workout on initialization.
    public var defaultWorkoutType: WorkoutType? {
        get { value(for: UserPreferenceKeys.defaultWorkoutType) }
        set { setValue(newValue, for: UserPreferenceKeys.defaultWorkoutType) }
    }
    
    /// The user required horizontal GPS accuracy in meters. The default valus is given by ``UserPreferences/defaultGPSAccuracy``.
    public var requiredGPSAccuracy: CLLocationAccuracy {
        get { value(for: UserPreferenceKeys.requiredGPSAccuracy) ?? Self.defaultGPSAccuracy }
        set { setValue(newValue == Self.defaultGPSAccuracy ? nil : newValue, for: UserPreferenceKeys.requiredGPSAccuracy) }
    }
    
    /// The default value for the ``UserPreferences/requiredGPSAccuracy`` property.
    public static let defaultGPSAccuracy: CLLocationAccuracy = 20
    
    /// Indicates whether the ``WorkoutRecorder`` should calculate it's ``WorkoutRecorder/speed`` measurement based on the last kilometer of
    /// route data or just on the last available location. The former of which will provide a more stable value while the latter will be
    /// most accurate for displaying the current value.
    public var calculateRollingSpeed: Bool {
        get { value(for: UserPreferenceKeys.calculateRollingSpeed) }
        set { setValue(newValue, for: UserPreferenceKeys.calculateRollingSpeed) }
    }
}
