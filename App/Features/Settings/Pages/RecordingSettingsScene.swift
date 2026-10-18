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

import CoreLocation
import OutRunCore
import SwiftUI

struct RecordingSettingsScene: View {

    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase

    private let availableGPSAccuracies: [CLLocationAccuracy] = [10, 20, 30, 40, 50]
    private var smallDistanceUnit: UnitLength { userPreferences.altitudeUnit ?? UserPreferences.fallbackAltitudeUnit(for: locale)}

    var body: some View {
        @Bindable var userPreferences = userPreferences
        Form {
            Section {
                ForEach(PermissionItem.recordingItems(for: recorder)) { item in
                    PermissionRow(item: item)
                }
            } header: {
                Text("permissions")
            } footer: {
                Text("recording_permissions_footer")
            }

            Picker(selection: $userPreferences.defaultWorkoutType) {
                Text("recording_preferences_default_workout_type_latest").tag(WorkoutType?.none)
                ForEach(WorkoutType.allCases, id: \.rawValue) { type in
                    Text(type.description).tag(type)
                }
            } label: {
                Text("recording_settings_default_workout_type")
            }

            Picker(selection: $userPreferences.requiredGPSAccuracy) {
                ForEach(availableGPSAccuracies, id: \.self) { accuracy in
                    let measurement = Measurement(value: accuracy, unit: UnitLength.meters)
                    let formattedMeasurement = measurement.formatted(.measurement(
                        width: .abbreviated,
                        usage: .general,
                        numberFormatStyle: .number.rounded()
                    ).locale(locale))
                    if accuracy == UserPreferences.defaultGPSAccuracy {
                        Text(verbatim: formattedMeasurement + " (" + .init(localized: "default") + ")")
                    } else {
                        Text(verbatim: formattedMeasurement)
                    }
                }
            } label: {
                Text("recording_settings_gps_accuracy")
            }

            descriptiveSetting(description: "recording_settings_rolling_speed_description") {
                Toggle("recording_settings_rolling_speed", isOn: $userPreferences.calculateRollingSpeed)
            }

            descriptiveSetting(description: "recording_settings_pause_automatically_description") {
                Toggle("recording_settings_pause_automatically", isOn: $userPreferences.pauseAutomatically)
            }

        }
        .safeAreaPadding(.top, .regular)
        .navigationTitle("recording_settings")
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await recorder.refreshPermissionStatuses()
        }
    }

    @ViewBuilder
    private var permissionSection: some View {
        Section {
            ForEach(PermissionItem.recordingItems(for: recorder)) { item in
                PermissionRow(item: item)
            }
        } header: {
            Text("permissions")
        } footer: {
            Text("recording_permissions_footer")
        }
    }

    @ViewBuilder
    private func descriptiveSetting<C: View>(description: LocalizedStringKey, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: .regular) {
            content()
            Text(description).font(.footnote).opacity(0.6)
        }
    }
}
