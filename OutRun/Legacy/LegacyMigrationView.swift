import OutRunCore
import SwiftUI

struct LegacyMigrationView: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(\.openURL) private var openURL
    @Namespace private var namespace
    @State private var finishedMigration: Bool = false
    @State private var showMigrationExplanation: Bool = false
    @State private var progress: Float = 0
    @State private var estimatedEnd: Date?
    @State private var error: Error?
    
    private let dismissAction: () -> Void
    private var iOS26OrLater: Bool { if #available(iOS 26, *) { true } else { false } }
    
    init(dismissAction: @escaping () -> Void) {
        self.dismissAction = dismissAction
    }
    
    private func formattedRemainingTime(for date: Date, estimatedEnd: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .full
        return formatter.string(from: date, to: estimatedEnd) ?? "nil"
    }
    
    private func migrationAction() async {
        do {
            let start: Date = .now
            let (_, progressStream) = LegacyMigrationHelper.performLegacyMigration(core: core)
            for try await progress in progressStream {
                try Task.checkCancellation()
                await MainActor.run { self.progress = progress }
                let duration = start.distance(to: .now)
                guard progress.isFinite, progress > .zero, progress < 1, duration > 10 else { continue }
                await MainActor.run { self.estimatedEnd = start.addingTimeInterval(duration / Double(progress)) }
            }
            sleep(1)
            await MainActor.run { finishedMigration = true }
        } catch {
            await MainActor.run { self.error = error }
        }
    }
    
    // MARK: Views
    
    var body: some View {
        VStack(alignment: .leading, spacing: .regular) {
            if let error {
                errorContent(for: error)
            } else {
                // TODO: Show "Introducing ORCA Workouts" view
            }
        }
        .padding(.extraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, content: bottomSafeAreaContent)
        .ignoresSafeArea(edges: iOS26OrLater ? .bottom : [])
        .tint(error != nil ? .red : nil)
        .animation(.default, value: error == nil)
        .background()
        .task(migrationAction)
    }
    
    @ViewBuilder
    private func bottomSafeAreaContent() -> some View {
        Group {
            if error != nil {
                safeAreaActionButton(R.string.localizable.legacy_migration_view_failed_action()) {
                    // TODO: open support email
                }
            } else if finishedMigration {
                safeAreaActionButton(R.string.localizable.legacy_migration_view_success_action(), action: dismissAction)
            } else {
                migrationContent
            }
        }
        .background { BackgroundBlackoutGradient(startPoint: .top, endPoint: .center) }
        .animation(.default, value: finishedMigration)
        .animation(.default, value: error == nil)
    }
    
    @ViewBuilder private var migrationContent: some View {
        VStack(alignment: .leading, spacing: .extraSmall) {
            HStack(spacing: .small) {
                Text(R.string.localizable.legacy_migration_view_migration_title).font(.headline)
                Button(R.string.localizable.info(), systemImage: "info") {
                    showMigrationExplanation.toggle()
                }
                .symbolVariant(.circle)
                .labelStyle(.iconOnly)
                .popover(isPresented: $showMigrationExplanation) {
                    Text(R.string.localizable.legacy_migration_view_migration_message)
                        .font(.subheadline)
                        .padding(.regular)
                        .frame(width: 300)
                        .presentationCompactAdaptation(.popover)
                }
            }
            Group {
                if let estimatedEnd {
                    TimelineView(.animation(minimumInterval: 1)) { context in
                        let remainingTime = formattedRemainingTime(for: context.date, estimatedEnd: estimatedEnd)
                        Text(R.string.localizable.legacy_migration_view_migration_estimated_time(remainingTime))
                    }
                } else {
                    Text(R.string.localizable.legacy_migration_view_migration_estimating_time)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .controlSize(.large)
                .animation(.default, value: progress)
                .padding(.top, .regular)
            
        }
        .padding(iOS26OrLater ? .large : .regular)
        .background {
            Group {
                if #available(iOS 26, *) {
                    Color.clear.glassEffect(.regular.interactive(), in: .containerRelative)
                } else {
                    Color.secondaryBackground.clipShape(.rect(cornerRadius: .large))
                }
            }
            .matchedGeometryEffect(id: "safeArea", in: namespace, anchor: .bottom)
        }
        .padding(.horizontal, .large)
        .padding(.vertical, iOS26OrLater ? .large : .small)
    }
    
    @ViewBuilder
    private func errorContent(for error: Error) -> some View {
        VStack(spacing: .large) {
            Image(systemName: "exclamationmark.triangle")
                .symbolVariant(.fill)
                .font(.system(size: 64))
            Text(R.string.localizable.legacy_migration_view_failed_title)
                .font(.title.bold())
            Text(error.localizedDescription)
                .font(.title3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.tint)
        .tint(.red)
    }
    
    @ViewBuilder
    private func safeAreaActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        ActionButton(verbatim: title, action: action)
            .padding(.extraLarge)
            .matchedGeometryEffect(id: "safeArea", in: namespace, anchor: .bottom)
    }
}
