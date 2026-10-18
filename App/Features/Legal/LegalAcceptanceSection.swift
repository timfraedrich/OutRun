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

import SwiftUI

/// The toggles to accept the terms of service and to confirm having read the privacy policy, each linking to its document.
struct LegalAcceptanceSection: View {
    
    @Binding var acceptedTermsOfService: Bool
    @Binding var acceptedPrivacyPolicy: Bool
    @Binding var presentedDocument: LegalDocument?
    
    var body: some View {
        Section {
            toggle(
                for: .termsOfService,
                confirmation: "setup_legal_terms_of_service_confirmation",
                isOn: $acceptedTermsOfService
            )
            toggle(
                for: .privacyPolicy,
                confirmation: "setup_legal_privacy_policy_confirmation",
                isOn: $acceptedPrivacyPolicy
            )
        }
    }
    
    @ViewBuilder
    private func toggle(for document: LegalDocument, confirmation: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: .extraSmall) {
                Button {
                    presentedDocument = document
                } label: {
                    HStack(spacing: .extraSmall) {
                        Text(document.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Image(systemName: "arrow.up.right")
                    }
                    .fontWeight(.semibold)
                }
                Text(confirmation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.accentColor)
    }
}
