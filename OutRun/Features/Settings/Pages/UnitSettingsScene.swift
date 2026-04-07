import OutRunCore
import SwiftUI

struct UnitSettingsScene: View {
    
    @Environment(UserPreferences.self) private var userPreferences
    
    var body: some View {
        @Bindable var userPreferences = userPreferences
        Form {
            Picker(selection: $userPreferences.distanceUnit) {
                Text("System").tag(UnitLength?.none)
                ForEach(UserPreferences.supportedDistanceUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("Distance Unit")
            }
            Picker(selection: $userPreferences.altitudeUnit) {
                Text("System").tag(UnitLength?.none)
                ForEach(UserPreferences.supportedAltitudeUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("Altitude Unit")
            }
            Picker(selection: $userPreferences.speedUnit) {
                Text("System").tag(UnitSpeed?.none)
                ForEach(UserPreferences.supportedSpeedUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("Speed Unit")
            }
            Picker(selection: $userPreferences.energyUnit) {
                Text("System").tag(UnitEnergy?.none)
                ForEach(UserPreferences.supportedEnergyUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("Energy Unit")
            }
            Picker(selection: $userPreferences.weightUnit) {
                Text("System").tag(UnitMass?.none)
                ForEach(UserPreferences.supportedWeightUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("Weight Unit")
            }
        }
        .navigationTitle("Unit Settings")
    }
    
    private func formattedUnit(_ unit: Unit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        return formatter.string(from: unit)
    }
}
