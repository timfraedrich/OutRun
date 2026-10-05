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
    @State private var status: LegacyMigrationProgressView.Status = .running(progress: 0, estimatedEnd: nil)
    @State private var error: Error?

    private let dismissAction: () -> Void

    private var finishedMigration: Bool { status == .done }
    private var weightUnit: UnitMass {
        core.userPreferences?.safeWeightUnit(for: locale) ?? UserPreferences.fallbackWeightUnit(for: locale)
    }
    private var primaryActionTitleKey: LocalizedStringKey {
        switch page {
        case .profile: "save"
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
        .task(migrationAction)
        .onChange(of: core.user?.id, initial: true, prefillDraft)
    }

    // MARK: Pages

    @ViewBuilder private var pageContent: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(Page.allCases, id: \.self) { page in
                        content(for: page)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $page)
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
        case .profile:
            SetupPageView(
                systemImage: "person.crop.circle.fill",
                title: "legacy_migration_profile_title",
                message: "legacy_migration_profile_message"
            ) {
                SetupProfileForm(draft: $draft, weightUnit: weightUnit)
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
                    EstimatedTimeRemainingText(estimatedEnd: status.estimatedEnd)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
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
            PageIndicator(items: Page.allCases, selection: page)
                .foregroundStyle(.tint, .tertiary)
            VStack(spacing: .small) {
                if page != .done && page != .profile {
                    LegacyMigrationProgressView(status: status)
                        .animation(.default, value: status)
                        .transition(.scale.combined(with: .opacity))
                }
                ActionButton(primaryActionTitleKey, action: primaryAction)
                    .disabled(page == .profile && !draft.isComplete || page == .done && !finishedMigration)
                if page == .profile {
                    ActionButton("skip_action", prominent: false, action: advance)
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
        case .profile:
            saveProfileAndAdvance()
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
              let index = Page.allCases.firstIndex(of: page),
              let next = Page.allCases[safeIndex: index + 1]
        else { return }
        self.page = next
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
        do {
            let start: Date = .now
            let (_, progressStream) = LegacyMigrationHelper.performLegacyMigration(core: core)
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
                core.userPreferences?.recordLegalAcceptanceIfNeeded()
                status = .done
            }
        } catch {
            await MainActor.run { self.error = error }
        }
    }

    // MARK: Types

    private enum Page: Hashable, CaseIterable {
        case update
        case newLook
        case performance
        case privacy
        case profile
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
