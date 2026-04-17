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
                    Button {
                        grantPermissions(for: healthSyncService)
                    } label: {
                        Text(verbatim: "Grant Permissions")
                    }
                    .errorPopover($grantPermissionError)
                }
                Section {
                    LabeledContent {
                        Text(String(describing: healthSyncService.inwardSyncMode))
                    } label: {
                        Text(verbatim: "Inward Mode")
                    }
                    LabeledContent {
                        OptionalDatePicker(selection: $inwardSyncDate)
                    } label: {
                        Text(verbatim: "Start Date")
                    }
                    
                    Button {
                        let mode: SyncMode = if let date = inwardSyncDate {
                            .enabledFrom(date: date)
                        } else {
                            .enabled
                        }
                        healthSyncService.setInwardSyncMode(mode)
                    } label: {
                        Text(verbatim: "Set Mode")
                    }
                    Button("reset") {
                        healthSyncService.setInwardSyncMode(.disabled)
                    }
                }
                Section {
                    LabeledContent {
                        Text(String(describing: healthSyncService.outwardSyncMode))
                    } label: {
                        Text(verbatim: "Outward Mode")
                    }
                    LabeledContent {
                        OptionalDatePicker(selection: $outwardSyncDate)
                    } label: {
                        Text(verbatim: "Start Date")
                    }
                    
                    Button {
                        let mode: SyncMode = if let date = outwardSyncDate {
                            .enabledFrom(date: date)
                        } else {
                            .enabled
                        }
                        healthSyncService.setOutwardSyncMode(mode)
                    } label: {
                        Text(verbatim: "Set Mode")
                    }
                    Button("reset") {
                        healthSyncService.setOutwardSyncMode(.disabled)
                    }
                }
            }
            .navigationTitle("apple_health")
        } else {
            Text("error_health_sync_service_not_available")
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
