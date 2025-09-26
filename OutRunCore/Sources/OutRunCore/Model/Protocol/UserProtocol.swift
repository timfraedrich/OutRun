import Foundation

public protocol UserProtocol: Equatable {
    
    typealias RawPreferences = [String : Data]
    
    var id: UUID? { get set }
    var name: String { get set }
    var weight: Double? { get set }
    var sex: Sex? { get set }
    
    var preferences: RawPreferences { get set }
    
    var creationDate: Date { get }
    var lastEditDate: Date { get set }
}
