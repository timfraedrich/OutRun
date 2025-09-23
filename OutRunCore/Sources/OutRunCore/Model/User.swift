import Foundation
import SwiftData

@Model
public class User: UserProtocol {
    
    /// Optional identifier to identify a user with an external service.
    public var id: UUID?
    public var name: String
    public var weight: Double?
    public var sex: Sex?
    
    public var preferences: [String : Data]
    
    public private(set) var creationDate: Date
    public var lastEditDate: Date
    
    public init(
        id: UUID? = nil,
        name: String,
        weight: Double? = nil,
        sex: Sex? = nil,
        preferences: [String : Data] = [:],
        creationDate: Date,
        lastEditDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.weight = weight
        self.sex = sex
        self.preferences = preferences
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate ?? creationDate
    }
    
    /// - note: this initializer leaves out any kind of samples. Samples must be inserted into the context and linked
    /// manually.
    public convenience init(from rawUser: RawUser) {
        self.init(
            id: rawUser.id,
            name: rawUser.name,
            weight: rawUser.weight,
            sex: rawUser.sex,
            preferences: rawUser.preferences,
            creationDate: rawUser.creationDate,
            lastEditDate: rawUser.lastEditDate
        )
    }
}
