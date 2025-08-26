import Foundation
@testable import OutRunCore
import Testing

@Suite("Database Tests")
struct DatabaseTests {
    
    @Test("Workout Recording")
    func workoutRecording() async throws {
        let exampleWorkout = try readExampleWorkout()
        guard let endDate = exampleWorkout.endDate else { throw "Example workout has no end date." }
        let database = try await Database(isStoredInMemoryOnly: true)
        let identifier = try await database.initializeWorkout(with: exampleWorkout.type, startDate: exampleWorkout.startDate)
        let samples: [(Date, Any)] = exampleWorkout.route.map { ($0.timestamp, $0) } + exampleWorkout.pauses.map { ($0.endDate, $0) }
        let sortedSamples = samples.sorted(by: { $0.0 < $1.0 }).map({ $0.1 })
        var routeSampleWasAdded = false
        for sample in sortedSamples {
            if let sample = sample as? RawWorkoutRouteDataSample {
                let addedDistance: Double = routeSampleWasAdded ? 0 : exampleWorkout.distance
                if !routeSampleWasAdded { routeSampleWasAdded = true }
                try await database.addRouteSample(
                    sample,
                    toWorkoutWith: identifier,
                    addedDistance: addedDistance,
                    updatedEnergy: exampleWorkout.energy,
                    updatedRepetitions: exampleWorkout.repetitions
                )
            } else if let sample = sample as? RawWorkoutPause {
                try await database.addPause(sample, toWorkoutWith: identifier)
            }
        }
        var resultWorkout = try await database.finalizeWorkout(with: identifier, endDate: endDate)
        resultWorkout.id = exampleWorkout.id
        resultWorkout.creationDate = exampleWorkout.creationDate
        resultWorkout.lastEditDate = exampleWorkout.lastEditDate
        #expect(resultWorkout == exampleWorkout)
    }
    
    private static let exampleWorkoutFileName = "ExampleWorkout"
    
    private func readExampleWorkout() throws -> RawWorkout {
        guard let url = Bundle.module.url(forResource: Self.exampleWorkoutFileName, withExtension: "json") else {
            throw "Invalid URL for example workout json file."
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RawWorkout.self, from: data)
    }
}
