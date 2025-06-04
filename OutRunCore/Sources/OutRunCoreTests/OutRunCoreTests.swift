import Foundation
@testable import OutRunDatabase
import Testing

struct MigrationTests {
    
    private func readExampleData() throws -> [RawWorkout] {
        guard let url = Bundle.module.url(forResource: "ExampleWorkouts", withExtension: "json") else {
            throw "Invalid URL for example workouts json file generated."
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([RawWorkout].self, from: data)
    }
}
