import Foundation
import ZIPFoundation

extension Archive {
    
    func extract(_ entry: Entry) async throws -> Data {
        try await withCheckedThrowingContinuation { entryContinuation in
            do {
                var fullData = Data()
                let sizeToRead = Int(entry.uncompressedSize)
                _ = try extract(entry, skipCRC32: true) { data in
                    fullData.append(data)
                    guard fullData.count >= sizeToRead else { return }
                    entryContinuation.resume(returning: fullData)
                }
            } catch {
                entryContinuation.resume(throwing: error)
            }
        }
    }
}
