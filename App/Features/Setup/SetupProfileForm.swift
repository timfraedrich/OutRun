import OutRunCore
import SwiftUI

struct SetupProfileForm: View {
    
    @Binding private var draft: SetupProfileDraft
    private let unitSystem: Binding<UnitSystem>?
    private let weightUnit: UnitMass
    
    private var defaultBirthdate: Date {
        Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now
    }
    
    var body: some View {
        Section {
            LabeledContent("user_name") {
                TextField("user_name_placeholder", text: $draft.name)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.givenName)
            }
            LabeledContent("user_weight") {
                MeasurementTextField(verbatim: "-", measurement: $draft.weight, unit: weightUnit)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("user_birthday") {
                OptionalDatePicker(
                    selection: $draft.birthdate,
                    in: ...Date.now,
                    defaultValue: defaultBirthdate,
                    displayedComponents: .date,
                    labelFormatStyle: .init(date: .abbreviated)
                )
                .buttonStyle(.plain)
                .symbolRenderingMode(.hierarchical)
            }
            Picker(selection: $draft.sex) {
                Text("user_sex_not_specified").tag(Sex?.none)
                ForEach(Sex.allCases, id: \.hashValue) { sex in
                    Text(sex.description.capitalized).tag(sex)
                }
            } label: {
                Text("user_sex")
            }
        } footer: {
            Text("setup_profile_weight_footer")
        }
        
        if let unitSystem {
            Section {
                Picker(selection: unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.hashValue) { system in
                        Text(system.description).tag(system)
                    }
                } label: {
                    Text("setup_units")
                }
            }
        }
    }
    
    init(draft: Binding<SetupProfileDraft>, unitSystem: Binding<UnitSystem>? = nil, weightUnit: UnitMass) {
        self._draft = draft
        self.unitSystem = unitSystem
        self.weightUnit = weightUnit
    }
}

#Preview {
    @Previewable @State var draft: SetupProfileDraft = .init()
    @Previewable @State var unitSystem: UnitSystem = .system
    SetupPageView(systemImage: "person.crop.circle.fill", title: "setup_profile_title", message: "setup_profile_message") {
        SetupProfileForm(draft: $draft, unitSystem: $unitSystem, weightUnit: unitSystem.weightUnit(for: .current))
    }
    .background(Color(.systemGroupedBackground))
    .customBottomSafeAreaBar {
        ActionButton("continue_action") {}.disabled(!draft.isComplete)
    }
}
