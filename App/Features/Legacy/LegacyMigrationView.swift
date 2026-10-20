//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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

struct LegacyMigrationView: View {

    @Environment(OutRunCore.self) private var core
    @Environment(\.locale) private var locale
    @Namespace private var namespace
    @State private var page: Page? = .update
    @State private var draft: SetupProfileDraft = .init()
    @State private var prefilledDraft: Bool = false
    @State private var savingProfile: Bool = false
    @State private var acceptedTermsOfService: Bool = false
    @State private var acceptedPrivacyPolicy: Bool = false
    @State private var legalAcceptanceDate: Date?
    @State private var presentedLegalDocument: LegalDocument?
    @State private var status: LegacyMigrationProgressView.Status = .running(progress: 0, estimatedEnd: nil)
    @State private var error: Error?
    @State private var showsHealthPage: Bool = false
    /// `nil` until the user decided whether to continue syncing with Apple Health.
    @State private var continueHealthSync: Bool?
    @State private var healthRequestError: Error?

    private let dismissAction: () -> Void

    private var pages: [Page] { Page.allCases.filter { $0 != .appleHealth || showsHealthPage } }
    private var healthSyncService: HealthSyncService? { core.syncService(HealthSyncService.self) }
    private var finishedMigration: Bool { status == .done }
    private var acceptedLegalDocuments: Bool { legalAcceptanceDate != nil }
    private var weightUnit: UnitMass {
        core.userPreferences?.safeWeightUnit(for: locale) ?? UserPreferences.fallbackWeightUnit(for: locale)
    }
    private var primaryActionTitleKey: LocalizedStringKey {
        switch page {
        case .profile: "save"
        case .appleHealth: "setup_health_grant_permission_action"
        case .done: "legacy_migration_view_success_action"
        default: "continue_action"
        }
    }

    init(dismissAction: @escaping () -> Void) {
        self.dismissAction = dismissAction
    }

    var body: some View {
        Group {
            if let error {
                errorContent(for: error)
            } else {
                pageContent
            }
        }
        .disabled(savingProfile)
        .task(id: legalAcceptanceDate, migrationAction)
        .task(determineHealthPageVisibility)
        .legalDocumentSheet($presentedLegalDocument)
        .onChange(of: core.user?.id, initial: true, prefillDraft)
    }

    // MARK: Pages

    @ViewBuilder private var pageContent: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(pages, id: \.self) { page in
                        content(for: page)
                            .scrollDisabled(false)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $page)
            .scrollDisabled(true)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
        }
        .customBottomSafeAreaBar(ignoredSafeAreaRegions: page == .profile ? .all : .container, content: barContent)
    }

    @ViewBuilder
    private func content(for page: Page) -> some View {
        switch page {
        case .update:
            ScrollView {
                SetupPageHeader(title: "legacy_migration_update_title", message: "legacy_migration_update_message") {
                    Image(.oLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundStyle(.accent.gradient)
                }
                .padding(.horizontal, .extraLarge)
            }
            .defaultScrollAnchor(.center)
        case .legal:
            SetupPageView(
                systemImage: "hand.raised.fill",
                title: "legacy_migration_legal_title",
                message: "legacy_migration_legal_message"
            ) {
                LegalAcceptanceSection(
                    acceptedTermsOfService: $acceptedTermsOfService,
                    acceptedPrivacyPolicy: $acceptedPrivacyPolicy,
                    presentedDocument: $presentedLegalDocument
                )
                .disabled(acceptedLegalDocuments)
            }
        case .profile:
            SetupPageView(
                systemImage: "person.crop.circle.fill",
                title: "legacy_migration_profile_title",
                message: "legacy_migration_profile_message"
            ) {
                SetupProfileForm(draft: $draft, weightUnit: weightUnit)
            }
        case .appleHealth:
            SetupPageView(title: "legacy_migration_health_title", message: "legacy_migration_health_message") {
                SetupPageSymbol("heart.fill").tint(.pink)
            }
        case .done:
            ScrollView {
                VStack(spacing: .regular) {
                    SetupPageHeader(
                        title: finishedMigration ? "legacy_migration_done_title" : "legacy_migration_progress_title",
                        message: finishedMigration ? "legacy_migration_done_message" : "legacy_migration_progress_message"
                    ) {
                        if #available(iOS 26.0, *) {
                            doneSymbol.symbolVariableValueMode(.draw)
                        } else {
                            doneSymbol
                        }
                    }
                    if !finishedMigration {
                        EstimatedTimeRemainingText(estimatedEnd: status.estimatedEnd)
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, .extraLarge)
            }
            .defaultScrollAnchor(.center)
        default:
            ScrollView {
                SetupPageHeader(
                    systemImage: page.systemImage,
                    title: page.titleKey,
                    message: page.messageKey
                )
                .padding(.horizontal, .extraLarge)
            }
            .defaultScrollAnchor(.center)
        }
    }

    @ViewBuilder private var doneSymbol: some View {
        let image: Image = if finishedMigration {
            Image(systemName: "checkmark.circle.fill")
        } else if #available(iOS 26.0, *) {
            Image(systemName: "circle", variableValue: Double(status.progress))
        } else {
            Image(systemName: "slowmo", variableValue: Double(status.progress))
        }
        SetupPageSymbol(image)
            .contentTransition(.symbolEffect(.replace))
            .animation(.default, value: finishedMigration)
    }

    @ViewBuilder
    private func barContent() -> some View {
        VStack(spacing: .regular) {
            PageIndicator(items: pages, selection: page)
                .foregroundStyle(.tint, .tertiary)
            VStack(spacing: .small) {
                if acceptedLegalDocuments && page != .done && page != .profile && page != .appleHealth {
                    LegacyMigrationProgressView(status: status)
                        .animation(.default, value: status)
                        .transition(.scale.combined(with: .opacity))
                }
                ActionButton(primaryActionTitleKey, action: primaryAction)
                    .disabled(
                        page == .legal && !(acceptedTermsOfService && acceptedPrivacyPolicy)
                            || page == .profile && !draft.isComplete
                            || page == .done && !finishedMigration
                    )
                    .errorPopover($healthRequestError)
                if page == .profile {
                    ActionButton("skip_action", prominent: false, action: advance)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if page == .appleHealth {
                    ActionButton("legacy_migration_health_disable_action", prominent: false, action: declineHealthSync)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.default, value: finishedMigration)
        .animation(.default, value: page)
    }
    
    @ViewBuilder
    private func errorContent(for error: Error) -> some View {
        VStack(spacing: .large) {
            Group {
                Image(systemName: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .font(.system(size: 64))
                Text("legacy_migration_view_failed_title")
                    .font(.title.bold())
            }
            .foregroundStyle(.tint)
            Text(error.localizedDescription)
                .font(.title3)
            Text("legacy_migration_view_failed_footnote")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.extraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .customBottomSafeAreaBar {
            ActionButton("legacy_migration_view_failed_action", action: openSupportMail)
        }
        .tint(.red)
    }
    
    // MARK: Actions

    private func primaryAction() {
        switch page {
        case .legal:
            if !acceptedLegalDocuments {
                legalAcceptanceDate = .now
            }
            advance()
        case .profile:
            saveProfileAndAdvance()
        case .appleHealth:
            grantHealthPermissionAndAdvance()
        case .done:
            dismissAction()
        default:
            if finishedMigration {
                page = .profile
            } else {
                advance()
            }
        }
    }

    private func advance() {
        guard let page,
              let index = pages.firstIndex(of: page),
              let next = pages[safeIndex: index + 1]
        else { return }
        self.page = next
    }

    /// Determined once, so the page does not disappear while it is presented once the permission was granted.
    @Sendable
    private func determineHealthPageVisibility() async {
        guard LegacyMigrationHelper.legacyHealthSyncEnabled, let healthSyncService else {
            continueHealthSync = false
            return
        }
        await healthSyncService.refreshAuthorizationStatus()
        showsHealthPage = healthSyncService.authorizationStatus.isRequestable
        if !showsHealthPage {
            continueHealthSync = true
            migrateHealthConfigurationIfReady()
        }
    }

    private func grantHealthPermissionAndAdvance() {
        Task {
            do {
                if let healthSyncService, healthSyncService.authorizationStatus.isRequestable {
                    try await healthSyncService.requestAuthorization()
                }
                continueHealthSync = true
                migrateHealthConfigurationIfReady()
                advance()
            } catch {
                healthRequestError = error
            }
        }
    }

    private func declineHealthSync() {
        continueHealthSync = false
        advance()
    }

    /// Restores the legacy Health sync configuration once the migration finished and the user decided to continue syncing, whichever
    /// happens last.
    private func migrateHealthConfigurationIfReady() {
        guard finishedMigration, let continueHealthSync else { return }
        Task {
            await LegacyMigrationHelper.migrateHealthConfiguration(in: core, continueHealthSync: continueHealthSync)
        }
    }
    
    private func prefillDraft() {
        guard !prefilledDraft, let user = core.user else { return }
        prefilledDraft = true
        draft = .init(from: user)
    }
    
    private func saveProfileAndAdvance() {
        Task {
            savingProfile = true
            do {
                try await core.updateUserProperties(
                    name: draft.trimmedName,
                    birthday: draft.birthday,
                    weight: draft.weightInKilograms,
                    sex: draft.sex
                )
                advance()
            } catch {
                self.error = error
            }
            savingProfile = false
        }
    }
    
    private func openSupportMail() {
        guard let url = URL(string: ExternalURL.support) else { return }
        UIApplication.shared.open(url)
    }
    
    @Sendable
    private func migrationAction() async {
        guard let legalAcceptanceDate else { return }
        do {
            let start: Date = .now
            let (_, progressStream) = LegacyMigrationHelper.performLegacyMigration(
                core: core,
                legalAcceptanceDate: legalAcceptanceDate
            )
            for try await progress in progressStream {
                try Task.checkCancellation()
                let duration = start.distance(to: .now)
                let estimatedEnd: Date? = if progress.isFinite, progress > .zero, progress < 1, duration > 10 {
                    start.addingTimeInterval(duration / Double(progress))
                } else {
                    nil
                }
                await MainActor.run { status = .running(progress: progress, estimatedEnd: estimatedEnd) }
            }
            await MainActor.run {
                status = .done
                migrateHealthConfigurationIfReady()
            }
        } catch {
            await MainActor.run { self.error = error }
        }
    }

    // MARK: Types

    private enum Page: Hashable, CaseIterable {
        case update
        case legal
        case newLook
        case performance
        case privacy
        case profile
        case appleHealth
        case done

        var titleKey: LocalizedStringKey {
            switch self {
            case .newLook: "legacy_migration_new_look_title"
            case .performance: "legacy_migration_performance_title"
            case .privacy: "legacy_migration_privacy_title"
            default: "error"
            }
        }

        var messageKey: LocalizedStringKey {
            switch self {
            case .newLook: "legacy_migration_new_look_message"
            case .performance: "legacy_migration_performance_message"
            case .privacy: "legacy_migration_privacy_message"
            default: "error"
            }
        }

        var systemImage: String {
            switch self {
            case .newLook: "paintbrush.fill"
            case .performance: "gauge.with.dots.needle.100percent"
            case .privacy: "lock.shield.fill"
            default: "exclamationmark.triangle.fill"
            }
        }
    }
}
