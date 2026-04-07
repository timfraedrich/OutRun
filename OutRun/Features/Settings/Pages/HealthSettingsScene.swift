import OutRunCore
import SwiftUI

struct HealthSettingsScene: View {
    
    @Environment(OutRunCore.self) private var core
    @State private var grantPermissionError: Error?
    
    var body: some View {
        if let healthSyncService = core.syncService(HealthSyncService.self) {
            Form {
                Button("Grant Permissions") { grantPermissions(for: healthSyncService) }
                    .errorPopover($grantPermissionError)
            }
            .navigationTitle("Apple Health")
        } else {
            Text("Apple Health is not available.")
        }
    }
    
    private func grantPermissions(for healthSyncService: HealthSyncService) {
        Task {
            do {
                try await healthSyncService.requestAuthorization()
                healthSyncService.outwardSyncMode = .enabled
            } catch {
                print("HealthSyncService authorization failed: \(error)")
            }
        }
    }
}
