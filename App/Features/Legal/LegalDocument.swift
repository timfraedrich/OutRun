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

enum LegalDocument: Identifiable {
    
    case termsOfService
    case privacyPolicy
    case imprint
    
    var id: Self { self }
    
    var title: LocalizedStringKey {
        switch self {
        case .termsOfService: "legal_terms_of_service"
        case .privacyPolicy: "legal_privacy_policy"
        case .imprint: "legal_imprint"
        }
    }
    
    var url: URL? {
        let resource = switch self {
        case .termsOfService: "terms_of_service"
        case .privacyPolicy: "privacy_policy"
        case .imprint: "imprint"
        }
        return Bundle.main.url(forResource: resource, withExtension: "md")
    }
}
