import Foundation

struct RawSyncServiceState {
    
    var id: String
    var lastSyncDate: Date?
    var lastSyncMode: SyncMode
    var preferences: RawPreferences
    
    init(id: String, lastSyncDate: Date? = nil, lastSyncMode: SyncMode = .disabled, preferences: RawPreferences = .init()) {
        self.id = id
        self.lastSyncDate = lastSyncDate
        self.lastSyncMode = lastSyncMode
        self.preferences = preferences
    }
    
    init(from state: SyncServiceState) {
        self.init(id: state.id, lastSyncDate: state.lastSyncDate, lastSyncMode: state.lastSyncMode, preferences: state.preferences)
    }
}
