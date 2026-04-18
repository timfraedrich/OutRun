import OutRunCore
import SwiftUI

struct SetupScene: View {
    
    @Environment(\.locale) private var locale
    @Environment(OutRunCore.self) private var core
    @State private var loading: Bool = false
    @State private var error: Error?
    @State private var name: String = ""
    @State private var birthdate: Date?
    @State private var unitSystem: UnitSystem = .system
    @State private var weight: Measurement<UnitMass>?
    @State private var sex: Sex?
    
    private var weightUnit: UnitMass {
        switch unitSystem {
        case .system: .init(forLocale: locale, usage: .personWeight)
        case .metric: .kilograms
        case .imperial: .pounds
        }
    }
    
    private var weightValueBinding: Binding<Double?> {
        .init {
            weight?.converted(to: weightUnit).value
        } set: { newValue in
            weight = if let newValue {
                .init(value: newValue, unit: weightUnit)
            } else {
                nil
            }
        }
    }
    
    private var formattedWeightUnit: String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.locale = locale
        return formatter.string(from: weightUnit)
    }
    
    var body: some View {
        Form {
            Section {
                LabeledContent("user_name") {
                    TextField("user_name_placeholder", text: $name).fixedSize()
                }
                LabeledContent("user_birthday") {
                    OptionalDatePicker(
                        selection: $birthdate,
                        in: ...Date.now,
                        displayedComponents: .date,
                        labelFormatStyle: .init(date: .abbreviated)
                    )
                    .buttonStyle(.plain)
                    .symbolRenderingMode(.hierarchical)
                }
                Picker(selection: $unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.hashValue) { system in
                        Text(system.description).tag(system)
                    }
                } label: {
                    Text("setup_units")
                }

                LabeledContent("user_weight") {
                    HStack(spacing: .small) {
                        TextField("user_weight_placeholder", value: weightValueBinding, format: .number).fixedSize()
                        Text(formattedWeightUnit)
                    }
                }
                Picker(selection: $sex) {
                    Text("user_sex_not_specified").tag(Sex?.none)
                    ForEach(Sex.allCases, id: \.hashValue) { sex in
                        Text(sex.description.capitalized).tag(sex)
                    }
                } label: {
                    Text("user_sex")
                }
            }
            .multilineTextAlignment(.trailing)
        }
        .overlay {
            if loading {
                ProgressView().progressViewStyle(.circular).controlSize(.large)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: .regular) {
                if let error {
                    Text(error.localizedDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                ActionButton("setup_action", action: setup)
            }
            .padding([.horizontal, .bottom], .large)
            .padding(.top, .regular)
            .background { BackgroundBlackoutGradient(startPoint: .top, endPoint: .center) }
            .ignoresSafeArea()
            .animation(.default, value: error?.localizedDescription)
        }
        .disabled(loading)
    }
    
    private func setup() {
        Task {
            loading = true
            do {
                // TODO: Implement validation
                guard !name.isEmpty else { throw SetupSceneError.nameEmpty }
                let birthday = birthdate.map(Day.init)
                let weight = weight?.converted(to: .kilograms).value
                let user = RawUser(name: name, birthday: birthday, weight: weight, sex: sex, creationDate: .now)
                try await core.setup(for: user)
            } catch {
                self.error = error
            }
            loading = false
        }
    }
    
    private enum SetupSceneError: LocalizedError {
        
        /// The field "Name" must not be empty.
        case nameEmpty
        
        var errorDescription: String? {
            switch self {
            case .nameEmpty: .init(localized: "setup_scene_error_name_empty")
            }
        }
    }
}

enum UnitSystem: CaseIterable, CustomStringConvertible, Hashable {
    case system
    case metric
    case imperial
    
    var description: String {
        switch self {
        case .system: .init(localized: "system")
        case .metric: .init(localized: "unit_system_metric")
        case .imperial: .init(localized: "unit_system_imperial")
        }
    }
}
