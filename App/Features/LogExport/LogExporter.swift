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

import Foundation
import OSLog
import OutRunCore
import UniformTypeIdentifiers

/// Reads the log entries the app and ``OutRunCore`` wrote since the app was launched and formats them as CSV.
enum LogExporter {

    private static let subsystems = [OutRun.identifier, OutRunCore.moduleIdentifier]
    private static let header = ["date", "level", "subsystem", "category", "message"]

    /// - note: The system only grants an app access to the entries of its current process, so entries of earlier launches are not included.
    @concurrent
    static func csv() async throws -> Data {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let predicate = NSPredicate(format: "subsystem IN %@", subsystems)
        let entries = try store.getEntries(matching: predicate)
        let dateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true, timeZone: Calendar.current.timeZone)
        var lines = [row(header)]
        for case let entry as OSLogEntryLog in entries {
            try Task.checkCancellation()
            lines.append(row([
                entry.date.formatted(dateStyle),
                entry.level.name,
                entry.subsystem,
                entry.category,
                entry.composedMessage,
            ]))
        }
        return Data(lines.joined(separator: "\r\n").utf8)
    }

    /// Writes the CSV to a file with the given name inside a new temporary directory and returns the file's URL.
    /// - bote: The caller is responsible for removing the directory containing the file once it is no longer needed.
    @concurrent
    static func temporaryFile(named filename: String) async throws -> URL {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appending(path: filename).appendingPathExtension(for: .commaSeparatedText)
        try await csv().write(to: file, options: [.atomic, .completeFileProtection])
        return file
    }

    private static func row(_ fields: [String]) -> String {
        fields.map(escaped).joined(separator: ",")
    }

    private static func escaped(_ field: String) -> String {
        guard field.contains(where: { [",", "\"", "\n", "\r"].contains($0) }) else { return field }
        return "\"" + field.replacing("\"", with: "\"\"") + "\""
    }
}
