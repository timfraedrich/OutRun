public enum Sex: Codable, CustomDebugStringConvertible, Equatable, Sendable {
    
    case male
    case female
    
    public var debugDescription: String {
        switch self {
        case .male: "Sex.male"
        case .female: "Sex.female"
        }
    }
}
