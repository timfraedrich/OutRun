import OutRunCore
import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsScene: View {
    
    @Environment(BackupService.self) private var backupService
    @State private var inOrExportInProgress: Bool = false
    @State private var exportBackup: Bool = false
    @State private var exportError: Error?
    @State private var importBackup: Bool = false
    @State private var importError: Error?
    
    var body: some View {
        List {
            Section {
                Button(action: exportButtonAction, label: exportButtonContent)
                    .disabled(inOrExportInProgress)
                    .errorPopover($exportError)
                    .fileImporter(
                        isPresented: $exportBackup,
                        allowedContentTypes: [.folder],
                        allowsMultipleSelection: false,
                        onCompletion: processExportResult
                    )
            } header: {
                EmptyView()
            } footer: {
                Text("Export your workout data for safe keeping and to restore it later. The backup will be saved as a .zip archive with .json files for each workout.")
                    .foregroundStyle(.secondary)
            }
            Section {
                Button(action: importButtonAction, label: importButtonContent)
                    .disabled(inOrExportInProgress)
                    .errorPopover($importError)
                    .fileImporter(
                        isPresented: $importBackup,
                        allowedContentTypes: [.zip, .init(filenameExtension: "orbup")!],
                        allowsMultipleSelection: false,
                        onCompletion: processImportResult
                    )
            } header: {
                EmptyView()
            } footer: {
                Text("Import a backup created by this app. The app accepts .zip archives and the old .orbup files. Data already existing in the app will not be overwritten or removed. If you import an outdated workout, it will be skipped.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Backup")
    }
    
    @ViewBuilder
    private func label(systemName: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: .regular) {
            Image(systemName: systemName)
                .font(.title)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .tint)
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func exportButtonContent() -> some View {
        label(systemName: "arrow.up.document.fill", title: "Create Backup")
    }
    
    @ViewBuilder
    private func importButtonContent() -> some View {
        label(systemName: "arrow.down.document.fill", title: "Restore Backup")
    }
    
    private func exportButtonAction() {
        exportBackup = true
    }
    
    private func importButtonAction() {
        importBackup = true
    }
    
    private func processExportResult(_ result: Result<[URL], Error>) {
        Task {
            inOrExportInProgress = true
            do {
                let urls = try result.get()
                guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                let (task, progressSequence) = backupService.backup(to: url)
                for try await progress in progressSequence {
                    print("Progress: \(progress)")
                }
                _ = try await task.value
                // TODO: Show success to user.
            } catch {
                exportError = error
            }
            inOrExportInProgress = false
        }
    }
    
    private func processImportResult(_ result: Result<[URL], Error>) {
        Task {
            inOrExportInProgress = true
            do {
                let urls = try result.get()
                guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                let (task, progressSequence) = backupService.restoreBackup(from: url)
                for try await progress in progressSequence {
                    print("Progress: \(progress)")
                }
                _ = try await task.value
                // TODO: Show result to user.
            } catch {
                importError = error
            }
            inOrExportInProgress = false
        }
    }
}
