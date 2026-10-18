//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import OutRunCore
import SwiftUI

struct PermissionRow: View {

    @Environment(\.openURL) private var openURL
    @State private var requestError: Error?
    @State private var showInfo: Bool = false

    let item: PermissionItem

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(spacing: .small) {
                Image(systemName: item.systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: .zero) {
                    Text(verbatim: item.title).fontWeight(.medium)
                    Text(item.isRequired ? "permission_requirement_required" : "permission_requirement_optional")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Spacing.small.rawValue)
                PermissionStatusIndicator(status: item.status, requestAction: requestAction, infoAction: infoAction)
                    .errorPopover($requestError)
                    .popover(isPresented: $showInfo, content: resolutionContent)
            }
            Text(item.reason).font(.footnote).opacity(0.6)
        }
    }

    @ViewBuilder
    private func resolutionContent() -> some View {
        VStack(alignment: .center, spacing: .regular) {
            Text(item.resolution)
                .multilineTextAlignment(.center)
                .font(.footnote)
            if item.resolvableInSystemSettings {
                Button(action: openSystemSettings) {
                    Text("permission_open_settings_action").frame(maxWidth: .infinity)
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.regular)
        .presentationCompactAdaptation(.popover)
        .frame(idealWidth: 200)
    }
    
    private var requestAction: (() -> Void)? {
        guard let request = item.request else { return nil }
        return {
            Task {
                do {
                    try await request()
                } catch {
                    requestError = error
                }
            }
        }
    }
    
    private var infoAction: (() -> Void)? {
        guard item.status.requiresManualResolution else { return nil }
        return {
            showInfo = true
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

#Preview {
    List {
        Section {
            PermissionRow(item: .init(
                id: "location",
                title: "Location",
                systemImage: "location.fill",
                isRequired: true,
                reason: "Your location is used to record the route of your workouts.",
                status: .denied,
                resolution: "Open Settings and allow access to your location while using the app.",
                resolvableInSystemSettings: true,
                request: nil
            ))
            PermissionRow(item: .init(
                id: "motion",
                title: "Motion & Fitness",
                systemImage: "figure.walk.motion",
                isRequired: false,
                reason: "Motion data refines the elevation recorded for your workouts.",
                status: .undetermined,
                resolution: "Open Settings and turn on Motion & Fitness.",
                resolvableInSystemSettings: true,
                request: {}
            ))
        }
    }
}
