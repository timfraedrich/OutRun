import SwiftData
import OSLog
import Perception

@Observable
@MainActor
public class OutRunCore {
    
    public static nonisolated let moduleIdentifier = "software.tfr.outruncore"
    
    public typealias Status = OutRunCoreStatus
    
    private let logger = Logger(category: "OutRunCore")
    @ObservationIgnored private(set) var database: Database?
    @ObservationIgnored private(set) var syncManager: SyncManager?
    
    public let config: OutRunCoreConfiguration
    public let syncServices: [any SyncService]
    public let userDefaults: UserDefaults
    public let modelContainer: ModelContainer
    @ObservationIgnored public private(set) var recorder: WorkoutRecorder?
    @ObservationIgnored public private(set) var userPreferences: UserPreferences?
    public private(set) var status: Status = .initializing
    public private(set) var user: RawUser?
    
    public init(config: OutRunCoreConfiguration, syncServices: [any SyncService] = []) {
        guard config.recordableDataTypes.contains(.location) else {
            fatalError("Invalid OutRunCore configuration. Must include .location as a recordable data type.")
        }
        // Due to a Swift 6 or iOS bug receiving a CMPedometer update results in an assertion failure. For the time being step data
        // collection will not be supported. For further details see: https://forums.swift.org/t/cmpedometer-breaks-with-swift-6/82091
        guard !config.recordableDataTypes.contains(.steps) else {
            fatalError("Invalid OutRunCore configuration. Currently, the ability to record steps is not supported.")
        }
        self.config = config
        self.syncServices = syncServices
        self.userDefaults = if let name = config.appGroupIdentifier, let defaults = UserDefaults(suiteName: name) {
            defaults
        } else {
            .standard
        }
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
            fatalError("Failed to initialize ModelContainer: \(error).")
        }
        Task(operation: asyncInit)
    }
    
    // MARK: Public API
    
    /// This method can be used to set up the core with a user.
    ///
    /// To create a ``RawUser`` for this setup method just initialize it with the needed properties using the available initializer. To
    /// populate the ``RawUser/preferences`` field it is recommended to use the ``UserPreferences`` class. The whole process may look as
    /// follows:
    ///
    /// ```swift
    /// let userPreferences = UserPreferences(preferences: [:])
    ///
    /// userPreferences.distanceUnit = .kilometers
    /// userPreferences.myCustomPreferences = "Hello World!"
    ///
    /// let user = RawUser(
    ///     id: nil,
    ///     name: "John",
    ///     weight: 76.8,
    ///     sex: .male,
    ///     preferences: userPreferences.preferences,
    ///     creationDate: .now
    /// )
    ///
    /// try await core.setup(for: user)
    /// ```
    ///
    /// - throws: Throws if the core does not have status `.needsSetup` or inserting the user into the database fails.
    /// - note: This method waits for the core to transition into the `.initialized` state before returning.
    public func setup(for user: RawUser) async throws {
        guard case .needsSetup = status, let database else { throw OutRunCoreError.setupNotRequired }
        try validateUserProperties(name: user.name)
        try await database.insert(user)
        if case .initialized = status { return }
        await wait(for: .initialized)
    }
    
    /// Inserts the provided workouts into the database. This function may for example be used for a migration of an existing database.
    /// - throws: Throws if the core is not yet initialized or inserting the workouts fails.
    /// - warning: Inserting a large amount of workouts at the same time might result in a long wait time or a crash, it is advised to
    /// insert in batches of appropriate size.
    public nonisolated func insert(_ workouts: [RawWorkout]) async throws {
        guard case .initialized = await status, let database = await database else { throw OutRunCoreError.notInitialized }
        try await database.insert(workouts)
    }
    
    /// Upserts the prodived workout into the database.
    /// - throws: Throws if the core is not yet initialized or inserting the workout fails.
    /// - note: If a workout with the provided workout identifier already exists it is only updated in the database if the existing
    /// workout's lastEditDate is earlier than the provided workout's. In this case the OutRunCoreError.newerWorkoutVersionExists will be
    /// thrown.
    @discardableResult
    public func upsert(_ workout: RawWorkout) async throws -> UUID {
        guard case .initialized = status, let database else { throw OutRunCoreError.notInitialized }
        do {
            return try await database.upsert(workout)
        } catch SyncError.conflict {
            throw OutRunCoreError.newerWorkoutVersionExists
        }
    }
    
    /// Deletes the workout with the provided identifier, if present.
    /// - throws: Throws if the core is not yet initialized or deleting the workout fails.
    public func delete(workoutWithIdentifier identifier: UUID) async throws {
        guard case .initialized = status, let database else { throw OutRunCoreError.notInitialized }
        try await database.delete(workoutWithIdentifier: identifier)
    }
    
    /// Fetches the number of workouts currently saved in the database.
    public func fetchWorkoutCount() async throws -> Int {
        guard case .initialized = status, let database else { throw OutRunCoreError.notInitialized }
        return try await database.fetchWorkoutCount()
    }
    
    /// Fetches workouts within the provided limit and and with the provided offset from the database.
    public func fetchWorkouts(limit: Int = .max, offset: Int = .zero) async throws -> [RawWorkout] {
        guard case .initialized = status, let database else { throw OutRunCoreError.notInitialized }
        return try await database.fetchWorkouts(limit: limit, offset: offset)
    }
    
    /// Updates properties of the currently set up user.
    /// - throws: Throws if the core is not yet initialized, the provided properties are invalid or updating the user fails.
    /// - note: For restrictions on properties see ``UserProtocol``.
    public func updateUserProperties(
        id: UUID?? = .none,
        name: String? = .none,
        birthday: Day?? = .none,
        weight: Double?? = .none,
        sex: Sex?? = .none
    ) async throws {
        guard case .initialized = status, let database else { throw OutRunCoreError.notInitialized }
        try validateUserProperties(name: name)
        try await database.updateUserProperties(id: id, name: name, birthday: birthday, weight: weight, sex: sex)
    }
    
    /// Resets the core by deleting the user and all workouts from the database.
    /// - throws: Throws if the core is not yet initialized or deleting the data from the database fails.
    /// - note: This method waits for the core to transition into the `.needsSetup` state before returning.
    public func reset() async throws {
        guard case .initialized = status, let database else { throw OutRunCoreError.notInitialized }
        status = .initializing
        do {
            try await database.deleteAllData()
            await deinitialize()
        } catch {
            status = .initialized
            throw error
        }
    }
    
    public func syncService<Service: SyncService>(_ type: Service.Type) -> Service? {
        syncServices.first(where: { $0 is Service }) as? Service
    }
    
    // MARK: Internal Workings
    
    private func asyncInit() async {
        do {
            let database = try await Database(modelContainer: modelContainer)
            self.database = database
            try startStreamingUserUpdates()
            try startStreamingUserPreferenceUpdates()
            syncManager = await .init(
                database: database,
                syncDelegate: DefaultSyncDelegate(database: database, userDefaults: userDefaults),
                syncServices: syncServices
            )
            if let user = try await database.fetchOptionalUser() {
                try await initialize(with: user)
                logger.info("Finished initialization.")
            } else {
                status = .needsSetup
                logger.info("Finished initialization, no user found.")
            }
        } catch {
            status = .failed(error)
            logger.critical("Failed initialization: \((error as CustomDebugStringConvertible).debugDescription).")
        }
    }
    
    private nonisolated func validateUserProperties(name: String?) throws {
        if let name, name.isEmpty {
            throw OutRunCoreError.invalidNameProvided
        }
    }
    
    private func initialize(with user: RawUser) async throws {
        guard let database else { throw OutRunCoreError.notInitialized }
        userPreferences = UserPreferences(preferences: user.preferences)
        recorder = try await WorkoutRecorder(
            database: database,
            locationService: .init(),
            altitudeService: config.recordableDataTypes.contains(.preciseAltitude) ? .init() : nil,
            stepService: config.recordableDataTypes.contains(.steps) ? .init() : nil
        )
        await syncManager?.initialize()
        status = .initialized
    }
    
    private func deinitialize() async {
        status = .needsSetup
        userPreferences = nil
        recorder = nil
        await syncManager?.deinitialize()
    }
    
    func wait(for status: OutRunCoreStatus) async {
        let statusSequence = Perceptions { [weak self] in self?.status }.buffer(policy: .unbounded)
        for await newStatus in statusSequence where newStatus == status {
            return
        }
    }
    
    private func startStreamingUserUpdates() throws {
        guard let database else { throw OutRunCoreError.notInitialized }
        Task {
            var task: Task<Void, Never>?
            do {
                let tuple = try await database.userStream()
                task = tuple.task
                let userStream = tuple.stream
                for try await user in userStream where !Task.isCancelled {
                    if case .failed = status { break }
                    if let user {
                        self.user = user
                        userPreferences?.update(basedOn: user.preferences)
                        guard case .needsSetup = status else { continue }
                        try await initialize(with: user)
                    } else {
                        guard case .initialized = status else { continue }
                        await deinitialize()
                    }
                }
            } catch {
                status = .failed(error)
                logger.critical("Failed streaming user updates: \((error as CustomDebugStringConvertible).debugDescription).")
            }
            task?.cancel()
        }
    }
    
    private func startStreamingUserPreferenceUpdates() throws {
        guard let database else { throw OutRunCoreError.notInitialized }
        let preferencesSequence = Perceptions { [weak self] in self?.userPreferences?.preferences }.buffer(policy: .bufferingLatest(1))
        Task {
            for await preferences in preferencesSequence where !Task.isCancelled {
                guard let preferences else { continue }
                do {
                    try await database.updateUserPreferences(preferences)
                } catch {
                    logger.critical("Failed to update user preferences: \((error as CustomDebugStringConvertible).debugDescription).")
                }
            }
        }
    }
}
