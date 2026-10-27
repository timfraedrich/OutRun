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

import AsyncAlgorithms
import SwiftData
import Cache
import Foundation
import GPXKit
import OutRunCore
import ZIPFoundation

@Observable
class BackupService {
    
    typealias ProgressStream = AsyncThrowingStream<Float, Error>
    typealias JobResult<ReturnType> = (task: Task<ReturnType, Error>, progressStream: ProgressStream)
    private typealias WorkoutStream = AsyncThrowingStream<RawWorkout, Error>
    
    private let core: OutRunCore
    
    init(core: OutRunCore) {
        self.core = core
    }
    
    // MARK: - JSON Coding
    
    private static nonisolated let dateFormatStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    
    private static nonisolated let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(dateFormatStyle))
        }
        return encoder
    }()
    
    private static nonisolated let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            guard let date = try? Date(dateString, strategy: dateFormatStyle) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date Format is not valid.")
            }
            return date
        }
        return decoder
    }()
    
    // MARK: - Backup
    
    enum BackupWarning: Hashable, Sendable, CaseIterable {
        /// Individual files will be written to the provided directory. The user might not expect a large number of files to be saved and
        /// should be made aware before continuing.
        case individualFilesWillBeWritten
    }
    
    func checkBackup(_ workoutIds: Set<Workout.ID>? = .none, using type: BackupType) -> Set<BackupWarning> {
        if !type.useZipCompression, workoutIds?.count != 1 {
            [.individualFilesWillBeWritten]
        } else {
            []
        }
    }
    
    private static nonisolated func backupData(for workout: RawWorkout, of type: BackupType) throws -> Data {
        switch type {
        case .model:
            return try encoder.encode(workout)
        case .gpx:
            let xml = GPXExporter(track: GPXTrack(from: workout), creatorName: "OutRun").xmlString
            guard let data = xml.data(using: .utf8) else { throw BackupServiceError.couldNotEncodeData }
            return data
        case .legacy:
            throw BackupServiceError.couldNotEncodeData
        }
    }
    
    private static nonisolated func fetchBackupFile(
        forWorkoutWith identifier: PersistentIdentifier,
        of type: BackupType,
        in container: ModelContainer
    ) throws -> BackupFile? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.persistentModelID == identifier })
        descriptor.fetchLimit = 1
        guard let workout = try context.fetch(descriptor).first else { return nil }
        let data = try backupData(for: RawWorkout(workout: workout), of: type)
        return BackupFile(name: workout.id.uuidString + "." + type.fileExtension, data: data)
    }
    
    /// - note: This function expects a directory `url`.
    func backup(_ workoutIds: Set<Workout.ID>? = .none, to url: URL, using type: BackupType) -> JobResult<URL> {
        let timestamp = Date.now
        let (stream, continuation) = ProgressStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        let task: Task<URL, Error> = Task { [core] in
            do {
                let container = await core.modelContainer
                var descriptor = FetchDescriptor<Workout>()
                if let workoutIds = workoutIds.map(Array.init) {
                    descriptor.predicate = #Predicate { workoutIds.contains($0.id) }
                }
                let identifiers = try ModelContext(container).fetchIdentifiers(descriptor)
                guard !identifiers.isEmpty else { throw BackupServiceError.noDataToBackUp }
                
                let archive: Archive?
                if type.useZipCompression, workoutIds?.count != 1 {
                    let archiveName = "outrun_" + type.rawValue + "_" + BackupService.timestampFormatter.string(from: timestamp) + ".zip"
                    archive = try Archive(url: url.appending(component: archiveName), accessMode: .create, pathEncoding: .utf8)
                } else {
                    archive = .none
                }
                
                continuation.yield(0.05)
                let total = Float(identifiers.count)
                let maxConcurrentTasks = ProcessInfo.processInfo.activeProcessorCount
                try await withThrowingTaskGroup(of: BackupFile?.self) { group in
                    var finishedCount = 0
                    func write(_ file: BackupFile?) throws {
                        if let file {
                            if let archive {
                                try archive.addEntry(
                                    with: file.name,
                                    type: .file,
                                    uncompressedSize: Int64(file.data.count),
                                    compressionMethod: .deflate
                                ) { position, size in
                                    file.data.subdata(in: Int(position)..<Int(position) + size)
                                }
                            } else {
                                try file.data.write(to: url.appending(component: file.name))
                            }
                        }
                        finishedCount += 1
                        continuation.yield(0.05 + 0.90 * Float(finishedCount) / total)
                    }
                    for (index, identifier) in identifiers.enumerated() {
                        if index >= maxConcurrentTasks, let file = try await group.next() {
                            try write(file)
                        }
                        group.addTask {
                            try BackupService.fetchBackupFile(forWorkoutWith: identifier, of: type, in: container)
                        }
                    }
                    while let file = try await group.next() {
                        try write(file)
                    }
                }
                
                continuation.yield(1)
                continuation.finish()
                return archive?.url ?? url
            } catch {
                continuation.finish(throwing: error)
                throw error
            }
        }
        return (task, stream)
    }
    
    // MARK: - Restore
    
    enum RestoreWarning: Hashable, Sendable, CaseIterable {
        case gpxWillAlwaysAddNewWorkouts
        case notAllFilesAreImportable
    }
    
    func checkRestoreURL(_ url: URL) throws -> Set<RestoreWarning> {
        let resourceKeys = Set<URLResourceKey>([.isDirectoryKey])
        if try url.resourceValues(forKeys: resourceKeys).isDirectory ?? false, let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys.map(\.self),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            let fileURLs = DirectoryIterator(enumerator: enumerator).lazy
                .compactMap { $0 as? URL }
                .filter { !((try? $0.resourceValues(forKeys: resourceKeys).isDirectory) ?? false) }
            return BackupService.restoreWarnings(forFilesAt: fileURLs)
        } else if url.standardizedFileURL.pathExtension == "zip" {
            let archive = try Archive(url: url, accessMode: .read)
            let fileURLs = archive.lazy
                .filter { $0.type == .file }
                .map { URL(filePath: $0.path) }
                .filter { !$0.lastPathComponent.hasPrefix(".") }
            return BackupService.restoreWarnings(forFilesAt: fileURLs)
        } else {
            return BackupService.restoreWarnings(forFilesAt: [url])
        }
    }
    
    private static nonisolated func restoreWarnings(forFilesAt fileURLs: some Sequence<URL>) -> Set<RestoreWarning> {
        var warnings = Set<RestoreWarning>()
        for fileURL in fileURLs {
            switch backupTypeForFile(at: fileURL) {
            case .gpx: warnings.insert(.gpxWillAlwaysAddNewWorkouts)
            case .none: warnings.insert(.notAllFilesAreImportable)
            case .model, .legacy: break
            }
            // we can break if all warnings are presented anyways
            if warnings.count == RestoreWarning.allCases.count { break }
        }
        return warnings
    }
    
    private static nonisolated func backupTypeForFile(at url: URL) -> BackupType? {
        let fileExtension = url.standardizedFileURL.pathExtension
        for type in BackupType.allCases where type.fileExtension == fileExtension {
            return type
        }
        return .none
    }
    
    private static nonisolated func decodeBackupFile(at url: URL) throws -> [RawWorkout] {
        guard let type = backupTypeForFile(at: url) else { throw BackupServiceError.unsupportedFile }
        return try decodeBackup(Data(contentsOf: url), of: type)
    }
    
    private static nonisolated func decodeBackup(_ data: Data, of type: BackupType) throws -> [RawWorkout] {
        switch type {
        case .model:
            return [try decoder.decode(RawWorkout.self, from: data)]
        case .gpx:
            guard let xmlString = String(data: data, encoding: .utf8),
                  case .success(let track) = GPXFileParser(xmlString: xmlString).parse()
            else { throw BackupServiceError.backupNotReadable }
            return [RawWorkout(from: track)]
        case .legacy:
            return try LegacyBackupHelper.restore(from: data)
        }
    }
    
    func restore(from url: URL) -> JobResult<RestoreBackupResult> {
        let (stream, continuation) = ProgressStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        let task: Task<RestoreBackupResult, Error> = Task { [core] in
            do {
                continuation.yield(0.05)
                let fileManager = FileManager.default
                let resourceKeys = Set<URLResourceKey>([.isDirectoryKey])
                let result: RestoreBackupResult
                
                if try url.resourceValues(forKeys: resourceKeys).isDirectory ?? false, let enumerator = fileManager.enumerator(
                    at: url,
                    includingPropertiesForKeys: resourceKeys.map(\.self),
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) {
                    var fileURLs: [URL] = []
                    for case let fileURL as URL in DirectoryIterator(enumerator: enumerator) {
                        let isDirectory = (try? fileURL.resourceValues(forKeys: resourceKeys).isDirectory) ?? false
                        guard !isDirectory, BackupService.backupTypeForFile(at: fileURL) != nil else { continue }
                        fileURLs.append(fileURL)
                    }
                    result = try await BackupService.restore(
                        fileURLs.count,
                        into: core,
                        reportingProgressTo: continuation,
                        load: { fileURLs[$0] },
                        decode: BackupService.decodeBackupFile
                    )
                } else if url.standardizedFileURL.pathExtension == "zip" {
                    let archive = try Archive(url: url, accessMode: .read)
                    let entries = archive.compactMap { entry -> (entry: ZIPFoundation.Entry, type: BackupType)? in
                        let entryURL = URL(filePath: entry.path)
                        guard entry.type == .file, !entryURL.lastPathComponent.hasPrefix("."),
                              let type = BackupService.backupTypeForFile(at: entryURL)
                        else { return nil }
                        return (entry, type)
                    }
                    result = try await BackupService.restore(
                        entries.count,
                        into: core,
                        reportingProgressTo: continuation,
                        load: { (data: try archive.extract(entries[$0].entry), type: entries[$0].type) },
                        decode: { try BackupService.decodeBackup($0.data, of: $0.type) }
                    )
                } else {
                    result = try await BackupService.restore(
                        1,
                        into: core,
                        reportingProgressTo: continuation,
                        load: { _ in url },
                        decode: BackupService.decodeBackupFile
                    )
                }
                
                continuation.yield(1)
                continuation.finish()
                return result
            } catch {
                continuation.finish(throwing: error)
                throw error
            }
        }
        return (task, stream)
    }
    
    /// Decodes the backup items in parallel and upserts the decoded workouts in batches.
    /// - parameter load: Provides the payload of the backup item at the given index. It is called serially on the calling task, so it may
    /// access resources that are not safe to be used concurrently.
    /// - parameter decode: Decodes the workouts from the payload of a backup item. It is called concurrently.
    /// - throws: Throws if upserting fails as a whole, but not if a single item cannot be read or a single workout cannot be upserted.
    private static nonisolated func restore<Payload: Sendable>(
        _ itemCount: Int,
        into core: OutRunCore,
        reportingProgressTo continuation: ProgressStream.Continuation,
        load: (Int) throws -> Payload,
        decode: @escaping @Sendable (Payload) throws -> [RawWorkout]
    ) async throws -> RestoreBackupResult {
        let maxConcurrentTasks = ProcessInfo.processInfo.activeProcessorCount
        return try await withThrowingTaskGroup(of: Result<[RawWorkout], any Error>.self) { group in
            var batch = RestoreBatch(core: core, itemCount: itemCount, continuation: continuation)
            for index in 0..<itemCount {
                if index >= maxConcurrentTasks, let item = try await group.next() {
                    try await batch.add(item)
                }
                do {
                    let payload = try load(index)
                    group.addTask { Result { try decode(payload) } }
                } catch {
                    try await batch.add(.failure(error))
                }
            }
            while let item = try await group.next() {
                try await batch.add(item)
            }
            try await batch.upsertPendingWorkouts()
            return batch.result
        }
    }
    
    // MARK: - Helpers
    
    private static nonisolated let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
    
    // MARK: - Models
    
    struct RestoreBackupResult: Hashable, Sendable, AdditiveArithmetic {
        
        var upserted: Int = 0
        var skipped: Int = 0
        var failed: Int = 0
        
        var total: Int { upserted + skipped + failed }
        
        static let zero: BackupService.RestoreBackupResult = .init()
        
        static func + (lhs: RestoreBackupResult, rhs: RestoreBackupResult) -> RestoreBackupResult {
            .init(
                upserted: lhs.upserted + rhs.upserted,
                skipped: lhs.skipped + rhs.skipped,
                failed: lhs.failed + rhs.failed
            )
        }
        
        static func - (lhs: BackupService.RestoreBackupResult, rhs: BackupService.RestoreBackupResult) -> BackupService.RestoreBackupResult {
            .init(
                upserted: lhs.upserted - rhs.upserted,
                skipped: lhs.skipped - rhs.skipped,
                failed: lhs.failed - rhs.failed
            )
        }
    }
    
    private struct WorkoutExtractionError: Error {}
    
    private struct BackupFile: Sendable {
        let name: String
        let data: Data
    }
    
    /// Collects decoded workouts to upsert them in batches, which reduces the number of saves.
    private struct RestoreBatch {
        
        private static let size = 25
        
        private let core: OutRunCore
        private let itemCount: Int
        private let continuation: ProgressStream.Continuation
        private(set) var result = RestoreBackupResult()
        private var pendingWorkouts: [RawWorkout] = []
        private var addedItemCount = 0
        
        init(core: OutRunCore, itemCount: Int, continuation: ProgressStream.Continuation) {
            self.core = core
            self.itemCount = itemCount
            self.continuation = continuation
        }
        
        mutating func add(_ item: Result<[RawWorkout], any Error>) async throws {
            switch item {
            case .success(let workouts): pendingWorkouts += workouts
            case .failure: result.failed += 1
            }
            if pendingWorkouts.count >= Self.size { try await upsertPendingWorkouts() }
            addedItemCount += 1
            continuation.yield(0.05 + 0.90 * Float(addedItemCount) / Float(itemCount))
        }
        
        mutating func upsertPendingWorkouts() async throws {
            while !pendingWorkouts.isEmpty {
                let workouts = Array(pendingWorkouts.prefix(Self.size))
                pendingWorkouts.removeFirst(workouts.count)
                for upsertResult in try await core.upsert(workouts) {
                    switch upsertResult {
                    case .success: result.upserted += 1
                    case .failure(OutRunCoreError.newerWorkoutVersionExists): result.skipped += 1
                    case .failure: result.failed += 1
                    }
                }
            }
        }
    }
}
