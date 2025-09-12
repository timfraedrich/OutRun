import SwiftData
import OSLog

@Observable
@MainActor
public class OutRunCore {
    
    static nonisolated let moduleIdentifier = "software.tfr.running-core"
    
    public typealias Status = OutRunCoreStatus
    
    @ObservationIgnored private var database: Database?
    @ObservationIgnored public var recorder: WorkoutRecorder?
    private let logger = Logger(category: "OutRunCore")
    let modelContainer: ModelContainer
    
    public var status: Status = .initializing
    
    // TODO: check if workout source is apple health and reimport
    public init(config: OutRunCoreConfiguration) {
        guard config.recordableDataTypes.contains(.location) else {
            fatalError("Invalid OutRunCore configuration. Must include .location as a recordable data type.")
        }
        do {
            let groupContainer: ModelConfiguration.GroupContainer = if let appGroupIdentifier = config.appGroupIdentifier {
                .identifier(appGroupIdentifier)
            } else {
                .none
            }
            modelContainer = try Database.modelContainer(
                name: config.containerName,
                isStoredInMemoryOnly: config.isStoredInMemoryOnly,
                groupContainer: groupContainer
            )
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
                    altitudeService: config.recordableDataTypes.contains(.preciseAltitude) ? .init() : nil,
                    stepService: config.recordableDataTypes.contains(.steps) ? .init() : nil
                )
                self.database = database
                self.status = .initialized
                logger.info("Finished initialization.")
            } catch {
                self.status = .failed(error)
                logger.critical("Failed initialization: \((error as CustomDebugStringConvertible).debugDescription).")
            }
        }
    }
    
    public func insert(_ workouts: [RawWorkout]) async throws {
        guard status == .initialized, let database else { throw OutRunCoreError.notInitialized }
        try await database.insert(workouts)
    }
}
