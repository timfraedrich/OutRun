import Foundation

enum BackupProcess: Equatable, Identifiable {
    
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
    
    static func == (lhs: BackupProcess, rhs: BackupProcess) -> Bool {
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
