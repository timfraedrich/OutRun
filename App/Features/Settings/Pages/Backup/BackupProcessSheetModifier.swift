import SwiftUI

struct BackupProcessSheetModifier: ViewModifier {
    
    @Binding private var process: BackupProcess?
    
    init(process: Binding<BackupProcess?>) {
        _process = process
    }
    
    func body(content: Content) -> some View {
        content.dynamicSheet(item: $process, content: processSheetContent)
    }
    
    @ViewBuilder
    private func processSheetContent(_ process: BackupProcess) -> some View {
        VStack(spacing: .extraLarge) {
            VStack(spacing: .small) {
                Text(process.title).font(.title).fontWeight(.bold)
                Text(verbatim: process.message).font(.subheadline).foregroundStyle(.secondary).padding(.horizontal, .extraLarge)
            }
            if let symbolSystemName = process.symbolSystemName {
                Image(systemName: symbolSystemName)
                    .symbolRenderingMode(.multicolor)
                    .font(.largeTitle)
            }
            if let progress = process.progress {
                ProgressView(value: progress).progressViewStyle(.linear)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        .padding([.top, .horizontal], .extraLarge)
        .padding(.bottom, .regular)
        .interactiveDismissDisabled(!process.isDismissable)
    }
}

extension View {
    
    @ViewBuilder
    func backupProcessSheet(for process: Binding<BackupProcess?>) -> some View {
        modifier(BackupProcessSheetModifier(process: process))
    }
}
