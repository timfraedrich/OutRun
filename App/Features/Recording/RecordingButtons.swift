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

import SwiftUI

struct RecordingButtons: View {
    
    private let isRecording: Bool
    private let isPaused: Bool
    private let startAction: () -> Void
    private let endAction: () -> Void
    private let pauseAction: () -> Void
    private let resumeAction: () -> Void
    
    var body: some View {
        HStack(spacing: .regular) {
            if isRecording {
                pauseResumeButton
            }
            startEndButton
        }
    }
    
    @ViewBuilder private var startEndButton: some View {
        ActionButton(isRecording ? "recording_end_short" : "recording_start_short", action: startEndAction)
    }
    
    @ViewBuilder private var pauseResumeButton: some View {
        ActionButton(maxWidth: nil, action: pauseResumeAction) {
            Image(systemName: isPaused ? "play" : "pause").symbolVariant(.fill)
        }
        .tint(.gray)
    }
    
    init(
        isRecording: Bool,
        isPaused: Bool,
        startAction: @escaping () -> Void,
        endAction: @escaping () -> Void,
        pauseAction: @escaping () -> Void,
        resumeAction: @escaping () -> Void
    ) {
        self.isRecording = isRecording
        self.isPaused = isPaused
        self.startAction = startAction
        self.endAction = endAction
        self.pauseAction = pauseAction
        self.resumeAction = resumeAction
    }
    
    private func startEndAction() {
        if isRecording {
            endAction()
        } else {
            startAction()
        }
    }
    
    private func pauseResumeAction() {
        if isPaused {
            resumeAction()
        } else {
            pauseAction()
        }
    }
}

#Preview {
    RecordingButtons(
        isRecording: true,
        isPaused: false,
        startAction: {},
        endAction: {},
        pauseAction: {},
        resumeAction: {}
    )
}
