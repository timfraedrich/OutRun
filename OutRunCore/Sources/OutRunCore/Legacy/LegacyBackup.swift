import Foundation

struct LegacyBackup<W: Codable>: Codable {
    
    let date: Date
    let version: String
    let workoutData: [W]
}
