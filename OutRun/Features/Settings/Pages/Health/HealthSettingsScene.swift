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
                exportSection(for: healthSyncService)
                importSection(for: healthSyncService)
            }
            .navigationTitle("apple_health")
            .pickerStyle(.inline)
        } else {
            Text("error_health_sync_service_not_available")
        }
    }
    
    @ViewBuilder
    private func exportSection(for healthSyncService: HealthSyncService) -> some View {
        Section("Export Mode") {
            let outwardSyncModeBinding: Binding<SyncMode> = .init {
                healthSyncService.outwardSyncMode
            } set: { syncMode in
                let newSyncMode: SyncMode
                switch syncMode {
                case .enabledFrom:
                    if case .enabledFrom = healthSyncService.outwardSyncMode { return }
                    newSyncMode = .enabledFrom(date: .now)
                default:
                    newSyncMode = syncMode
                }
                healthSyncService.setOutwardSyncMode(newSyncMode)
            }
            Picker(selection: outwardSyncModeBinding) {
                HealthSyncModeOptionView(
                    "Do not Export",
                    imageName: "xmark",
                    messageKey: "No data will be exported to Apple Health."
                )
                .tag(SyncMode.disabled)
                if case .enabledFrom(let startDate) = healthSyncService.outwardSyncMode {
                    let formattedStartDate = startDate.formatted(date: .numeric, time: .shortened)
                    HealthSyncModeOptionView(
                        "Exporting Since \(formattedStartDate)",
                        imageName: "clock",
                        messageKey: "All new workouts created in this app after \(formattedStartDate) will be exported to Apple Health."
                    )
                    .tag(healthSyncService.outwardSyncMode)
                } else {
                    HealthSyncModeOptionView(
                        "Export Starting Now",
                        imageName: "clock",
                        messageKey: "All new workouts created in this app after turning this option on will be exported to Apple Health."
                    )
                    .tag(SyncMode.enabledFrom(date: .now))
                }
                HealthSyncModeOptionView(
                    "Export Everything",
                    imageName: "arrow.up",
                    messageKey: "All existing and new workouts created in this app will be exported to Apple Health."
                )
                .tag(SyncMode.enabled)
            } label: {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func importSection(for healthSyncService: HealthSyncService) -> some View {
        Section("Import Mode") {
            let inwardSyncModeBinding: Binding<SyncMode> = .init {
                healthSyncService.inwardSyncMode
            } set: { syncMode in
                let newSyncMode: SyncMode
                switch syncMode {
                case .enabledFrom:
                    if case .enabledFrom = healthSyncService.inwardSyncMode { return }
                    newSyncMode = .enabledFrom(date: .now)
                default:
                    newSyncMode = syncMode
                }
                healthSyncService.setInwardSyncMode(newSyncMode)
            }
            Picker(selection: inwardSyncModeBinding) {
                HealthSyncModeOptionView(
                    "Do not Import",
                    imageName: "xmark",
                    messageKey: "No data will be imported from Apple Health."
                )
                .tag(SyncMode.disabled)
                if case .enabledFrom(let startDate) = healthSyncService.inwardSyncMode {
                    let formattedStartDate = startDate.formatted(date: .numeric, time: .shortened)
                    HealthSyncModeOptionView(
                        "Importing Since \(formattedStartDate)",
                        imageName: "clock",
                        messageKey: "All Apple Health workouts started after \(formattedStartDate) will be imported into this app."
                    )
                    .tag(healthSyncService.inwardSyncMode)
                } else {
                    HealthSyncModeOptionView(
                        "Import Starting Now",
                        imageName: "clock",
                        messageKey: "All Apple Health workouts started after turning this option on will be imported into this app."
                    )
                    .tag(SyncMode.enabledFrom(date: .now))
                }
                HealthSyncModeOptionView(
                    "Import Everything",
                    imageName: "arrow.down",
                    messageKey: "All existing and new Apple Health workouts will be imported into this app."
                )
                .tag(SyncMode.enabled)
            } label: {
                EmptyView()
            }
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
