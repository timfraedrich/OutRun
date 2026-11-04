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

private struct LogExportModifier: ViewModifier {

    @Binding var isPresented: Bool
    @Binding var isPreparing: Bool
    @State private var file: URL?
    @State private var isSharing: Bool = false
    @State private var error: Error?

    private var filename: String {
        "OutRun-Logs-" + Date.now.formatted(.iso8601.year().month().day())
    }

    func body(content: Content) -> some View {
        content
            .disabled(isPreparing)
            .alert("log_export_warning_title", isPresented: $isPresented) {
                Button("cancel", role: .cancel) {}
                Button("continue_action", action: prepareExport)
            } message: {
                Text("log_export_warning_message")
            }
            .sheet(isPresented: $isSharing, onDismiss: removeFile) {
                if let file {
                    ShareSheet(items: [file]) {
                        isSharing = false
                    }
                    .presentationDetents([.medium, .large])
                    .ignoresSafeArea()
                }
            }
            .errorPopover($error)
    }

    private func prepareExport() {
        isPreparing = true
        Task {
            defer { isPreparing = false }
            do {
                file = try await LogExporter.temporaryFile(named: filename)
                isSharing = true
            } catch {
                self.error = error
            }
        }
    }

    private func removeFile() {
        guard let file else { return }
        self.file = nil
        try? FileManager.default.removeItem(at: file.deletingLastPathComponent())
    }
}

extension View {

    /// Asks the user to confirm the export of the app's log entries, warning that they may contain sensitive data, and then
    /// lets them share the entries as a CSV file.
    ///
    /// - Parameter isPreparing: Set while the entries are collected, which can take a few seconds.
    func logExport(isPresented: Binding<Bool>, isPreparing: Binding<Bool>) -> some View {
        modifier(LogExportModifier(isPresented: isPresented, isPreparing: isPreparing))
    }
}
