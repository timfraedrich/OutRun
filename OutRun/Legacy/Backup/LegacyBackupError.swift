// TODO: Localize
enum LegacyBackupError: Error {
    case corruptedData
    case missingVersion
    case invalidVersion
}
