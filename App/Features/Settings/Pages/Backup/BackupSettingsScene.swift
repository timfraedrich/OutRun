//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
