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
        ActionButton(isRecording ? "recording_end" : "recording_start", action: startEndAction)
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
