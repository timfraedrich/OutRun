import OutRunCore
import SwiftUI

struct PermissionStatusIndicator: View {

    let status: PermissionStatus
    let requestAction: (() -> Void)?
    let infoAction: (() -> Void)?
    
    init(status: PermissionStatus, requestAction: (() -> Void)? = nil, infoAction: (() -> Void)? = nil) {
        self.status = status
        self.requestAction = requestAction
        self.infoAction = infoAction
    }

    var body: some View {
        switch status {
        case .granted:
            Label("permission_status_granted", systemImage: "checkmark.circle.fill")
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(.green)
        case .undetermined:
            if let requestAction {
                statusButton("permission_allow_action", tint: Color?.none, action: requestAction)
            } else {
                statusText("permission_status_undetermined", tint: .secondary)
            }
        case .limited:
            infoStatusButton("permission_status_limited", tint: .orange, action: infoAction)
        case .denied:
            infoStatusButton("permission_status_denied", tint: .red, action: infoAction)
        case .unavailable:
            statusText("permission_status_unavailable", tint: .secondary)
        }
    }
    
    @ViewBuilder
    private func statusButton<S: ShapeStyle>(_ titleKey: LocalizedStringKey, tint: S?, action: @escaping () -> Void) -> some View {
        statusButton(tint: tint, action: action) {
            Text(titleKey)
        }
    }
    
    @ViewBuilder
    private func infoStatusButton<S: ShapeStyle>(_ titleKey: LocalizedStringKey, tint: S, action: (() -> Void)?) -> some View {
        if let action {
            statusButton(tint: tint, action: action) {
                HStack(spacing: .extraSmall) {
                    Image(systemName: "info.circle")
                    Text(titleKey)
                }
            }
        } else {
            statusText(titleKey, tint: tint)
        }
    }
    
    @ViewBuilder
    private func statusButton<S: ShapeStyle, Label: View>(tint: S?, action: @escaping () -> Void, @ViewBuilder label: () -> Label) -> some View {
        Button(action: action, label: label)
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(tint)
    }

    @ViewBuilder
    private func statusText<S: ShapeStyle>(_ titleKey: LocalizedStringKey, tint: S) -> some View {
        statusButton(titleKey, tint: tint, action: {})
            .foregroundStyle(tint)
            .disabled(true)
    }
}

#Preview {
    List {
        PermissionStatusIndicator(status: .granted)
        PermissionStatusIndicator(status: .undetermined, requestAction: {})
        PermissionStatusIndicator(status: .undetermined)
        PermissionStatusIndicator(status: .limited, infoAction: {})
        PermissionStatusIndicator(status: .limited)
        PermissionStatusIndicator(status: .denied, infoAction: {})
        PermissionStatusIndicator(status: .denied)
        PermissionStatusIndicator(status: .unavailable)
    }
}
