import OutRunCore
import SwiftUI

struct ProfileScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var name: String = ""
    @State private var weight: Measurement<UnitMass>?
    @State private var birthdate: Date?
    @State private var sex: Sex?
    @State private var error: Error?
    
    var body: some View {
        Form {
            LabeledContent("Name") {
                TextField("Your name", text: $name).fixedSize()
            }
            LabeledContent("Birthday") {
                OptionalDatePicker(
                    selection: $birthdate,
                    in: ...Date.now,
                    displayedComponents: .date,
                    labelFormatStyle: .init(date: .abbreviated)
                )
                .buttonStyle(.plain)
                .symbolRenderingMode(.hierarchical)
            }
            LabeledContent("Weight") {
                MeasurementTextField("Your weight", measurement: $weight, unit: userPreferences.safeWeightUnit(for: locale))
            }
            Picker(selection: $sex) {
                Text("Not specified").tag(Sex?.none)
                ForEach(Sex.allCases, id: \.hashValue) { sex in
                    Text(sex.description.capitalized).tag(sex)
                }
            } label: {
                Text("Sex")
            }
        }
        .multilineTextAlignment(.trailing)
        .navigationTitle("User Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).errorPopover($error)
            }
        }
        .onAppear {
            guard let user = core.user else { return }
            name = user.name
            birthdate = try? user.birthday?.date()
            let userWeight: Measurement<UnitMass>? = if let weight = user.weight {
                .init(value: weight, unit: .kilograms)
            } else {
                nil
            }
            weight = userWeight
            sex = user.sex
        }
    }
    
    private func save() {
        Task {
            do {
                let birthday = birthdate.map(Day.init)
                let weight = weight?.converted(to: .kilograms).value
                try await core.updateUserProperties(name: name, birthday: birthday, weight: weight, sex: sex)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
