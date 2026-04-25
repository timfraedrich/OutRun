import Combine
import Foundation
import Perception
import SwiftData

actor Database: ModelActor {
    
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor
    
    init(modelContainer: ModelContainer) async throws {
        self.modelContainer = modelContainer
        let modelContext = ModelContext(modelContainer)
        modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    }
    
    // MARK: - Recording
    
    /// Initializes a workout for live recording.
    /// - returns: The identifier of the initialized workout.
    /// - throws: Throws if saving the workout fails.
    func initializeWorkout(with type: WorkoutType, startDate: Date) throws -> RawWorkout {
        let workout = Workout(
            type: type,
            distance: .zero,
            startDate: startDate,
            endDate: nil,
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: nil,
            comment: nil,
            creationDate: .now,
            source: .native
        )
        modelContext.insert(workout)
        try modelContext.save()
        return RawWorkout(workout: workout)
    }
    
    /// Continues a workout that has previously been finished.
    /// - returns: The current state of the workout to restore the recording process.
    /// - throws: Throws if the workout cannot be found, is not yet finished or saving changes fails.
    /// - note: A user initiated pause from the current endDate to the continueDate is added to the workout to indicate that the user
    /// interrupted the recording process. This can lead to a very long pause in the workout. For UX reasons the user should only be able to
    /// continue very recently finished workouts.
    func continueWorkout(with identifier: UUID, continueDate: Date) throws -> RawWorkout {
        let workout = try fetchWorkout(with: identifier)
        guard let endDate = workout.endDate else { throw DatabaseError.workoutNotFinished }
        workout.endDate = nil
        modelContext.insert(WorkoutPause(startDate: endDate, endDate: continueDate, userInitiated: true, workout: workout))
        workout.lastEditDate = .now
        try modelContext.save()
        return RawWorkout(workout: workout)
    }
    
    /// Adds a route sample to a workout currently being recorded.
    /// - throws: Throws if the workout cannot be found, is already finished or saving it fails.
    func addRouteSample(
        _ sample: RawWorkoutRouteDataSample,
        toWorkoutWith identifier: UUID,
        updatedDistance: Double,
        updatedEnergy: Double?,
        updatedRepetitions: Int?
    ) throws {
        let workout = try fetchWorkout(with: identifier)
        guard workout.endDate == nil else { throw DatabaseError.workoutAlreadyFinished }
        modelContext.insert(WorkoutRouteDataSample(from: sample, attachTo: workout))
        workout.distance = updatedDistance
        if let updatedEnergy = updatedEnergy { workout.energy = updatedEnergy }
        if let updatedRepetitions = updatedRepetitions { workout.repetitions = updatedRepetitions }
        workout.lastEditDate = .now
        try modelContext.save()
    }
    
    /// Adds a pause to a workout currently being recorded.
    /// - throws: Throws if the workout cannot be found, is already finished or saving it fails.
    func addPause(_ pause: RawWorkoutPause, toWorkoutWith identifier: UUID) throws {
        let workout = try fetchWorkout(with: identifier)
        guard workout.endDate == nil else { throw DatabaseError.workoutAlreadyFinished }
        modelContext.insert(WorkoutPause(from: pause, attachTo: workout))
        workout.lastEditDate = .now
        try modelContext.save()
    }
    
    /// Finalizes a workout currently being recorded and saves or discards it based on the recorded distance.
    /// - returns: A `RawWorkout` representing the final recorded workout if the recorded distance is larger than zero, `nil` otherwise.
    /// - throws: Throws if the workout cannot be found, is already finished or saving it fails.
    func finalizeWorkout(with identifier: UUID, endDate: Date) throws -> RawWorkout? {
        let workout = try fetchWorkout(with: identifier)
        guard workout.endDate == nil else { throw DatabaseError.workoutAlreadyFinished }
        if workout.distance > .zero {
            workout.endDate = endDate
            workout.lastEditDate = .now
            try modelContext.save()
            return RawWorkout(workout: workout)
        } else {
            modelContext.delete(workout)
            try modelContext.save()
            return nil
        }
    }
    
    /// Tries to fetch an unfinished workout to recover the recording process after termination.
    /// - returns: An unfinished `RawWorkout` representing the current state in the database with a pause inserted from the `lastEditDate`
    /// to the `recoveryDate` provided.
    /// - throws: Throws if the fetching process or saving the workout after inserting the pause fails. The method will **not** throw if
    /// there is no workout to recover.
    @discardableResult
    func recoverUnfinishedWorkout(recoveryDate: Date) throws -> RawWorkout? {
        let descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.endDate == nil })
        guard let workout = try modelContext.fetch(descriptor).first else { return nil }
        modelContext.insert(WorkoutPause(startDate: workout.lastEditDate, endDate: recoveryDate, userInitiated: false, workout: workout))
        try modelContext.save()
        return RawWorkout(workout: workout)
    }
    
    /// Changes the workout type and updates the energy value of a workout currently being recorded.
    /// - returns: The workout whose type was changed.
    /// - throws: Throws if the workout cannot be found, is already finished or saving it fails.
    @discardableResult
    func changeWorkoutType(
        ofWorkoutWith identifier: UUID,
        to type: WorkoutType,
        updatedEnergy: Double?
    ) throws -> RawWorkout {
        let workout = try fetchWorkout(with: identifier)
        guard workout.endDate == nil else { throw DatabaseError.workoutAlreadyFinished }
        workout.type = type
        workout.energy = updatedEnergy
        workout.lastEditDate = .now
        try modelContext.save()
        return RawWorkout(workout: workout)
    }
    
    /// Fetches the workout type of the last started workout in the database, `nil` if fetching fails or no workout exists in the database.
    func fetchLatestWorkoutType() -> WorkoutType? {
        let sortDescriptor = SortDescriptor<Workout>(\.startDate, order: .reverse)
        var fetchDescriptor = FetchDescriptor<Workout>(sortBy: [sortDescriptor])
        fetchDescriptor.fetchLimit = 1
        fetchDescriptor.propertiesToFetch = [\.rawType]
        return try? modelContext.fetch(fetchDescriptor).first?.type
    }
    
    // MARK: Workouts
    
    func insert(_ rawWorkout: RawWorkout) throws {
        try insert([rawWorkout])
    }
    
    func insert(_ rawWorkouts: [RawWorkout]) throws {
        for rawWorkout in rawWorkouts {
            let workout = Workout(from: rawWorkout)
            workout.route = rawWorkout.route.map { WorkoutRouteDataSample.init(from: $0) }
            workout.heartRates = rawWorkout.heartRates.map { WorkoutHeartRateDataSample(from: $0) }
            workout.pauses = rawWorkout.pauses.map { WorkoutPause(from: $0) }
            workout.events = rawWorkout.events.map { WorkoutEvent(from: $0) }
            workout.serviceMappings = rawWorkout.serviceMappings.map { SyncServiceMapping(from: $0) }
            modelContext.insert(workout)
        }
        try modelContext.save()
    }
    
    func queryWorkoutRoute(for identifier: UUID) async throws -> [RawWorkoutRouteDataSample] {
        let workout = try fetchWorkout(with: identifier)
        return workout.route.sorted(by: { $0.timestamp > $1.timestamp }).map(RawWorkoutRouteDataSample.init)
    }
    
    // MARK: - User
    
    func insert(_ rawUser: RawUser) throws {
        guard try modelContext.fetchCount(FetchDescriptor<User>()) == .zero else { throw DatabaseError.userAlreadyPresent }
        let user = User(from: rawUser)
        user.lastEditDate = .now
        modelContext.insert(user)
        try modelContext.save()
    }
    
    func userStream() throws -> (stream: AsyncThrowingStream<RawUser?, Error>, task: Task<Void, Never>) {
        let (stream, continuation) = AsyncThrowingStream<RawUser?, Error>.makeStream(bufferingPolicy: .unbounded)
        let task = Task {
            var descriptor = FetchDescriptor<User>()
            descriptor.fetchLimit = 1
            do {
                let user = try modelContext.fetch(descriptor).first.map(RawUser.init)
                continuation.yield(user)
                var lastUser: RawUser? = user
                for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) where !Task.isCancelled {
                    let user = try modelContext.fetch(descriptor).first.map(RawUser.init)
                    guard user != lastUser else { continue }
                    continuation.yield(user)
                    lastUser = user
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        return (stream, task)
    }
    
    private func fetchUser() throws -> User {
        var descriptor = FetchDescriptor<User>()
        descriptor.fetchLimit = 1
        guard let user = try modelContext.fetch(descriptor).first else { throw DatabaseError.objectNotFound }
        return user
    }

    func fetchOptionalUser() throws -> RawUser? {
        do {
            return try fetchUser()
        } catch DatabaseError.objectNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    func fetchUser() throws -> RawUser {
        let user: User = try fetchUser()
        return RawUser(from: user)
    }
    
    @discardableResult
    func updateUserPreferences(_ preferences: RawPreferences) throws -> RawUser {
        let user: User = try fetchUser()
        if user.preferences != preferences {
            user.preferences = preferences
            user.lastEditDate = .now
            try modelContext.save()
        }
        return RawUser(from: user)
    }
    
    @discardableResult
    func updateUserProperties(
        id: UUID?? = .none,
        name: String? = .none,
        birthday: Day?? = .none,
        weight: Double?? = .none,
        sex: Sex?? = .none
    ) throws -> RawUser {
        let user: User = try fetchUser()
        if let id { user.id = id }
        if let name { user.name = name }
        if let birthday { user.birthday = birthday }
        if let weight { user.weight = weight }
        if let sex { user.sex = sex }
        user.lastEditDate = .now
        try modelContext.save()
        return RawUser(from: user)
    }
    
    func deleteUser() throws {
        let user: User = try fetchUser()
        modelContext.delete(user)
        try modelContext.save()
    }
    
    // MARK: - Syncing
    
    /// Fetches the change history in the date range in ascending order.
    func fetchHistory(in dateRange: Range<Date>) throws -> [some HistoryTransaction] {
        let predicate = #Predicate<DefaultHistoryTransaction> { $0.timestamp >= dateRange.lowerBound && $0.timestamp < dateRange.upperBound }
        var descriptor = HistoryDescriptor<DefaultHistoryTransaction>(predicate: predicate)
        let sortDescriptor: SortDescriptor<DefaultHistoryTransaction> = .init(\.timestamp, order: .forward)
        if #available(iOS 26, *) {
            descriptor.sortBy = [sortDescriptor]
        }
        var history = try modelContext.fetchHistory(descriptor)
        if #unavailable(iOS 26) {
            history.sort(using: sortDescriptor)
        }
        return history
    }
    
    func fetchWorkout(for identifier: PersistentIdentifier) throws -> RawWorkout {
        var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.persistentModelID == identifier })
        descriptor.fetchLimit = 1
        guard let workout = try modelContext.fetch(descriptor).first else { throw DatabaseError.objectNotFound }
        return RawWorkout(workout: workout)
    }
    
    func fetchSyncServiceState(for identifier: String) throws -> RawSyncServiceState {
        let state = try fetchSyncServiceState(with: identifier)
        return RawSyncServiceState(from: state)
    }
    
    func upsertSyncServiceState(_ rawState: RawSyncServiceState) throws {
        do {
            let state = try fetchSyncServiceState(with: rawState.id)
            state.lastSyncDate = rawState.lastSyncDate
            state.lastSyncMode = rawState.lastSyncMode
            state.preferences = rawState.preferences
        } catch DatabaseError.objectNotFound {
            modelContext.insert(SyncServiceState(from: rawState))
        }
        try modelContext.save()
    }

    func upsertSyncServiceMapping(_ mapping: RawSyncServiceMapping, forWorkoutWith workoutId: UUID) throws {
        let workout = try fetchWorkout(with: workoutId)
        if let existing = workout.serviceMappings.first(where: { $0.serviceIdentifier == mapping.serviceIdentifier }) {
            existing.externalId = mapping.externalId
            existing.externalUrl = mapping.externalUrl
            existing.lastEditDateSynced = mapping.lastEditDateSynced
            existing.syncStatus = mapping.syncStatus
        } else {
            workout.serviceMappings.append(SyncServiceMapping(from: mapping))
        }
        try modelContext.save()
    }

    func fetchFinishedWorkouts(startingFrom date: Date) throws -> [RawWorkout] {
        let descriptor = FetchDescriptor<Workout>(predicate: #Predicate {
            $0.endDate != nil && $0.startDate >= date
        })
        return try modelContext.fetch(descriptor).map(RawWorkout.init)
    }
    
    /// Fetches workouts that need retry for a specific sync service (failed or pending status)
    /// This is memory-efficient as it only loads the necessary properties before mapping
    func fetchRetriableWorkouts(for serviceIdentifier: String) throws -> [RawWorkout] {
        // let sourceCasesToSync
        let syncCases = WorkoutSyncStatus.casesWhereSyncShouldBeAttempted.map(\.rawValue)
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                // Must be finished and have a failed/pending mapping for this service
                workout.endDate != nil &&
                workout.serviceMappings.contains { mapping in
                    mapping.serviceIdentifier == serviceIdentifier &&
                    syncCases.contains(mapping.rawSyncStatus)
                }
            }
        )
        return try modelContext.fetch(descriptor).map(RawWorkout.init)
    }
    
    func deleteSyncServiceState(for identifier: String) throws {
        let state = try fetchSyncServiceState(with: identifier)
        modelContext.delete(state)
        try modelContext.save()
    }
    
    // MARK: Sync Delegate Implementation
    
    @discardableResult
    func upsert(_ workout: RawWorkout) async throws -> UUID {
        do {
            let serviceInformation: (externalIdentifier: String, serviceIdentifier: String)?
            if case .syncService(let serviceIdentifier) = workout.source,
               let serviceMapping = workout.serviceMappings.first(where: { $0.serviceIdentifier == serviceIdentifier }),
               let externalIdentifier = serviceMapping.externalId ?? serviceMapping.externalUrl {
                serviceInformation = (externalIdentifier, serviceIdentifier)
            } else {
                serviceInformation = nil
            }
            let databaseWorkout = try fetchWorkout(with: workout.id, or: serviceInformation)
            if databaseWorkout.lastEditDate > workout.lastEditDate {
                throw SyncError.conflict
            }
            databaseWorkout.type = workout.type
            databaseWorkout.distance = workout.distance
            databaseWorkout.startDate = workout.startDate
            databaseWorkout.endDate = workout.endDate
            databaseWorkout.energy = workout.energy
            databaseWorkout.repetitions = workout.repetitions
            databaseWorkout.isRace = workout.isRace
            databaseWorkout.name = workout.name
            databaseWorkout.comment = workout.comment
            databaseWorkout.creationDate = workout.creationDate
            databaseWorkout.lastEditDate = workout.lastEditDate
            databaseWorkout.source = workout.source
            databaseWorkout.route = workout.route.map { WorkoutRouteDataSample.init(from: $0) }
            databaseWorkout.heartRates = workout.heartRates.map { WorkoutHeartRateDataSample(from: $0) }
            databaseWorkout.pauses = workout.pauses.map { WorkoutPause(from: $0) }
            databaseWorkout.events = workout.events.map { WorkoutEvent(from: $0) }
            databaseWorkout.serviceMappings = workout.serviceMappings.map { SyncServiceMapping(from: $0) }
            try modelContext.save()
        } catch DatabaseError.objectNotFound {
            try insert([workout])
        }
        return workout.id
    }
    
    func delete(workoutWithIdentifier identifier: UUID) throws {
        let databaseWorkout = try fetchWorkout(with: identifier)
        modelContext.delete(databaseWorkout)
        try modelContext.save()
    }
    
    private func delete(workoutWithSyncServiceMatching predicate: Predicate<SyncServiceMapping>, and serviceIdentifier: String) throws {
        let fullPredicate = #Predicate<SyncServiceMapping> {
            predicate.evaluate($0) && $0.serviceIdentifier == serviceIdentifier && $0.workout != nil
        }
        var descriptor = FetchDescriptor<SyncServiceMapping>(predicate: fullPredicate)
        descriptor.fetchLimit = 1
        guard let workout = try modelContext.fetch(descriptor).first?.workout else { throw DatabaseError.objectNotFound }
        modelContext.delete(workout)
        try modelContext.save()
    }
    
    func delete(workoutWithExternalIdentifier externalIdentifier: String, forServiceWith serviceIdentifier: String) throws {
        try delete(workoutWithSyncServiceMatching: #Predicate { $0.externalId == externalIdentifier }, and: serviceIdentifier)
    }
    
    func delete(workoutWithExternalURL externalURL: String, forServiceWith serviceIdentifier: String) throws {
        try delete(workoutWithSyncServiceMatching: #Predicate { $0.externalUrl == externalURL }, and: serviceIdentifier)
    }
    
    // MARK: - Private
    
    private func fetchSyncServiceState(with identifier: String) throws -> SyncServiceState {
        var descriptor = FetchDescriptor<SyncServiceState>(predicate: #Predicate { $0.id == identifier })
        descriptor.fetchLimit = 1
        guard let state = try modelContext.fetch(descriptor).first else { throw DatabaseError.objectNotFound }
        return state
    }
    
    private func fetchWorkout(
        with identifier: UUID,
        or serviceInformation: (externalIdentifier: String, serviceIdentifier: String)? = nil
    ) throws -> Workout {
        do {
            var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == identifier })
            descriptor.fetchLimit = 1
            guard let workout = try modelContext.fetch(descriptor).first else { throw DatabaseError.objectNotFound }
            return workout
        } catch DatabaseError.objectNotFound {
            guard let (externalIdentifier, serviceIdentifier) = serviceInformation else { throw DatabaseError.objectNotFound }
            var descriptor = FetchDescriptor<SyncServiceMapping>(predicate: #Predicate {
                $0.serviceIdentifier == serviceIdentifier
                && $0.workout != nil
                && $0.externalId == externalIdentifier || $0.externalUrl == externalIdentifier
            })
            descriptor.fetchLimit = 1
            guard let workout = try modelContext.fetch(descriptor).first?.workout else { throw DatabaseError.objectNotFound }
            return workout
        } catch {
            throw error
        }
    }
    
    // MARK: - Internal
    
    func fetchWorkoutCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<Workout>())
    }
    
    func fetchWorkouts(limit: Int = .max, offset: Int = .zero) throws -> [RawWorkout] {
        var descriptor = FetchDescriptor<Workout>()
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor).map(RawWorkout.init)
    }
    
    func deleteAllData() throws {
        for model in ModelSchema.models {
            try modelContext.delete(model: model)
        }
        try modelContext.save()
    }
    
    // MARK: - Testing
    
    init(
        isStoredInMemoryOnly: Bool = false,
        groupContainer: ModelConfiguration.GroupContainer = .automatic
    ) async throws {
        try await self.init(
            modelContainer: try Self.modelContainer(name: nil, isStoredInMemoryOnly: isStoredInMemoryOnly, groupContainer: groupContainer)
        )
    }
    
    // MARK: - Static
    
    static func modelContainer(
        name: String?,
        isStoredInMemoryOnly: Bool = false,
        groupContainer: ModelConfiguration.GroupContainer = .automatic
    ) throws -> ModelContainer {
        // If migrations get added, prevent extensions to automatically migrate to avoid crashes.
        // See https://developer.apple.com/forums/thread/773637?answerId=824240022#824240022 to handle this properly.
        let schema = Schema(versionedSchema: ModelSchema.self)
        let config = ModelConfiguration(
            name,
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: groupContainer,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, migrationPlan: nil, configurations: config)
    }
}
