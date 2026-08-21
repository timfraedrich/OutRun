import OutRunCore
import SwiftUI

struct BackupSettingsScene: View {
    
    @State private var process: BackupProcess?
    @State private var pickBackupLocation: Bool = false
    @State private var pickBackupToRestore: Bool = false
    
    var processInProgress: Bool { process != .none }
    
    var body: some View {
        List {
            section(
                title: "backup_export_action",
                systemName: "arrow.up.document.fill",
                explanation: "backup_export_description",
                fileImporterIsPresented: $pickBackupLocation
            )
            .backupExport(of: .model, process: $process, pickExportLocation: $pickBackupLocation)
            section(
                title: "backup_import_action",
                systemName: "arrow.down.document.fill",
                explanation: "backup_import_description",
                fileImporterIsPresented: $pickBackupToRestore
            )
            .backupImport(process: $process, pickBackupToRestore: $pickBackupToRestore)
        }
        .safeAreaPadding(.top, .regular)
        .navigationBarBackButtonHidden(processInProgress)
        .interactiveDismissDisabled(processInProgress)
        .navigationTitle("backup")
        .backupProcessSheet(for: $process)
    }
    
    @ViewBuilder
    private func section(
        title: LocalizedStringKey,
        systemName: String,
        explanation: LocalizedStringKey,
        fileImporterIsPresented: Binding<Bool>
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
        } header: {
            EmptyView()
        } footer: {
            Text(explanation).foregroundStyle(.secondary)
        }
    }
}
