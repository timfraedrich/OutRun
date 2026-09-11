import OutRunCore
import SwiftUI

struct HealthSettingsScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(\.scenePhase) private var scenePhase
    @State private var outwardSyncDate: Date?
    @State private var inwardSyncDate: Date?

    var body: some View {
        if let healthSyncService = core.syncService(HealthSyncService.self) {
            List {
                permissionSection(for: healthSyncService)
                exportSection(for: healthSyncService)
                importSection(for: healthSyncService)
            }
            .safeAreaPadding(.top, .regular)
            .navigationTitle("apple_health")
            .pickerStyle(.inline)
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                await healthSyncService.refreshAuthorizationStatus()
            }
        } else {
            Text("error_health_sync_service_not_available")
        }
    }

    @ViewBuilder
    private func permissionSection(for healthSyncService: HealthSyncService) -> some View {
        Section {
            PermissionRow(item: .appleHealth(for: healthSyncService))
        } header: {
            Text("permissions")
        } footer: {
            Text("health_permissions_footer")
        }
    }

    @ViewBuilder
    private func exportSection(for healthSyncService: HealthSyncService) -> some View {
        Section("health_sync_export_mode") {
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
                    "health_sync_export_disabled",
                    imageName: "xmark",
                    messageKey: "health_sync_export_disabled_message"
                )
                .tag(SyncMode.disabled)
                if case .enabledFrom(let startDate) = healthSyncService.outwardSyncMode {
                    let formattedStartDate = startDate.formatted(date: .numeric, time: .shortened)
                    HealthSyncModeOptionView(
                        "health_sync_exporting_since_\(formattedStartDate)",
                        imageName: "clock",
                        messageKey: "health_sync_export_since_date_message_\(formattedStartDate)"
                    )
                    .tag(healthSyncService.outwardSyncMode)
                } else {
                    HealthSyncModeOptionView(
                        "health_sync_export_starting_now",
                        imageName: "clock",
                        messageKey: "health_sync_export_starting_now_message"
                    )
                    .tag(SyncMode.enabledFrom(date: .now))
                }
                HealthSyncModeOptionView(
                    "health_sync_export_everything",
                    imageName: "arrow.up",
                    messageKey: "health_sync_export_everything_message"
                )
                .tag(SyncMode.enabled)
            } label: {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func importSection(for healthSyncService: HealthSyncService) -> some View {
        Section("health_sync_import_mode") {
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
                    "health_sync_import_disabled",
                    imageName: "xmark",
                    messageKey: "health_sync_import_disabled_message"
                )
                .tag(SyncMode.disabled)
                if case .enabledFrom(let startDate) = healthSyncService.inwardSyncMode {
                    let formattedStartDate = startDate.formatted(date: .numeric, time: .shortened)
                    HealthSyncModeOptionView(
                        "health_sync_importing_since_\(formattedStartDate)",
                        imageName: "clock",
                        messageKey: "health_sync_import_since_date_message_\(formattedStartDate)"
                    )
                    .tag(healthSyncService.inwardSyncMode)
                } else {
                    HealthSyncModeOptionView(
                        "health_sync_import_starting_now",
                        imageName: "clock",
                        messageKey: "health_sync_import_starting_now_message"
                    )
                    .tag(SyncMode.enabledFrom(date: .now))
                }
                HealthSyncModeOptionView(
                    "health_sync_import_everything",
                    imageName: "arrow.down",
                    messageKey: "health_sync_import_everything_message"
                )
                .tag(SyncMode.enabled)
            } label: {
                EmptyView()
            }
        }
    }
}
