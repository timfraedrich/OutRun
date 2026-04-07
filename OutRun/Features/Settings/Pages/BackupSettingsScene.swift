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
                Button("Create Backup") {
                    exportBackup = true
                }
                .disabled(inOrExportInProgress)
                .fileImporter(isPresented: $exportBackup, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
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
                            let result = try await task.value
                            print("Saved to: \(result)")
                        } catch {
                            importError = error
                        }
                        inOrExportInProgress = false
                    }
                }
            }
            Section {
                Button("Restore Backup") {
                    importBackup = true
                }
                .disabled(inOrExportInProgress)
                .errorPopover($importError)
                .fileImporter(isPresented: $importBackup, allowedContentTypes: [.zip, .init(filenameExtension: "orbup")!], allowsMultipleSelection: false) { result in
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
                            let result = try await task.value
                            print("Import Result: \(result)")
                        } catch {
                            importError = error
                        }
                        inOrExportInProgress = false
                    }
                }
            }
        }
        .navigationTitle("Backup")
    }
}
