import OutRunCore
import SwiftUI

@main
struct OutRunApp: App {
    
    private let config: OutRunCoreConfiguration = .init(
        containerName: "OutRun",
        isStoredInMemoryOnly: false,
        appGroupIdentifier: nil,
        recordableDataTypes: .all
    )
    
    var body: some Scene {
        OutRunCoreScene(config: config) { status in
            Group {
                switch status {
                case .initializing:
                    ProgressView().progressViewStyle(.circular)
                case .initialized:
                    ZStack {
                        Text("App")
                        LegacyMigrationView()
                    }
                case .failed(let error):
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .backgroundStyle(.primaryBackground)
            .foregroundStyle(.primaryLabel, .secondaryLabel, .tertiaryLabel)
        }
    }
}
