import SwiftData
import OSLog
import Perception

@Observable
@MainActor
public class OutRunCore {
    
    static nonisolated let moduleIdentifier = "software.tfr.running-core"
    
    public typealias Status = OutRunCoreStatus
    
    @ObservationIgnored var database: Database?
    @ObservationIgnored public var recorder: WorkoutRecorder?
    private let logger = Logger(category: "OutRunCore")
    let modelContainer: ModelContainer
    let config: OutRunCoreConfiguration
    
    public private(set) var user: RawUser?
    public private(set) var status: Status = .initializing
    
    // TODO: check if workout source is apple health and reimport
    public init(config: OutRunCoreConfiguration) {
        guard config.recordableDataTypes.contains(.location) else {
            fatalError("Invalid OutRunCore configuration. Must include .location as a recordable data type.")
        }
        // Due to a Swift 6 or iOS bug receiving a CMPedometer update results in an assertion failure. For the time being step data
        // collection will not be supported. For further details see: https://forums.swift.org/t/cmpedometer-breaks-with-swift-6/82091
        guard !config.recordableDataTypes.contains(.steps) else {
            fatalError("Invalid OutRunCore configuration. Currently, the ability to record steps is not supported.")
        }
        self.config = config
        let groupContainer: ModelConfiguration.GroupContainer = if let id = config.appGroupIdentifier { .identifier(id) } else { .none }
        do {
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
                self.database = database
                try self.startStreamingUserUpdates()
                if let user = try await database.fetchUser() {
                    self.user = user
                    try await self.prepareRecorder(database: database)
                    logger.info("Finished initialization.")
                } else {
                    self.status = .userMissing
                    logger.info("Finished initialization, no user found.")
                }
            } catch {
                self.status = .failed(error)
                logger.critical("Failed initialization: \((error as CustomDebugStringConvertible).debugDescription).")
            }
        }
    }
    
    private func prepareRecorder(database: Database) async throws {
        guard let user else { throw OutRunCoreError.notInitialized }
        self.recorder = await WorkoutRecorder(
            user: user,
            database: database,
            locationService: .init(),
            altitudeService: config.recordableDataTypes.contains(.preciseAltitude) ? .init() : nil,
            stepService: config.recordableDataTypes.contains(.steps) ? .init() : nil
        )
        self.status = .initialized
    }
    
    // TODO: rename migrate and add user with migration
    public func insert(_ workouts: [RawWorkout]) async throws {
        guard status == .initialized, let database else { throw OutRunCoreError.notInitialized }
        try await database.insert(workouts)
    }
    
    public func createUser(identifier: UUID?, name: String, weight: Double?, sex: Sex?) async throws {
        guard case .userMissing = status, let database else { throw OutRunCoreError.userNotMissing }
        let user = RawUser(id: identifier, name: name, weight: weight, sex: sex, creationDate: .now)
        try await database.insert(user)
        try await prepareRecorder(database: database)
    }
    
    private func startStreamingUserUpdates() throws {
        guard let database else { throw OutRunCoreError.notInitialized }
        Task {
            let (userStream, task) = try await database.userStream()
            do {
                for try await user in userStream where !Task.isCancelled {
                    if case .failed = status { break }
                    
                    status = user == nil ? .userMissing : .initialized
                }
            } catch {
                status = .failed(error)
            }
            task.cancel()
        }
    }
}
