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

import Foundation
import OutRunCore

extension UserPreferences {

    var acceptedLegalVersion: Int? {
        get { value(for: UserPreferenceKeys.acceptedLegalVersion) }
        set { setValue(newValue, for: UserPreferenceKeys.acceptedLegalVersion) }
    }

    var legalAcceptanceDate: Date? {
        get { value(for: UserPreferenceKeys.legalAcceptanceDate) }
        set { setValue(newValue, for: UserPreferenceKeys.legalAcceptanceDate) }
    }

    /// Records acceptance of ``LegalAcceptance/currentVersion``.
    func recordLegalAcceptance(on date: Date = .now) {
        acceptedLegalVersion = LegalAcceptance.currentVersion
        legalAcceptanceDate = date
    }

    /// Records acceptance of ``LegalAcceptance/currentVersion`` unless an acceptance is already on file.
    ///
    /// Used by the legacy migration, where consent was given in the previous version of the app and must not be requested again, but still
    /// needs to be on file so a future revision of the documents can be detected.
    func recordLegalAcceptanceIfNeeded(on date: Date = .now) {
        guard acceptedLegalVersion == nil else { return }
        recordLegalAcceptance(on: date)
    }
}
