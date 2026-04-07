import OutRunCore
import SwiftUI

struct RecordingSettingsScene: View {
    
    @Environment(UserPreferences.self) private var userPreferences
    
    var body: some View {
        @Bindable var userPreferences = userPreferences
        Form {
            Picker(selection: $userPreferences.defaultWorkoutType) {
                Text("Latest").tag(WorkoutType?.none)
                ForEach(WorkoutType.allCases, id: \.rawValue) { type in
                    Text(type.description).tag(type)
                }
            } label: {
                Text("Default Workout Type")
            }

            Picker(selection: $userPreferences.requiredGPSAccuracy) {
                Text("10 m").tag(10.0)
                Text("20 m (Default)").tag(UserPreferences.defaultGPSAccuracy)
                Text("30 m").tag(30.0)
                Text("40 m").tag(40.0)
                Text("50 m").tag(50.0)
            } label: {
                Text("GPS Accuracy")
            }

            Toggle("Rolling Speed", isOn: $userPreferences.calculateRollingSpeed)

        }
        .navigationTitle("Recording Preferences")
    }
}
