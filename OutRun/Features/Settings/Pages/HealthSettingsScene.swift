import OutRunCore
import SwiftUI

struct HealthSettingsScene: View {
    
    @Environment(OutRunCore.self) private var core
    @State private var grantPermissionError: Error?
    @State private var outwardSyncDate: Date?
    @State private var inwardSyncDate: Date?
    
    var body: some View {
        if let healthSyncService = core.syncService(HealthSyncService.self) {
            List {
                Section {
                    Button("Grant Permissions") { grantPermissions(for: healthSyncService) }
                        .errorPopover($grantPermissionError)
                }
                Section {
                    LabeledContent("Inward Mode", value: String(describing: healthSyncService.inwardSyncMode))
                    OptionalDatePicker(selection: $inwardSyncDate)
                    Button("Set Mode") {
                        let mode: SyncMode = if let date = inwardSyncDate {
                            .enabledFrom(date: date)
                        } else {
                            .enabled
                        }
                        healthSyncService.setInwardSyncMode(mode)
                    }
                    Button("Reset") { healthSyncService.setInwardSyncMode(.disabled) }
                }
                Section {
                    LabeledContent("Outward Mode", value: String(describing: healthSyncService.outwardSyncMode))
                    OptionalDatePicker(selection: $outwardSyncDate)
                    Button("Set Mode") {
                        let mode: SyncMode = if let date = outwardSyncDate {
                            .enabledFrom(date: date)
                        } else {
                            .enabled
                        }
                        healthSyncService.setOutwardSyncMode(mode)
                    }
                    Button("Reset") { healthSyncService.setOutwardSyncMode(.disabled) }
                }
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
            } catch {
                print("HealthSyncService authorization failed: \(error)")
            }
        }
    }
}
