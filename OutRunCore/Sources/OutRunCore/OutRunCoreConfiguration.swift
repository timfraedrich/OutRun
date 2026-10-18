//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
        recordableDataTypes: RecordableDataTypes = [.location]
    ) {
        self.containerName = containerName
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
        self.appGroupIdentifier = appGroupIdentifier
        self.recordableDataTypes = recordableDataTypes
    }
}
