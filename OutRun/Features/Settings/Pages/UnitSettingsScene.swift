import OutRunCore
import SwiftUI

struct UnitSettingsScene: View {
    
    @Environment(UserPreferences.self) private var userPreferences
    
    var body: some View {
        @Bindable var userPreferences = userPreferences
        Form {
            Picker(selection: $userPreferences.distanceUnit) {
                Text("system").tag(UnitLength?.none)
                ForEach(UserPreferences.supportedDistanceUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("distance_unit")
            }
            Picker(selection: $userPreferences.altitudeUnit) {
                Text("system").tag(UnitLength?.none)
                ForEach(UserPreferences.supportedAltitudeUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("altitude_unit")
            }
            Picker(selection: $userPreferences.speedUnit) {
                Text("system").tag(UnitSpeed?.none)
                ForEach(UserPreferences.supportedSpeedUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("speed_unit")
            }
            Picker(selection: $userPreferences.energyUnit) {
                Text("system").tag(UnitEnergy?.none)
                ForEach(UserPreferences.supportedEnergyUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("energy_unit")
            }
            Picker(selection: $userPreferences.weightUnit) {
                Text("system").tag(UnitMass?.none)
                ForEach(UserPreferences.supportedWeightUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("weight_unit")
            }
        }
        .navigationTitle("unit_settings")
    }
    
    private func formattedUnit(_ unit: Unit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        return formatter.string(from: unit)
    }
}
