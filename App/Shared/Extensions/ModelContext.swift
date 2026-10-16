import Foundation
import OutRunCore
import SwiftData

extension ModelContext {

    /// The number of finished workouts that were recorded with this app.
    func nativeWorkoutCount() throws -> Int {
        let nativeSource = WorkoutSource.native.rawValue
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.endDate != nil && $0.rawSource == nativeSource }
        )
        return try fetchCount(descriptor)
    }
}
