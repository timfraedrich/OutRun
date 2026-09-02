import OutRunCore
import SwiftData
import SwiftUI
import TFRouting
import WebKit

struct SettingsScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
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
        List {
            profileSection
            subpageSection
            legalSection
            infoSection
        }
        .safeAreaPadding(.top, .regular)
        .navigationTitle("settings")
        .closeToolbarItem()
    }
    
    @ViewBuilder private var profileSection: some View {
        Section {
            RouteLink(route: SettingsPageRoute.profile) {
                HStack(spacing: .regular) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(core.user?.name ?? .init(localized: "user_name_fallback")).font(.title2.bold())
                        Text("user_profile").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder private var subpageSection: some View {
        Section {
            RouteLink(route: SettingsPageRoute.units) {
                SettingsRowLabel {
                    Text("unit_settings")
                } icon: {
                    Image(systemName: "ruler.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            RouteLink(route: SettingsPageRoute.recording) {
                SettingsRowLabel {
                    Text("recording_settings")
                } icon: {
                    Image(systemName: "record.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.extraSmall)
                }
            }
            RouteLink(route: SettingsPageRoute.appleHealth) {
                SettingsRowLabel {
                    Text("apple_health")
                } icon: {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(6)
                        .offset(x: 3, y: -3)
                }
            }
            RouteLink(route: SettingsPageRoute.backup) {
                SettingsRowLabel {
                    Text("backup")
                } icon: {
                    Image(systemName: "document.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.extraSmall)
                }
            }
            RouteLink(route: SettingsPageRoute.cache) {
                SettingsRowLabel {
                    Text("cache")
                } icon: {
                    Image(systemName: "internaldrive.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.extraSmall)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder private var legalSection: some View {
        Section {
            SettingsOpenURLButton("https://tfr.software/terms") {
                Text("legal_terms_of_service")
            }
            SettingsOpenURLButton("https://tfr.software/privacy") {
                Text("legal_privacy_policy")
            }
            SettingsOpenURLButton("https://tfr.software/imprint") {
                Text("legal_imprint")
            }
            SettingsOpenURLButton(UIApplication.openSettingsURLString) {
                Text("legal_acknowledgements")
            }
            SettingsOpenURLButton("mailto:orca@tfr.software") {
                LabeledContent("settings_support", value: "orca@tfr.software")
            }
        }
    }
    
    @ViewBuilder private var infoSection: some View {
        Section {
            LabeledContent("settings_info_version", value: version)
            LabeledContent("settings_info_database_size", value: databaseSize.formatted(.byteCount(style: .file)))
            LabeledContent("settings_info_number_of_workouts", value: workouts.count.description)
            Button("reset_app_action", role: .destructive, action: askForResetConfirmation)
                .errorPopover($resetError)
                .confirmationDialog("reset_app_action", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("reset", role: .destructive, action: reset)
                } message: {
                    Text("reset_app_confirmation_message")
                }
                .foregroundStyle(.tint)
                .tint(.red)
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
