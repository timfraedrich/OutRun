import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutEditScene: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var workout: Workout?
    let id: Workout.ID
    let addCloseButton: Bool
    
    var body: some View {
        ZStack {
            if let workout {
                WorkoutEditScene(workout: workout, addCloseButton: addCloseButton)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            }
        }
        .task {
            var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            workout = try? modelContext.fetch(descriptor).first
        }
    }
    
    init(id: Workout.ID, addCloseButton: Bool = true) {
        self.id = id
        self.addCloseButton = addCloseButton
    }
}
