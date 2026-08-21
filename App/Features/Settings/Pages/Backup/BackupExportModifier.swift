import SwiftUI
import UniformTypeIdentifiers

private struct BackupExportModifier: ViewModifier {
    
    @Environment(BackupService.self) private var backupService
    @Binding private var process: BackupProcess?
    @Binding private var isPresented: Bool
    private let type: BackupType
    
    init(type: BackupType, process: Binding<BackupProcess?>, isPresented: Binding<Bool>) {
        self.type = type
        _process = process
        _isPresented = isPresented
    }
    
    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: _isPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            onCompletion: processResult
        )
    }
    
    private func processResult(_ result: Result<[URL], Error>) {
        Task {
            process = .export(progress: .zero)
            do {
                let urls = try result.get()
                guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                let (task, progressSequence) = backupService.backup(to: url, using: .model)
                for try await progress in progressSequence {
                    process = .export(progress: progress)
                }
                _ = try await task.value
                process = .exportSucceeded
            } catch {
                process = .exportFailed(error: error)
            }
        }
    }
}

extension View {
    
    @ViewBuilder
    func backupExport(of type: BackupType, process: Binding<BackupProcess?>, pickExportLocation: Binding<Bool>) -> some View {
        modifier(BackupExportModifier(type: type, process: process, isPresented: pickExportLocation))
    }
}
