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
