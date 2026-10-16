import SwiftUI
import TFRouting

enum SettingsPageRoute: RouteProtocol {
    
    case appleHealth
    case backup
    case cache
    case profile
    case recording
    case tipJar
    case units
    
    func content(in context: RouteContext) -> some View {
        switch self {
        case .appleHealth: HealthSettingsScene()
        case .backup: BackupSettingsScene()
        case .cache: CacheSettingsScene()
        case .profile: ProfileScene()
        case .recording: RecordingSettingsScene()
        case .tipJar: TipJarSettingsScene()
        case .units: UnitSettingsScene()
        }
    }
}
