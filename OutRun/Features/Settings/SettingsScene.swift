import SwiftUI
import OutRunCore

struct SettingsScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(\.dismiss) private var dismiss
    @Bindable private var userPreferences: UserPreferences
    
    private var version: String {
        let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            marketingVersion + " (" + buildNumber + ")"
        } else {
            marketingVersion
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        if let user = core.user {
                            UserProfileView(user: user)
                        }
                    } label: {
                        HStack(spacing: .regular) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.tint)
                                .symbolRenderingMode(.hierarchical)
                            VStack(alignment: .leading, spacing: .zero) {
                                Text(core.user?.name ?? "User").font(.title2.bold())
                                Text("User Profile").font(.subheadline).opacity(0.6)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Section("Units") {
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
                
                Section("Recording") {
                    
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
                
                if let healthSyncService = core.syncService(HealthSyncService.self) {
                    Section("Apple Health") {
                        Button("Grant Permissions") {
                            Task {
                                do {
                                    try await healthSyncService.requestAuthorization()
                                    healthSyncService.outwardSyncMode = .enabled
                                } catch {
                                    print("HealthSyncService authorization failed: \(error)")
                                }
                            }
                        }
                    }
                }
                
                Section("Data") {
                    Button("Clear Map Cache") {
                        try? StaticWorkoutMapService.clearCache()
                    }
                    Button("Reset", role: .destructive) {
                        Task {
                            do {
                                try await core.reset()
                            } catch {
                                print("Reset failed: \(error)")
                            }
                        }
                    }
                }
                
                Section("Info") {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
    
    func formattedUnit(_ unit: Unit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        return formatter.string(from: unit)
    }
    
    init(userPreferences: UserPreferences) {
        self.userPreferences = userPreferences
    }
}

struct UserProfileView: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var name: String
    @State private var weight: Measurement<UnitMass>?
    @State private var provideAge: Bool = false
    @State private var birthdate: Date?
    @State private var sex: Sex?
    @State private var error: Error?
    @State private var showPopover: Bool = false
    
    var body: some View {
        Form {
            LabeledContent("Name") {
                TextField("Your name", text: $name).fixedSize()
            }
            LabeledContent("Birthday") {
                OptionalDatePicker(
                    selection: $birthdate,
                    in: ...Date.now,
                    displayedComponents: .date,
                    labelFormatStyle: .init(date: .abbreviated)
                )
                .buttonStyle(.plain)
                .symbolRenderingMode(.hierarchical)
            }
            LabeledContent("Weight") {
                MeasurementTextField("Your weight", measurement: $weight, unit: userPreferences.safeWeightUnit(for: locale))
            }
            Picker(selection: $sex) {
                Text("Not specified").tag(Sex?.none)
                ForEach(Sex.allCases, id: \.hashValue) { sex in
                    Text(sex.description.capitalized).tag(sex)
                }
            } label: {
                Text("Sex")
            }
        }
        .animation(.default, value: provideAge)
        .multilineTextAlignment(.trailing)
        .navigationTitle("User Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).errorPopover($error)
            }
        }
    }
    
    init(user: any UserProtocol) {
        self._name = .init(initialValue: user.name)
        self._birthdate = .init(initialValue: try? user.birthday?.date())
        let userWeight: Measurement<UnitMass>? = if let weight = user.weight {
            .init(value: weight, unit: .kilograms)
        } else {
            nil
        }
        self._weight = .init(initialValue: userWeight)
        self._sex = .init(initialValue: user.sex)
    }
    
    private func save() {
        Task {
            do {
                let birthday = birthdate.map(Day.init)
                let weight = weight?.converted(to: .kilograms).value
                try await core.updateUserProperties(name: name, birthday: birthday, weight: weight, sex: sex)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    
    @Previewable @State var date: Date? = .now
    
    OptionalDatePicker(selection: $date, labelFormatStyle: .init(date: .abbreviated))
}

#Preview {
    NavigationStack {
        List {
            Section("Settings") {
                NavigationLink {
                    EmptyView()
                } label: {
                    Label {
                        Text("Units")
                    } icon: {
                        ZStack {
                            Rectangle().opacity(0.2)
                            Image(systemName: "ruler.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(4)
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                NavigationLink {
                    EmptyView()
                } label: {
                    Label {
                        Text("Apple Health")
                    } icon: {
                        ZStack {
                            Rectangle().opacity(0.2)
                            Image(systemName: "heart.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .offset(x: 3, y: -3)
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                NavigationLink {
                    EmptyView()
                } label: {
                    Label {
                        Text("Recording")
                    } icon: {
                        ZStack {
                            Rectangle().opacity(0.2)
                            Image(systemName: "record.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            //.foregroundStyle(.white)
                                .padding(4)
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
            }
            Section("Info") {
                LabeledContent("Version", value: "2.0 (42)")
            }
        }
    }
}
