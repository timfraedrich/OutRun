import OutRunCore
import SwiftUI

/// This view functions as an overlay for the app before a legacy migration has been performed. If no legacy migration is appropriate this
/// view appears as an EmptyView.
///
/// This view can be added as an overlay above other app views as follows:
/// ```swift
/// ZStack {
///     Text("Your App View")
///     LegacyMigrationView()
/// }
/// ```
struct LegacyMigrationView: View {
    
    @Environment(OutRunCore.self) private var core
    
    @State private var isMigrationAppropriate: Bool
    @State private var progress: Double = 0
    @State private var error: Error?
    
    var body: some View {
        if isMigrationAppropriate {
            ZStack {
                VStack(alignment: .leading, spacing: .regular) {
                    Text(R.string.localizable.legacy_migration_view_title)
                        .font(.title.bold())
                    Text(R.string.localizable.legacy_migration_view_message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let error {
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .controlSize(.large)
                        .animation(.default, value: progress)
                }
                .padding(.extraLarge)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .task {
                do {
                    progress = 0.2
                    try await LegacyMigrationHelper.performLegacyMigration(core: core)
                    progress = 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isMigrationAppropriate = false
                    }
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    init() {
        self.isMigrationAppropriate = LegacyMigrationHelper.isLegacyMigrationAppropriate
    }
}
