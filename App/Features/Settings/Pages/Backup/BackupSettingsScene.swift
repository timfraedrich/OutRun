import OutRunCore
import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsScene: View {
    
    @Environment(BackupService.self) private var backupService
    @State private var process: Process?
    @State private var pickBackupLocation: Bool = false
    @State private var pickBackupToRestore: Bool = false
    
    var processInProgress: Bool { process != .none }
    
    var body: some View {
        List {
            section(
                title: "backup_export_action",
                systemName: "arrow.up.document.fill",
                explanation: "backup_export_description",
                fileImporterIsPresented: $pickBackupLocation,
                fileImporterAllowedContentTypes: [.folder],
                fileImporterOnCompletion: processExportResult
            )
            section(
                title: "backup_import_action",
                systemName: "arrow.down.document.fill",
                explanation: "backup_import_description",
                fileImporterIsPresented: $pickBackupToRestore,
                fileImporterAllowedContentTypes: [.zip, .init(filenameExtension: "orbup")!],
                fileImporterOnCompletion: processImportResult
            )
        }
        .safeAreaPadding(.top, .regular)
        .navigationBarBackButtonHidden(processInProgress)
        .interactiveDismissDisabled(processInProgress)
        .navigationTitle("backup")
        .dynamicSheet(item: $process, content: processSheetContent)
    }
    
    @ViewBuilder
    private func section(
        title: LocalizedStringKey,
        systemName: String,
        explanation: LocalizedStringKey,
        fileImporterIsPresented: Binding<Bool>,
        fileImporterAllowedContentTypes: [UTType],
        fileImporterOnCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        Section {
            Button {
                fileImporterIsPresented.wrappedValue = true
            } label: {
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
            .buttonStyle(.plain)
            .disabled(processInProgress)
            .fileImporter(
                isPresented: fileImporterIsPresented,
                allowedContentTypes: fileImporterAllowedContentTypes,
                allowsMultipleSelection: false,
                onCompletion: fileImporterOnCompletion
            )
        } header: {
            EmptyView()
        } footer: {
            Text(explanation).foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func processSheetContent(_ process: Process) -> some View {
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
    
    private func processExportResult(_ result: Result<[URL], Error>) {
        Task {
            process = .export(progress: .zero)
            do {
                let urls = try result.get()
                guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                let (task, progressSequence) = backupService.backup(to: url)
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
    
    private func processImportResult(_ result: Result<[URL], Error>) {
        Task {
            process = .import(progress: .zero)
            do {
                let urls = try result.get()
                guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                let (task, progressSequence) = backupService.restoreBackup(from: url)
                for try await progress in progressSequence {
                    process = .import(progress: progress)
                }
                let result = try await task.value
                process = .importSucceeded(result: result)
            } catch {
                process = .importFailed(error: error)
            }
        }
    }
    
    private enum Process: Equatable, Identifiable {
        
        case export(progress: Float)
        case exportSucceeded
        case exportFailed(error: Error)
        case `import`(progress: Float)
        case importSucceeded(result: BackupService.RestoreBackupResult)
        case importFailed(error: Error)
        
        var id: UUID { .init() }
        
        var title: LocalizedStringKey {
            switch self {
            case .export: "backup_export_running_title"
            case .exportSucceeded: "backup_export_success_title"
            case .exportFailed: "backup_export_failed_title"
            case .import: "backup_import_running_title"
            case .importSucceeded: "backup_import_success_title"
            case .importFailed: "backup_import_failed_title"
            }
        }
        
        var message: String {
            switch self {
            case .export, .import: .init(localized: "backup_import_export_running_message")
            case .exportSucceeded: .init(localized: "backup_export_success_message")
            case .importSucceeded(let result): .init(localized: "backup_import_success_message_\(result.total)_total_\(result.upserted)_successfull_\(result.skipped)_skipped_\(result.failed)_failed")
            case .exportFailed(let error), .importFailed(let error): error.localizedDescription
            }
        }
        
        var symbolSystemName: String? {
            switch self {
            case .export, .import: .none
            case .exportSucceeded, .importSucceeded: "checkmark.circle.fill"
            case .exportFailed, .importFailed: "xmark.octagon.fill"
            }
        }
        
        var progress: Float? {
            switch self {
            case .export(let progress), .import(let progress): progress
            case .exportSucceeded, .exportFailed, .importSucceeded, .importFailed: .none
            }
        }
        
        var isDismissable: Bool {
            switch self {
            case .export, .import: false
            case .exportSucceeded, .exportFailed, .importSucceeded, .importFailed: true
            }
        }
        
        static func == (lhs: BackupSettingsScene.Process, rhs: BackupSettingsScene.Process) -> Bool {
            switch (lhs, rhs) {
            case (.export(let lhsProgress), .export(let rhsProgress)),
                 (.import(let lhsProgress), .import(let rhsProgress)):
                lhsProgress == rhsProgress
            case (.exportSucceeded, .exportSucceeded),
                 (.importSucceeded, .importSucceeded),
                 (.exportFailed, .exportFailed),
                 (.importFailed, .importFailed):
                true
            default:
                false
            }
        }
    }
}
