public enum Sex: String, CaseIterable, Codable, CustomDebugStringConvertible, CustomStringConvertible, Hashable, Sendable {
    
    case male
    case female
    
    public var description: String {
        switch self {
        case .male: .init(localized: "sex_male", bundle: .module)
        case .female: .init(localized: "sex_female", bundle: .module)
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .male: "Sex.male"
        case .female: "Sex.female"
        }
    }
}
