import OutRunCore
import SwiftData
import SwiftUI
import TFRouting

@main
struct OutRun: App {
    
    @State private var core: OutRunCore
    @State private var backupService: BackupService
    @State private var mainRouter: Router
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
                                .environment(mainRouter)
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
            .environment(backupService)
            .workoutCardStyle(.list)
        }
        .modelContainer(core.modelContainer)
    }
    
    init() {
        let config: OutRunCoreConfiguration = .init(
            containerName: "OutRun",
            isStoredInMemoryOnly: false,
            appGroupIdentifier: nil,
            recordableDataTypes: [.location, .preciseAltitude]
        )
        let core = OutRunCore(config: config, syncServices: [HealthSyncService()])
        self.core = core
        backupService = .init(core: core)
        mainRouter = .init(scope: MainRoutingScope())
        showLegacyMigrationView = LegacyMigrationHelper.isLegacyMigrationAppropriate
    }
}
