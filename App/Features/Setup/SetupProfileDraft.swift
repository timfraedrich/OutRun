import Foundation
import OutRunCore


struct SetupProfileDraft {
    
    var name: String = ""
    var birthdate: Date?
    var weight: Measurement<UnitMass>?
    var sex: Sex?
    
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isComplete: Bool { !trimmedName.isEmpty }
    var birthday: Day? { birthdate.map(Day.init) }
    var weightInKilograms: Double? { weight?.converted(to: .kilograms).value }
    
    init() {}
    
    init(from user: any UserProtocol) {
        name = user.name
        birthdate = try? user.birthday?.date()
        weight = user.weight.map { Measurement(value: $0, unit: .kilograms) }
        sex = user.sex
    }
}
