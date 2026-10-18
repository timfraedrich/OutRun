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
