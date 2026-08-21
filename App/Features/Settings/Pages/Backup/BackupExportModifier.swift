import OutRunCore
import SwiftUI
import UniformTypeIdentifiers

private struct BackupExportModifier: ViewModifier {
    
    @Environment(BackupService.self) private var backupService
    @Binding private var process: BackupProcess?
    @Binding private var isPresented: Bool
    private let workoutIds: Set<Workout.ID>?
    private let type: BackupType
    
    init(workoutIds: Set<Workout.ID>?, type: BackupType, process: Binding<BackupProcess?>, isPresented: Binding<Bool>) {
        self.workoutIds = workoutIds
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
                let (task, progressSequence) = backupService.backup(workoutIds, to: url, using: type)
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
    func backupExport(
        _ workoutIds: Set<Workout.ID>? = .none,
        of type: BackupType,
        process: Binding<BackupProcess?>,
        pickExportLocation: Binding<Bool>
    ) -> some View {
        modifier(BackupExportModifier(workoutIds: workoutIds, type: type, process: process, isPresented: pickExportLocation))
    }
    
    @ViewBuilder
    func backupExport(
        _ workoutIds: Set<Workout.ID>? = .none,
        of type: Binding<BackupType?>,
        process: Binding<BackupProcess?>
    ) -> some View {
        let pickExportLocation: Binding<Bool> = .init {
            type.wrappedValue != nil
        } set: { newValue in
            guard !newValue else { return }
            type.wrappedValue = nil
        }
        backupExport(workoutIds, of: type.wrappedValue ?? .model, process: process, pickExportLocation: pickExportLocation)
    }
}
