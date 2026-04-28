import OutRunCore

enum LegacyWorkoutEventType: Int {
    
    case pause = 0
    case autoPause = 1
    case resume = 2
    case autoResume = 3
    case lap = 4
    case marker = 5
    case segment = 6
    case unknown = -1
    
    init(rawValue: Int) {
        switch rawValue {
        case 0: self = .pause
        case 1: self = .autoPause
        case 2: self = .resume
        case 3: self = .autoResume
        case 4: self = .lap
        case 5: self = .marker
        case 6: self = .segment
        default: self = .unknown
        }
    }
}

extension Calculation.PauseEventType {
    
    init?(legacyEventType: LegacyWorkoutEventType) {
        switch legacyEventType {
        case .pause: self = .pause
        case .autoPause: self = .autoPause
        case .resume: self = .resume
        case .autoResume: self = .autoResume
        default: return nil
        }
    }
}
