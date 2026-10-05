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
    
    private static nonisolated let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter.internetDateTimeWithFractionalSeconds()
            let dateString = formatter.string(from: date)
            try container.encode(dateString)
        }
        return encoder
    }()
    
    private static nonisolated let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatter = ISO8601DateFormatter.internetDateTimeWithFractionalSeconds()
            guard let date = formatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date Format is not valid.")
            }
            return date
        }
        return decoder
    }()
    
    // MARK: - Backup
    
    enum BackupWarning: Hashable, Sendable {
        /// Individual files will be written to the provided directory. The user might not expect a large number of files to be saved and
        /// should be made aware before continuing.
        case individualFilesWillBeWritten
    }
    
    /// - note: This function expects a directory `url`.
    func checkBackupURL(_ url: URL, for type: BackupType) throws -> Set<BackupWarning> {
        if case .gpx = type {
            [.individualFilesWillBeWritten]
        } else {
            []
        }
    }
    
    private static nonisolated func createModelFile(for workout: RawWorkout, at url: URL) throws {
        let data = try encoder.encode(workout)
        try data.write(to: url)
    }
    
    private static nonisolated func createGPXFile(for workout: RawWorkout, at url: URL) throws {
        let track = GPXTrack(from: workout)
        let xml = GPXExporter(track: track, creatorName: "OutRun").xmlString
        guard let data = xml.data(using: .utf8) else { throw BackupServiceError.couldNotEncodeData }
        try data.write(to: url)
    }
    
    private static nonisolated func createBackupFile(for workout: RawWorkout, of type: BackupType, at url: URL) throws {
        switch type {
        case .model: try createModelFile(for: workout, at: url)
        case .gpx: try createGPXFile(for: workout, at: url)
        case .legacy: throw BackupServiceError.couldNotEncodeData
        }
    }
    
    /// - note: This function expects a directory `url`.
    func backup(_ workoutIds: Set<Workout.ID>? = .none, to url: URL, using type: BackupType) -> JobResult<URL> {
        let timestamp = Date.now
        let (stream, continuation) = ProgressStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        let task: Task<URL, Error> = Task { [core] in
            do {
                let container = await core.modelContainer
                let context = ModelContext(container)
                var descriptor = FetchDescriptor<Workout>()
                let count = try workoutIds?.count ?? context.fetchCount(descriptor)
                guard count > .zero else { throw BackupServiceError.noDataToBackUp }
                descriptor.fetchLimit = 1
                
                let fileManager = FileManager.default
                let archive: Archive?
                let targetURL: URL
                if type.useZipCompression, workoutIds == .none || count > 1 {
                    let archiveName = "outrun_" + type.rawValue + "_" + BackupService.timestampFormatter.string(from: timestamp) + ".zip"
                    let archiveURL = url.appending(component: archiveName)
                    archive = try Archive(url: archiveURL, accessMode: .create, pathEncoding: .utf8)
                    targetURL = try BackupService.makeTemporaryDirectory(named: "outrun_backup")
                } else {
                    archive = .none
                    targetURL = url
                }
                
                continuation.yield(0.05)
                let total = Float(count)
                let workoutIds = workoutIds?.map(\.self) ?? []
                for offset in .zero..<count {
                    if !workoutIds.isEmpty, let id = workoutIds[safeIndex: offset] {
                        descriptor.predicate = #Predicate { $0.id == id }
                        descriptor.fetchOffset = nil
                    } else {
                        descriptor.fetchOffset = offset
                    }
                    guard let workout = try context.fetch(descriptor).first else { continue }
                    let rawWorkout = RawWorkout(workout: workout)
                    let workoutFileName = workout.id.uuidString + "." + type.fileExtension
                    let workoutURL = targetURL.appending(components: workoutFileName)
                    try BackupService.createBackupFile(for: rawWorkout, of: type, at: workoutURL)
                    if let archive {
                        try archive.addEntry(with: workoutFileName, fileURL: workoutURL, compressionMethod: .deflate)
                    }
                    continuation.yield(0.05 + 0.90 * Float(offset + 1) / total)
                }
                
                if archive != nil { try fileManager.removeItem(at: targetURL) }
                continuation.yield(1)
                continuation.finish()
                return if let archive { archive.url } else { targetURL }
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
        var warnings = Set<RestoreWarning>()
        let resourceKeys = Set<URLResourceKey>([.isDirectoryKey])
        if try url.resourceValues(forKeys: resourceKeys).isDirectory ?? false, let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys.map(\.self),
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in DirectoryIterator(enumerator: enumerator) {
                let isDirectory = (try? fileURL.resourceValues(forKeys: resourceKeys).isDirectory) ?? false
                guard !isDirectory else { continue }
                let type = BackupService.backupTypeForFile(at: fileURL)
                if let type, type == .gpx {
                    warnings.insert(.gpxWillAlwaysAddNewWorkouts)
                } else if type == nil {
                    warnings.insert(.notAllFilesAreImportable)
                }
                // we can break if all warnings are presented anyways
                if Set(RestoreWarning.allCases).subtracting(warnings).isEmpty {
                    break
                }
            }
        } else if let type = BackupService.backupTypeForFile(at: url), type == .gpx {
            warnings.insert(.gpxWillAlwaysAddNewWorkouts)
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
    
    private static nonisolated func restoreModelFile(at url: URL, into core: OutRunCore) async throws {
        let data = try Data(contentsOf: url)
        let workout = try decoder.decode(RawWorkout.self, from: data)
        try await core.upsert(workout)
    }
    
    private static nonisolated func restoreGPXFile(at url: URL, into core: OutRunCore) async throws {
        guard let parser = GPXFileParser(url: url), case .success(let track) = parser.parse()
        else { throw BackupServiceError.backupNotReadable }
        let workout = RawWorkout(from: track)
        try await core.upsert(workout)
    }
    
    /// - returns: A RestoreBackupResult instance if reading the file was successful.
    /// - throws: If reading the legacy file fails, but not if inserting a workout fails.
    private static nonisolated func restoreLegacyFile(at url: URL, into core: OutRunCore) async throws -> RestoreBackupResult {
        let data = try Data(contentsOf: url)
        let workouts = try LegacyBackupHelper.restore(from: data)
        var result = RestoreBackupResult()
        for workout in workouts {
            do {
                try await core.upsert(workout)
                result.upserted += 1
            } catch OutRunCoreError.newerWorkoutVersionExists {
                result.skipped += 1
            } catch {
                result.failed += 1
            }
        }
        return result
    }
    
    private static nonisolated func restoreBackupFile(
        at url: URL,
        into core: OutRunCore
    ) async throws -> RestoreBackupResult? {
        guard let type = backupTypeForFile(at: url) else { throw BackupServiceError.unsupportedFile }
        switch type {
        case .model: try await restoreModelFile(at: url, into: core)
        case .gpx: try await restoreGPXFile(at: url, into: core)
        case .legacy: return try await restoreLegacyFile(at: url, into: core)
        }
        return nil
    }
    
    func restore(from url: URL) -> JobResult<RestoreBackupResult> {
        let (stream, continuation) = ProgressStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        let task: Task<RestoreBackupResult, Error> = Task { [core] in
            do {
                continuation.yield(0.05)
                var result = RestoreBackupResult()
                let fileManager = FileManager.default
                let resourceKeys = Set<URLResourceKey>([.isDirectoryKey])
                
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
                    let total = Float(fileURLs.count)
                    for (index, fileURL) in fileURLs.enumerated() {
                        await BackupService.handleResult(&result) {
                            try await BackupService.restoreBackupFile(at: fileURL, into: core)
                        }
                        continuation.yield(0.05 + 0.90 * Float(index + 1) / total)
                    }
                } else {
                    let fileExtension = url.standardizedFileURL.pathExtension
                    if fileExtension == "zip" {
                        let archive = try Archive(url: url, accessMode: .read)
                        let entries = Array(archive), total = Float(entries.count)
                        for (index, entry) in entries.enumerated() {
                            await BackupService.handleResult(&result) {
                                let data = try await archive.extract(entry)
                                let workout = try BackupService.decoder.decode(RawWorkout.self, from: data)
                                try await core.upsert(workout)
                                return nil
                            }
                            continuation.yield(0.05 + 0.90 * Float(index + 1) / total)
                        }
                    } else {
                        await BackupService.handleResult(&result) {
                            try await BackupService.restoreBackupFile(at: url, into: core)
                        }
                    }
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
    
    // MARK: - Helpers
    
    private static nonisolated func makeTemporaryDirectory(named name: String) throws -> URL {
        let fileManager = FileManager.default
        let url = fileManager.temporaryDirectory.appending(path: name, directoryHint: .isDirectory)
        if fileManager.fileExists(atPath: url.path()) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
        return url
    }
    
    private static nonisolated let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
    
    private static nonisolated func handleResult(
        _ result: inout RestoreBackupResult,
        action: @escaping () async throws -> RestoreBackupResult?
    ) async {
        do {
            if let newResult = try await action() {
                result += newResult
            } else {
                result.upserted += 1
            }
        } catch OutRunCoreError.newerWorkoutVersionExists {
            result.skipped += 1
        } catch {
            result.failed += 1
        }
    }
    
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
}
