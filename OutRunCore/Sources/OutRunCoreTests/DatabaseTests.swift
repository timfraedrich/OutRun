//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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
@testable import OutRunCore
import Testing

@Suite("Database Tests")
struct DatabaseTests {
    
    @Test("Workout Recording")
    func workoutRecording() async throws {
        let exampleWorkout = try readExampleWorkout()
        guard let endDate = exampleWorkout.endDate else { throw "Example workout has no end date." }
        let database = try await Database(isStoredInMemoryOnly: true)
        let identifier = try await database.initializeWorkout(with: exampleWorkout.type, startDate: exampleWorkout.startDate).id
        let samples: [(Date, Any)] = exampleWorkout.route.map { ($0.timestamp, $0) } + exampleWorkout.pauses.map { ($0.endDate, $0) }
        let sortedSamples = samples.sorted(by: { $0.0 < $1.0 }).map({ $0.1 })
        for sample in sortedSamples {
            if let sample = sample as? RawWorkoutRouteDataSample {
                let updatedDistance: Double = exampleWorkout.distance
                try await database.addRouteSample(
                    sample,
                    toWorkoutWith: identifier,
                    updatedDistance: updatedDistance,
                    updatedEnergy: exampleWorkout.energy,
                    updatedRepetitions: exampleWorkout.repetitions
                )
            } else if let sample = sample as? RawWorkoutPause {
                try await database.addPause(sample, toWorkoutWith: identifier)
            }
        }
        guard var resultWorkout = try await database.finalizeWorkout(with: identifier, endDate: endDate)
        else { throw "Workout was incorrectly discarded" }
        resultWorkout.id = exampleWorkout.id
        resultWorkout.creationDate = exampleWorkout.creationDate
        resultWorkout.lastEditDate = exampleWorkout.lastEditDate
        #expect(resultWorkout == exampleWorkout)
    }
    
    @Test("Continue Workout Recording")
    func continueWorkoutRecording() async throws {
        let exampleWorkout = try readExampleWorkout()
        guard let endDate = exampleWorkout.endDate else { throw "Example workout has no end date." }
        let database = try await Database(isStoredInMemoryOnly: true)
        try await database.insert(exampleWorkout)
        let continueDate = endDate.addingTimeInterval(37)
        _ = try await database.continueWorkout(with: exampleWorkout.id, continueDate: continueDate)
        let newEndDate = continueDate.addingTimeInterval(10)
        guard var resultWorkout = try await database.finalizeWorkout(with: exampleWorkout.id, endDate: newEndDate)
        else { throw "Workout was incorrectly discarded" }
        #expect(resultWorkout.endDate == newEndDate)
        #expect(resultWorkout.pauses.count == exampleWorkout.pauses.count + 1)
        guard let lastPause = resultWorkout.pauses.sorted(by: { $0.endDate < $1.endDate }).last else {
            throw "Result workout has no pauses."
        }
        #expect(lastPause.startDate == endDate && lastPause.endDate == continueDate)
        resultWorkout.pauses.removeAll { $0 == lastPause }
        resultWorkout.endDate = endDate
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
