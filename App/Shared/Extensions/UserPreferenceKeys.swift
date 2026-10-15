import OutRunCore

extension UserPreferenceKeys {

    static func preferenceKey(for name: String) -> String {
        "de.tadris.OutRun." + name
    }
}
