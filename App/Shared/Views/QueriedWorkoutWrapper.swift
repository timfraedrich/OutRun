import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutWrapper<Content: View>: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(OutRunCore.self) private var core
    @State private var result: Result<RawWorkout, Error>?
    
    private let id: Workout.ID
    private let content: (any WorkoutProtocol) -> Content
    
    init(id: Workout.ID, @ViewBuilder content: @escaping (any WorkoutProtocol) -> Content) {
        self.id = id
        self.content = content
    }
    
    var body: some View {
        ZStack {
            switch result {
            case .success(let workout):
                content(workout)
            case .failure(let error):
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            case .none:
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            }
        }
        .transition(.blurReplace)
        .animation(.default, value: result != nil)
        .task(loadWorkout)
    }
    
    @Sendable
    private func loadWorkout() async {
        do {
            let workoutId = id
            var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == workoutId })
            descriptor.relationshipKeyPathsForPrefetching = [\.route, \.heartRates, \.pauses, \.serviceMappings]
            descriptor.fetchLimit = 1
            let container = modelContext.container
            result = try await Task {
                let context = ModelContext(container)
                guard let workout = try context.fetch(descriptor).first else { return .failure(WorkoutNotFoundError()) }
                return .success(RawWorkout(workout: workout))
            }.value
        } catch {
            result = .failure(error)
        }
    }
    
    struct WorkoutNotFoundError: LocalizedError {
        var errorDescription: String? {
            .init(localized: "error_workout_not_found")
        }
    }
}
