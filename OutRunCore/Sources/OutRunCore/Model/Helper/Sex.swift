public enum Sex: CaseIterable, Codable, CustomDebugStringConvertible, CustomStringConvertible, Hashable, Sendable {
    
    case male
    case female
    
    public var description: String {
        switch self {
        case .male: R.string.localizable.sex_male()
        case .female: R.string.localizable.sex_female()
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .male: "Sex.male"
        case .female: "Sex.female"
        }
    }
}
