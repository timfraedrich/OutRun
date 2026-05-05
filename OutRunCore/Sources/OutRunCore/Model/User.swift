import Foundation
import SwiftData

@Model
public class User: UserProtocol {
    
    @Attribute(.unique, .preserveValueOnDeletion) public var id: UUID?
    public var name: String
    public var birthday: Day?
    public var weight: Double?
    public var sex: Sex?
    
    public var preferences: RawPreferences
    
    public private(set) var creationDate: Date
    public var lastEditDate: Date
    
    public init(
        id: UUID? = nil,
        name: String,
        birthday: Day? = nil,
        weight: Double? = nil,
        sex: Sex? = nil,
        preferences: RawPreferences = [:],
        creationDate: Date,
        lastEditDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.birthday = birthday
        self.weight = weight
        self.sex = sex
        self.preferences = preferences
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate ?? creationDate
    }
    
    public convenience init(from user: any UserProtocol) {
        self.init(
            id: user.id,
            name: user.name,
            birthday: user.birthday,
            weight: user.weight,
            sex: user.sex,
            preferences: user.preferences,
            creationDate: user.creationDate,
            lastEditDate: user.lastEditDate
        )
    }
}
