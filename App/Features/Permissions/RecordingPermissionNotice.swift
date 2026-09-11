import OutRunCore
import SwiftUI

struct RecordingPermissionNotice: View {

    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(\.scenePhase) private var scenePhase

    let dismiss: () -> Void

    private var requiredPermissionsMissing: Bool {
        recorder.missingPermissions.contains { $0.isRequired }
    }

    var body: some View {
        List {
            header
            permissionCards
        }
        .customBottomSafeAreaBar(content: dismissBar)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await recorder.refreshPermissionStatuses()
        }
    }

    @ViewBuilder private var header: some View {
        Section {
            VStack(spacing: .small) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                    .padding(.bottom, .small)
                Text("recording_permissions_notice_title").font(.title2.bold())
                Text("recording_permissions_notice_message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder private var permissionCards: some View {
        ForEach(PermissionItem.recordingItems(for: recorder)) { item in
            PermissionRow(item: item)
        }
    }

    @ViewBuilder
    private func dismissBar() -> some View {
        VStack(spacing: .regular) {
            if requiredPermissionsMissing {
                Text("recording_permissions_notice_required_hint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            ActionButton("recording_permissions_notice_dismiss_action", action: dismiss)
                .disabled(requiredPermissionsMissing)
        }
    }
}
