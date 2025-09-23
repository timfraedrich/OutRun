import Foundation

public struct RawUser: UserProtocol {
    
    public var id: UUID?
    public var name: String
    public var weight: Double?
    public var sex: Sex?
    
    public var preferences: [String : Data]
    
    public let creationDate: Date
    public var lastEditDate: Date
    
    public init(
        id: UUID? = nil,
        name: String,
        weight: Double? = nil,
        sex: Sex? = nil,
        preferences: [String : Data],
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
}
