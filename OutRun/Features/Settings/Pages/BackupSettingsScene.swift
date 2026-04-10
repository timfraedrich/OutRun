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
                title: "Create Backup",
                systemName: "arrow.up.document.fill",
                explanation: "Export your workout data for safe keeping and to restore it later. The backup will be saved as a .zip archive with .json files for each workout.",
                fileImporterIsPresented: $pickBackupLocation,
                fileImporterAllowedContentTypes: [.folder],
                fileImporterOnCompletion: processExportResult
            )
            section(
                title: "Restore Backup",
                systemName: "arrow.down.document.fill",
                explanation: "Import a backup created by this app. The app accepts .zip archives and the old .orbup files. Data already existing in the app will not be overwritten or removed. If you import an outdated workout, it will be skipped.",
                fileImporterIsPresented: $pickBackupToRestore,
                fileImporterAllowedContentTypes: [.zip, .init(filenameExtension: "orbup")!],
                fileImporterOnCompletion: processImportResult
            )
        }
        .navigationBarBackButtonHidden(processInProgress)
        .interactiveDismissDisabled(processInProgress)
        .navigationTitle("Backup")
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
            case .export: "Creating Backup"
            case .exportSucceeded: "Backup Created"
            case .exportFailed: "Backup Failed"
            case .import: "Importing Backup"
            case .importSucceeded: "Backup Imported"
            case .importFailed: "Import Failed"
            }
        }
        
        var message: String {
            switch self {
            case .export, .import: .init(localized: "This may take a couple of minutes. Please do not close the app.")
            case .exportSucceeded: .init(localized: "The backup was saved to the selected folder.")
            case .importSucceeded(let result): .init(localized: "Of the \(result.total) workouts in the provided backup, \(result.upserted) were successfully imported, \(result.skipped) were skipped, and \(result.failed) failed to import.")
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
