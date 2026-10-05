import OutRunCore
import SwiftData
import SwiftUI
import TFRouting
import WebKit

struct SettingsScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(RouterNode.self) private var node
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
            NavigationLinkButton {
                node.route(SettingsPageRoute.profile)
            } label: {
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

    @ViewBuilder
    private func subpageButton<Icon: View>(
        _ titleKey: LocalizedStringKey,
        route: any RouteProtocol,
        @ViewBuilder icon: @escaping () -> Icon
    ) -> some View {
        NavigationLinkButton {
            node.route(route)
        } label: {
            SettingsRowLabel {
                Text(titleKey)
            } icon: {
                icon()
            }
        }
    }

    @ViewBuilder
    private func subpageButton(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        padding: Spacing? = .extraSmall,
        route: SettingsPageRoute
    ) -> some View {
        subpageButton(titleKey, route: route) {
            Image(systemName: systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(padding?.rawValue ?? .zero)
        }
    }

    @ViewBuilder private var subpageSection: some View {
        Section {
            subpageButton("unit_settings", systemImage: "ruler.fill", padding: nil, route: .units)
            subpageButton("recording_settings", systemImage: "record.circle", route: .recording)
            subpageButton("apple_health", route: SettingsPageRoute.appleHealth) {
                Image(systemName: "heart.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
                    .offset(x: 3, y: -3)
            }
            subpageButton("backup", systemImage: "document.fill", route: SettingsPageRoute.backup)
            subpageButton("cache", systemImage: "internaldrive.fill", route: SettingsPageRoute.cache)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder private var legalSection: some View {
        Section {
            SettingsOpenURLButton(ExternalURL.termsOfService) {
                Text("legal_terms_of_service")
            }
            SettingsOpenURLButton(ExternalURL.privacyPolicy) {
                Text("legal_privacy_policy")
            }
            SettingsOpenURLButton(UIApplication.openSettingsURLString) {
                Text("legal_acknowledgements")
            }
            SettingsOpenURLButton(ExternalURL.support) {
                LabeledContent("settings_support", value: ExternalURL.supportAddress)
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
