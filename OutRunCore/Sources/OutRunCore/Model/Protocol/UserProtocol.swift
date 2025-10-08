import Foundation

public protocol UserProtocol: Equatable {
    
    typealias RawPreferences = [String : Data]
    
    /// Optional identifier to identify a user with an external service.
    var id: UUID? { get set }
    /// The users name.
    /// - warning: This property should not be empty.
    var name: String { get set }
    var birthday: Day? { get set }
    /// The users weight in kilograms.
    var weight: Double? { get set }
    var sex: Sex? { get set }
    
    var preferences: RawPreferences { get set }
    
    var creationDate: Date { get }
    var lastEditDate: Date { get set }
}
