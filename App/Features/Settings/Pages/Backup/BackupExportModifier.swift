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
import UniformTypeIdentifiers

private struct BackupExportModifier: ViewModifier {
    
    @Environment(BackupService.self) private var backupService
    @Binding private var process: BackupProcess?
    @Binding private var isPresented: Bool
    @State private var pendingBackup: (url: URL, message: String)?
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
        .alert("backup_export_warning_title", isPresented: pendingBackupIsPresented, presenting: pendingBackup) { pendingBackup in
            Button("cancel", role: .cancel) {}
            Button("continue_action") { backup(to: pendingBackup.url) }
        } message: { pendingBackup in
            Text(verbatim: pendingBackup.message)
        }
    }
    
    private var pendingBackupIsPresented: Binding<Bool> {
        .init {
            pendingBackup != nil
        } set: { newValue in
            guard !newValue else { return }
            pendingBackup = nil
        }
    }
    
    private func processResult(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let warnings = backupService.checkBackup(workoutIds, using: type)
            if let firstWarning = warnings.first {
                let message = if warnings.count > 1 {
                    warnings.map { "• " + $0.message }.joined(separator: "\n")
                } else {
                    firstWarning.message
                }
                pendingBackup = (url, message)
            } else {
                backup(to: url)
            }
        } catch {
            process = .exportFailed(error: error)
        }
    }
    
    private func backup(to url: URL) {
        Task {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            process = .export(progress: .zero)
            do {
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
