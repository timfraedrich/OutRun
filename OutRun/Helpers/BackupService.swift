import Foundation
import OutRunCore
import ZIPFoundation

class BackupService {
    
    private let core: OutRunCore
    
    init(core: OutRunCore) {
        self.core = core
    }
    
    func backup(to url: URL) -> (task: Task<URL, Error>, progressStream: AsyncThrowingStream<Float, Error>) {
        let timestamp = Date.now
        let (stream, continuation) = AsyncThrowingStream<Float, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        let task = Task { [core] in
            do {
                let fileManager = FileManager.default
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd-HHmmss"
                let archiveName = "orca_backup_" + formatter.string(from: timestamp) + ".zip"
                let archiveURL = url.appending(component: archiveName)
                let archive = try Archive(url: archiveURL, accessMode: .create)
                let tempDirectoryURL = fileManager.temporaryDirectory.appending(path: "orca_backup", directoryHint: .isDirectory)
                if fileManager.fileExists(atPath: tempDirectoryURL.path()) {
                    try fileManager.removeItem(at: tempDirectoryURL)
                }
                try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: false)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .custom { date, encoder in
                    var container = encoder.singleValueContainer()
                    let formatter = ISO8601DateFormatter.internetDateTimeWithFractionalSeconds()
                    let dateString = formatter.string(from: date)
                    try container.encode(dateString)
                }
                let count = try await core.fetchWorkoutCount()
                continuation.yield(0.05)
                for offset in .zero...count {
                    guard let workout = try await core.fetchWorkouts(limit: 1, offset: offset).first else { break }
                    let workoutData = try encoder.encode(workout)
                    let workoutFileName = workout.id.uuidString + ".json"
                    let workoutURL = tempDirectoryURL.appending(components: workoutFileName)
                    try workoutData.write(to: workoutURL)
                    try archive.addEntry(with: workoutFileName, fileURL: workoutURL, compressionMethod: .deflate)
                    continuation.yield(0.05 + 0.95 * Float(offset + 1) / Float(count))
                }
                try fileManager.removeItem(at: tempDirectoryURL)
                continuation.yield(1)
                continuation.finish()
                return archiveURL
            } catch {
                continuation.finish(throwing: error)
                throw error
            }
        }
        return (task, stream)
    }
    
    func restoreBackup(from url: URL) -> (task: Task<RestoreBackupResult, Error>, progressStream: AsyncThrowingStream<Float, Error>) {
        let (stream, continuation) = AsyncThrowingStream<Float, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        let task = Task { [core] in
            do {
                let archive = try Archive(url: url, accessMode: .read)
                var result = RestoreBackupResult()
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
                let entries = Array(archive)
                let count = entries.count
                continuation.yield(0.05)
                for (offset, entry) in entries.enumerated() {
                    do {
                        let workoutData = try await archive.extract(entry)
                        let workout = try decoder.decode(RawWorkout.self, from: workoutData)
                        try await core.upsert(workout)
                        result.upserted += 1
                    } catch OutRunCoreError.newerWorkoutVersionExists {
                        result.skipped += 1
                    } catch {
                        result.failed += 1
                    }
                    continuation.yield(0.05 + 0.95 * Float(offset + 1) / Float(count))
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
    
    struct RestoreBackupResult {
        var upserted: Int = 0
        var skipped: Int = 0
        var failed: Int = 0
    }
}
