import Combine
import SwiftData
import OSLog

@MainActor
public class OutRunCore: ObservableObject {
    
    static nonisolated let moduleIdentifier = "software.tfr.running-core"
    
    @Published public var status: Status = .initializing
    
    private(set) var database: Database?
    private(set) var altitudeService: AltitudeService?
    private(set) var stepService: StepService?
    private(set) var locationService: LocationService?
    private(set) var workoutRecorder: WorkoutRecorder?
    
    private let logger = Logger(category: "OutRunCore")
    let modelContainer: ModelContainer
    
    // TODO: check if workout source is apple health and reimport
    public init(isStoredInMemoryOnly: Bool = false) {
        do {
            modelContainer = try Database.modelContainer(isStoredInMemoryOnly: isStoredInMemoryOnly)
        } catch {
            // the reason we allow the app to crash in this instance is that creating the ModelContainer instance should only fail under
            // extreme circumstances (e.g. way too little disk space or concurrent migrations). For now there are no migrations and such
            // little disk space to cause an issue will lead to much graver problems than an apps database not initializing correctly.
            logger.critical("Failed to initialize ModelContainer: \(error)")
            fatalError("Failed to initialize ModelContainer")
        }
        Task { @MainActor in
            do {
                let database = try await Task.detached { [modelContainer] in
                    return try await Database(modelContainer: modelContainer)
                }.value
                let locationService = LocationService()
                let altitudeService = AltitudeService()
                let stepService = StepService()
                let workoutRecorder = WorkoutRecorder(
                    database: database,
                    locationService: locationService,
                    altitudeService: altitudeService,
                    stepService: stepService
                )
                self.database = database
                self.locationService = locationService
                self.altitudeService = altitudeService
                self.stepService = stepService
                self.workoutRecorder = workoutRecorder
                self.status = .initialized
            } catch {
                self.status = .failed(error)
            }
        }
    }
    
    public func insert(_ workouts: [RawWorkout]) async throws {
        guard status == .initialized, let database else { throw OutRunCoreError.notInitialized }
        try await database.insert(workouts)
    }
    
    public enum OutRunCoreError: Error {
        case notInitialized
    }
    
    public enum Status: Equatable, Sendable {
        
        case initializing
        case initialized
        case failed(Error)
        
        public static func == (lhs: OutRunCore.Status, rhs: OutRunCore.Status) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing), (.initialized, .initialized), (.failed, .failed): true
            default: false
            }
        }
    }
}
