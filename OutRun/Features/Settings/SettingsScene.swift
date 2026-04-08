import OutRunCore
import SwiftData
import SwiftUI
import WebKit

struct SettingsScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(SettingsRouter.self) private var settingsRouter
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Query private var workouts: [Workout]
    @State private var confirmReset: Bool = false
    @State private var resetError: Error?
    
    private var version: String {
        let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            marketingVersion + " (" + buildNumber + ")"
        } else {
            marketingVersion
        }
    }
    
    private var databaseSize: Int {
        (try? core.modelContainer.configurations.first?.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? .zero
    }
    
    var body: some View {
        @Bindable var settingsRouter = settingsRouter
        @Bindable var userPreferences = userPreferences
        NavigationStack(path: $settingsRouter.path) {
            List {
                Section {
                    NavigationLink(value: SettingsDestination.profile) {
                        HStack(spacing: .regular) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.tint)
                                .symbolRenderingMode(.hierarchical)
                            VStack(alignment: .leading, spacing: .zero) {
                                Text(core.user?.name ?? "User").font(.title2.bold())
                                Text("User Profile").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Section {
                    NavigationLink(value: SettingsDestination.units) {
                        SettingsRowLabel {
                            Text("Unit Settings")
                        } icon: {
                            Image(systemName: "ruler.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    NavigationLink(value: SettingsDestination.recording) {
                        SettingsRowLabel {
                            Text("Recording Preferences")
                        } icon: {
                            Image(systemName: "record.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.extraSmall)
                        }
                    }
                    NavigationLink(value: SettingsDestination.appleHealth) {
                        SettingsRowLabel {
                            Text("Apple Health")
                        } icon: {
                            Image(systemName: "heart.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(6)
                                .offset(x: 3, y: -3)
                        }
                    }
                    NavigationLink(value: SettingsDestination.backup) {
                        SettingsRowLabel {
                            Text("Backup")
                        } icon: {
                            Image(systemName: "document.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.extraSmall)
                        }
                    }
                    NavigationLink(value: SettingsDestination.cache) {
                        SettingsRowLabel {
                            Text("Cache")
                        } icon: {
                            Image(systemName: "internaldrive.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.extraSmall)
                        }
                    }
                }
                
                Section {
                    SettingsOpenURLButton("https://tfr.software/terms") {
                        Text("Terms of Service")
                    }
                    SettingsOpenURLButton("https://tfr.software/privacy") {
                        Text("Privacy Policy")
                    }
                    SettingsOpenURLButton("https://tfr.software/imprint") {
                        Text("Imprint")
                    }
                    SettingsOpenURLButton("mailto:orca@tfr.software") {
                        LabeledContent("Support", value: "orca@tfr.software")
                    }
                }
                
                Section {
                    LabeledContent("Version", value: version)
                    LabeledContent("Database Size", value: databaseSize.formatted(.byteCount(style: .file)))
                    LabeledContent("Number of Workouts", value: workouts.count.description)
                    Button("Reset App", role: .destructive, action: askForResetConfirmation)
                        .errorPopover($resetError)
                        .confirmationDialog("Reset App", isPresented: $confirmReset, titleVisibility: .visible) {
                            Button("Reset", role: .destructive, action: reset)
                        } message: {
                            Text("Are you sure you want to reset the app. This will delete all data saved locally including your workouts and personal information. This action connot be undone.")
                        }
                        .foregroundStyle(.tint)
                        .tint(.red)
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
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .appleHealth:
                    HealthSettingsScene()
                case .backup:
                    BackupSettingsScene()
                case .cache:
                    CacheSettingsScene()
                case .profile:
                    ProfileScene()
                case .recording:
                    RecordingSettingsScene()
                case .units:
                    UnitSettingsScene()
                }
            }
        }
    }
    
    private func askForResetConfirmation() {
        confirmReset = true
    }
    
    private func reset() {
        Task {
            do {
                try await core.reset()
            } catch {
                resetError = error
            }
        }
    }
}
