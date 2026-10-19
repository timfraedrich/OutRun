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

struct WorkoutSyncButton: View {
    
    @Environment(OutRunCore.self) private var core
    @State private var isSyncing: Bool = false
    @State private var didSucceed: Bool = false
    @State private var confirmReplacement: Bool = false
    @State private var error: Error?
    let option: WorkoutSyncOption
    let workoutIdentifier: UUID
    let onCompletion: () -> Void
    
    var body: some View {
        Button {
            guard !didSucceed else { return }
            sync(replacingNewerVersion: false)
        } label: {
            Label {
                Text(option.titleKey)
            } icon: {
                if isSyncing {
                    ProgressView()
                } else if didSucceed {
                    Image(systemName: "checkmark.circle")
                } else {
                    Image(systemName: option.systemImage)
                }
            }
            .animation(.default, value: isSyncing)
            .animation(.default, value: didSucceed)
        }
        .disabled(isSyncing)
        .tint(didSucceed ? .green : nil)
        .errorPopover($error)
        .confirmationDialog("sync_conflict_title", isPresented: $confirmReplacement) {
            Button(option.conflictConfirmationKey, role: .destructive) {
                sync(replacingNewerVersion: true)
            }
        } message: {
            Text(option.conflictMessageKey)
        }
    }
    
    private func sync(replacingNewerVersion: Bool) {
        isSyncing = true
        Task {
            do {
                try await core.resync(
                    workoutWithIdentifier: workoutIdentifier,
                    withServiceWith: option.serviceIdentifier,
                    replacingNewerVersion: replacingNewerVersion
                )
                didSucceed = true
            } catch SyncError.conflict where !replacingNewerVersion {
                confirmReplacement = true
            } catch {
                self.error = error
            }
            isSyncing = false
            onCompletion()
            guard didSucceed else { return }
            try? await Task.sleep(for: .seconds(2))
            didSucceed = false
        }
    }
}
