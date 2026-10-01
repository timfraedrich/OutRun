import Foundation
import OutRunCore

/// The revision of the terms of service and privacy policy the app currently presents.
///
/// Increment ``currentVersion`` whenever either document changes in a way that requires renewed consent. Users whose stored
/// ``UserPreferences/acceptedLegalVersion`` is lower can then be asked to accept again.
enum LegalAcceptance {
    
    static let currentVersion: Int = 1
}
