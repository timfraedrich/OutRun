import Combine
import SwiftData
import OSLog

@Observable
@MainActor
public class OutRunCore {
    
    static nonisolated let moduleIdentifier = "software.tfr.running-core"
    
    public var status: Status = .initializing
    
    @ObservationIgnored private var database: Database?
    @ObservationIgnored public var recorder: WorkoutRecorder?
    
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
        Task {
            do {
                let database = try await Database(modelContainer: modelContainer)
                self.recorder = await WorkoutRecorder(
                    database: database,
                    locationService: .init(),
                    altitudeService: .init(),
                    stepService: .init()
                )
                self.database = database
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
