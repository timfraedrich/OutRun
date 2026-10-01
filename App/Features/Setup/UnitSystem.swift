import Foundation
import OutRunCore

/// A coarse choice of measurement units offered during setup, in place of the individual unit preferences found in the settings.
enum UnitSystem: CaseIterable, CustomStringConvertible, Hashable {
    case system
    case metric
    case imperial
    
    var description: String {
        switch self {
        case .system: .init(localized: "system")
        case .metric: .init(localized: "unit_system_metric")
        case .imperial: .init(localized: "unit_system_imperial")
        }
    }
    
    func weightUnit(for locale: Locale) -> UnitMass {
        switch self {
        case .system: UserPreferences.fallbackWeightUnit(for: locale)
        case .metric: .kilograms
        case .imperial: .pounds
        }
    }
    
    /// Writes the individual unit preferences matching this system.
    /// - note: ``UnitSystem/system`` clears the preferences instead, so every unit keeps resolving through its locale based fallback.
    func apply(to preferences: UserPreferences) {
        switch self {
        case .system:
            preferences.distanceUnit = nil
            preferences.altitudeUnit = nil
            preferences.speedUnit = nil
            preferences.energyUnit = nil
            preferences.weightUnit = nil
        case .metric:
            preferences.distanceUnit = .kilometers
            preferences.altitudeUnit = .meters
            preferences.speedUnit = .kilometersPerHour
            preferences.energyUnit = .kilocalories
            preferences.weightUnit = .kilograms
        case .imperial:
            preferences.distanceUnit = .miles
            preferences.altitudeUnit = .feet
            preferences.speedUnit = .milesPerHour
            preferences.energyUnit = .kilocalories
            preferences.weightUnit = .pounds
        }
    }
}
