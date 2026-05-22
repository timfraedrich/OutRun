enum SettingsDestination: Hashable, Identifiable {
    
    case appleHealth
    case backup
    case cache
    case profile
    case recording
    case units
    
    var id: Int { hashValue }
}
