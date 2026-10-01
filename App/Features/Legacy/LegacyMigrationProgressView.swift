import SwiftUI

struct LegacyMigrationProgressView: View {

    let status: Status

    @State private var showMigrationExplanation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: .extraSmall) {
            switch status {
            case .running(let progress, let estimatedEnd):
                runningContent(progress: progress, estimatedEnd: estimatedEnd)
            case .done:
                doneContent
            }
        }
        .padding(.vertical, .regular)
        .padding(.horizontal, .large)
        .background {
            compatibleProgressBackground
        }
    }

    @ViewBuilder
    private func runningContent(progress: Float, estimatedEnd: Date?) -> some View {
        HStack(spacing: .small) {
            Text("legacy_migration_view_migration_title").font(.headline)
            Button("info", systemImage: "info") {
                showMigrationExplanation.toggle()
            }
            .symbolVariant(.circle)
            .labelStyle(.iconOnly)
            .popover(isPresented: $showMigrationExplanation) {
                Text("legacy_migration_view_migration_message")
                    .font(.subheadline)
                    .padding(.regular)
                    .frame(width: 300)
                    .presentationCompactAdaptation(.popover)
            }
        }
        EstimatedTimeRemainingText(estimatedEnd: estimatedEnd)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        ProgressView(value: progress)
            .progressViewStyle(.linear)
            .animation(.default, value: progress)
            .padding(.top, .small)
    }

    @ViewBuilder private var doneContent: some View {
        HStack(spacing: .small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title2)
            Text("legacy_migration_view_migration_finished_title")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var compatibleProgressBackground: some View {
        if #available(iOS 26, *) {
            Color.clear.glassEffect(.regular, in: .rect(cornerRadius: .large))
        } else {
            Rectangle().fill(.background.secondary).clipShape(.rect(cornerRadius: .large))
        }
    }

    enum Status: Hashable {
        case running(progress: Float, estimatedEnd: Date?)
        case done

        var progress: Float {
            if case .running(let progress, _) = self {
                progress
            } else {
                1
            }
        }

        var estimatedEnd: Date? {
            if case .running(_, let estimatedEnd) = self {
                estimatedEnd
            } else {
                nil
            }
        }
    }
}
