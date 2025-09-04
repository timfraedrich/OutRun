import OutRunCore
import SwiftUI

@main
struct OutRunApp: App {
    
    var body: some Scene {
        OutRunCoreScene { status in
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
    }
}
