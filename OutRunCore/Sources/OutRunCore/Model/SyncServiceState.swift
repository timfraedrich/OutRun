import Foundation
import SwiftData

@Model
class SyncServiceState {
    
    @Attribute(.unique) var id: String
    var lastSyncDate: Date?
    var lastSyncMode: SyncMode
    var preferences: RawPreferences
    
    init(id: String, lastSyncDate: Date? = nil, lastSyncMode: SyncMode = .disabled, preferences: RawPreferences = .init()) {
        self.id = id
        self.lastSyncDate = lastSyncDate
        self.lastSyncMode = lastSyncMode
        self.preferences = preferences
    }
    
    convenience init(from rawState: RawSyncServiceState) {
        self.init(
            id: rawState.id,
            lastSyncDate: rawState.lastSyncDate,
            lastSyncMode: rawState.lastSyncMode,
            preferences: rawState.preferences
        )
    }
}
