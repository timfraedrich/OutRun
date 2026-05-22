import CoreLocation
import OutRunCore
import SwiftUI

struct RecordingSettingsScene: View {
    
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(\.locale) private var locale
    
    private let availableGPSAccuracies: [CLLocationAccuracy] = [10, 20, 30, 40, 50]
    private var smallDistanceUnit: UnitLength { userPreferences.altitudeUnit ?? UserPreferences.fallbackAltitudeUnit(for: locale)}
    
    var body: some View {
        @Bindable var userPreferences = userPreferences
        Form {
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

            Toggle("recording_settings_rolling_speed", isOn: $userPreferences.calculateRollingSpeed)

        }
        .navigationTitle("recording_settings")
    }
}
