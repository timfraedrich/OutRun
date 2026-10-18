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

struct SetupScene: View {
    
    @Environment(\.locale) private var locale
    @Environment(OutRunCore.self) private var core
    @ScaledMetric(relativeTo: .largeTitle) private var logoHeight: CGFloat = 120
    @State private var page: Page = .welcome
    @State private var acceptedTermsOfService: Bool = false
    @State private var acceptedPrivacyPolicy: Bool = false
    @State private var legalAcceptanceDate: Date?
    @State private var draft: SetupProfileDraft = .init()
    @State private var unitSystem: UnitSystem = .system
    @State private var healthImportMode: SyncMode = .disabled
    @State private var saveToHealth: Bool = false
    @State private var loading: Bool = false
    @State private var error: Error?

    private let initDate = Date.now

    private var healthSyncService: HealthSyncService? { core.syncService(HealthSyncService.self) }
    
    var body: some View {
        content(for: page)
            .id(page)
            .transition(.push(from: .trailing))
            .animation(.default, value: page)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .customBottomSafeAreaBar(content: barContent)
            .disabled(loading)
    }
    
    // MARK: Pages
    
    @ViewBuilder
    private func content(for page: Page) -> some View {
        switch page {
        case .welcome:
            SetupPageView(title: "setup_welcome_title") {
                Image(.oLogo)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.accent.gradient)
                    .scaledToFit()
                    .frame(height: logoHeight)
            } content: {
                SetupPageDetailRow(
                    "setup_welcome_privacy_title",
                    message: "setup_welcome_privacy_message",
                    systemImage: "lock.shield.fill"
                )
                SetupPageDetailRow(
                    "setup_welcome_tracking_title",
                    message: "setup_welcome_tracking_message",
                    systemImage: "location.app.fill"
                )
                SetupPageDetailRow(
                    "setup_welcome_design_title",
                    message: "setup_welcome_design_message",
                    systemImage: "iphone.sizes"
                )
            }
        case .legal:
            SetupPageView(systemImage: "hand.raised.fill", title: "setup_legal_title", message: "setup_legal_message") {
                Section {
                    legalToggle("legal_terms_of_service", urlString: ExternalURL.termsOfService, isOn: $acceptedTermsOfService)
                    legalToggle("legal_privacy_policy", urlString: ExternalURL.privacyPolicy, isOn: $acceptedPrivacyPolicy)
                }
            }
        case .profile:
            SetupPageView(
                systemImage: "person.crop.circle.fill",
                title: "setup_profile_title",
                message: "setup_profile_message"
            ) {
                SetupProfileForm(
                    draft: $draft,
                    unitSystem: $unitSystem,
                    weightUnit: unitSystem.weightUnit(for: locale)
                )
            }
        case .appleHealth:
            SetupPageView(title: "setup_health_title", message: "setup_health_message") {
                SetupPageSymbol("heart.fill").tint(.pink)
            } content: {
                Section {
                    Toggle("setup_health_export_toggle", isOn: $saveToHealth)
                        .tint(.accentColor)
                } header: {
                    Text("setup_health_export_header")
                } footer: {
                    Text("setup_health_export_footer")
                }
                Section {
                    Picker(selection: $healthImportMode) {
                        Text("setup_health_import_none").tag(SyncMode.disabled)
                        Text("setup_health_import_new").tag(SyncMode.enabledFrom(date: initDate))
                        Text("setup_health_import_all").tag(SyncMode.enabled)
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("setup_health_import_header")
                } footer: {
                    Text("setup_health_import_footer")
                }
            }
        case .ready:
            SetupPageView(
                systemImage: "checkmark.circle.fill",
                title: "setup_ready_title_\(draft.trimmedName)",
                message: "setup_ready_message"
            )
        }
    }
    
    @ViewBuilder
    private func legalToggle(_ titleKey: LocalizedStringKey, urlString: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            if let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: .extraSmall) {
                        Text(titleKey)
                        Image(systemName: "arrow.up.right")
                    }
                    .fontWeight(.semibold)
                }
            } else {
                Text(titleKey)
            }
        }
        .tint(.accentColor)
    }
    
    // MARK: Bottom Bar
    
    @ViewBuilder
    private func barContent() -> some View {
        VStack(spacing: .regular) {
            if let error {
                Text(error.localizedDescription)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            pageAction()
        }
        .animation(.default, value: error?.localizedDescription)
    }
    
    @ViewBuilder
    private func pageAction() -> some View {
        switch page {
        case .welcome:
            ActionButton("setup_welcome_action", action: advance)
        case .legal:
            ActionButton("continue_action", action: acceptLegalDocuments)
                .disabled(!acceptedTermsOfService || !acceptedPrivacyPolicy)
        case .profile:
            ActionButton("continue_action", action: advance)
                .disabled(!draft.isComplete)
        case .appleHealth:
            VStack(spacing: .small) {
                ActionButton("skip_action", prominent: false, action: skipHealth)
                ActionButton(action: connectHealth) {
                    if healthImportMode != .disabled {
                        Text("setup_health_start_import_action")
                    } else {
                        Text("setup_health_grant_permission_action")
                    }
                }
                .disabled(healthImportMode == .disabled && !saveToHealth)
            }
        case .ready:
            ActionButton("setup_ready_action", action: completeSetup)
        }
    }
    
    // MARK: Actions
    
    private func advance() {
        guard let index = Page.allCases.firstIndex(of: page), let next = Page.allCases[safeIndex: index + 1] else { return }
        page = next
    }
    
    private func acceptLegalDocuments() {
        legalAcceptanceDate = .now
        advance()
    }

    private func saveProfile() {
        Task {
            loading = true
            do {
                let preferences = UserPreferences(preferences: [:])
                unitSystem.apply(to: preferences)
                if let legalAcceptanceDate {
                    preferences.recordLegalAcceptance(on: legalAcceptanceDate)
                }
                let user = RawUser(
                    name: draft.trimmedName,
                    birthday: draft.birthday,
                    weight: draft.weightInKilograms,
                    sex: draft.sex,
                    preferences: preferences.preferences,
                    creationDate: .now
                )
                try await core.setup(for: user)
            } catch {
                self.error = error
            }
            loading = false
        }
    }

    private func skipHealth() {
        healthImportMode = .disabled
        saveToHealth = false
        advance()
    }
    
    private func connectHealth() {
        Task {
            loading = true
            do {
                await healthSyncService?.refreshAuthorizationStatus()
                if let healthSyncService, healthSyncService.authorizationStatus.isRequestable {
                    try await healthSyncService.requestAuthorization()
                }
                advance()
            } catch {
                self.error = error
            }
            loading = false
        }
    }
    
    private func completeSetup() {
        Task {
            loading = true
            do {
                let preferences = UserPreferences(preferences: [:])
                unitSystem.apply(to: preferences)
                if let legalAcceptanceDate {
                    preferences.recordLegalAcceptance(on: legalAcceptanceDate)
                }
                let user = RawUser(
                    name: draft.trimmedName,
                    birthday: draft.birthday,
                    weight: draft.weightInKilograms,
                    sex: draft.sex,
                    preferences: preferences.preferences,
                    creationDate: .now
                )
                try await core.setup(for: user)
                applyHealthSyncModes()
            } catch {
                self.error = error
            }
            loading = false
        }
    }
    
    /// Enables the Health sync directions chosen during setup.
    /// - note: Must only be called once ``OutRunCore/setup(for:)`` has finished, since the sync service ignores changes until it is
    /// initialized.
    private func applyHealthSyncModes() {
        guard let healthSyncService else { return }
        if case .enabledFrom = healthImportMode {
            healthImportMode = .enabledFrom(date: .now)
        }
        healthSyncService.setInwardSyncMode(healthImportMode)
        if saveToHealth {
            healthSyncService.setOutwardSyncMode(.enabled)
        }
    }
    
    private enum Page: Hashable, CaseIterable {
        case welcome
        case legal
        case profile
        case appleHealth
        case ready
    }
}
