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

import SwiftUI
import UniformTypeIdentifiers

private struct BackupImportModifier: ViewModifier {
    
    @Environment(BackupService.self) private var backupService
    @Binding private var process: BackupProcess?
    @Binding private var isPresented: Bool
    
    init(process: Binding<BackupProcess?>, isPresented: Binding<Bool>) {
        _process = process
        _isPresented = isPresented
    }
    
    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: _isPresented,
            allowedContentTypes: [.zip, .json, .init(filenameExtension: "gpx"), .init(filenameExtension: "orbup")].compactMap(\.self),
            allowsMultipleSelection: false,
            onCompletion: processResult
        )
    }
    
    private func processResult(_ result: Result<[URL], Error>) {
        Task {
            process = .import(progress: .zero)
            do {
                let urls = try result.get()
                guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                let (task, progressSequence) = backupService.restore(from: url)
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
}

extension View {
    
    @ViewBuilder
    func backupImport(process: Binding<BackupProcess?>, pickBackupToRestore: Binding<Bool>) -> some View {
        modifier(BackupImportModifier(process: process, isPresented: pickBackupToRestore))
    }
}
