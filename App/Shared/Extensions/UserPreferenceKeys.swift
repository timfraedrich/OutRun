import OutRunCore

extension UserPreferenceKeys {

    static func preferenceKey(for name: String) -> String {
        OutRun.identifier + "." + name
    }
}
