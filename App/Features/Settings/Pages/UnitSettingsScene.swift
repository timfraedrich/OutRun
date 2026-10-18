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
                Text("unit_settings_distance_unit")
            }
            Picker(selection: $userPreferences.altitudeUnit) {
                Text("system").tag(UnitLength?.none)
                ForEach(UserPreferences.supportedAltitudeUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("unit_settings_altitude_unit")
            }
            Picker(selection: $userPreferences.speedUnit) {
                Text("system").tag(UnitSpeed?.none)
                ForEach(UserPreferences.supportedSpeedUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("unit_settings_speed_unit")
            }
            Picker(selection: $userPreferences.energyUnit) {
                Text("system").tag(UnitEnergy?.none)
                ForEach(UserPreferences.supportedEnergyUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("unit_settings_energy_unit")
            }
            Picker(selection: $userPreferences.weightUnit) {
                Text("system").tag(UnitMass?.none)
                ForEach(UserPreferences.supportedWeightUnits, id: \.symbol) { unit in
                    Text(formattedUnit(unit)).tag(unit)
                }
            } label: {
                Text("unit_settings_weight_unit")
            }
        }
        .safeAreaPadding(.top, .regular)
        .navigationTitle("unit_settings")
    }
    
    private func formattedUnit(_ unit: Unit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        return formatter.string(from: unit)
    }
}
