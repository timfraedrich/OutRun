import OutRunCore
import SwiftUI

@main
struct OutRunApp: App {
    
    @State private var core: OutRunCore
    @State private var backupService: BackupService
    @State private var mainRouter: MainRouter
    @State private var settingsRouter: SettingsRouter
    @State private var showLegacyMigrationView: Bool
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showLegacyMigrationView {
                    LegacyMigrationView {
                        showLegacyMigrationView = false
                    }
                } else {
                    ZStack {
                        Rectangle().fill(.background).ignoresSafeArea()
                        switch core.status {
                        case .initializing:
                            ProgressView().progressViewStyle(.circular)
                        case .needsSetup:
                            SetupScene()
                        case .initialized:
                            MainScene()
                        case .failed(let error):
                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .environment(core)
            .environment(core.recorder)
            .environment(core.userPreferences)
            .environment(mainRouter)
            .environment(settingsRouter)
            .environment(backupService)
            .foregroundStyle(.primaryLabel, .secondaryLabel, .tertiaryLabel)
            .backgroundStyle(.primaryBackground)
            .workoutCardStyle(.list)
        }
        .modelContainer(core.modelContainer)
    }
    
    init() {
        let config: OutRunCoreConfiguration = .init(
            containerName: "ORCA",
            isStoredInMemoryOnly: false,
            appGroupIdentifier: nil,
            recordableDataTypes: [.location, .preciseAltitude]
        )
        let core = OutRunCore(config: config, syncServices: [HealthSyncService()])
        self.core = core
        backupService = .init(core: core)
        mainRouter = .init()
        settingsRouter = .init()
        showLegacyMigrationView = LegacyMigrationHelper.isLegacyMigrationAppropriate
    }
}
