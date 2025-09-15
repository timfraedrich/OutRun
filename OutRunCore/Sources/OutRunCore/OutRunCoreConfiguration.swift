/// The configuration to set up functionality for OutRunCore.
/// - warning: The ``recordableDataTypes`` field must contain `.location`, otherwise initialization of the core will cause a fatal error.
public struct OutRunCoreConfiguration {
    
    /// A name used for the SwiftData ModelContainer and subsequently the database file if writing to disk.
    public var containerName: String?
    /// Indicates whether the database should only be held in memory rather than being written to disk.
    /// - warning: Setting this option to `true` will result in all data being lost on app termination.
    public var isStoredInMemoryOnly: Bool
    /// The identifier of the app group in which the database and settings should be stored.
    public var appGroupIdentifier: String?
    
    /// Specifies the data to be collected during the recording of a workout.
    /// - warning: Must contain at least `.location`, otherwise initialization of the core will fail.
    public var recordableDataTypes: RecordableDataTypes
    
    public init(
        containerName: String? = nil,
        isStoredInMemoryOnly: Bool = false,
        appGroupIdentifier: String? = nil,
        recordableDataTypes: RecordableDataTypes
    ) {
        self.containerName = containerName
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
        self.appGroupIdentifier = appGroupIdentifier
        self.recordableDataTypes = recordableDataTypes
    }
}
