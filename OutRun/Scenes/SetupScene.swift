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
                Picker(selection: $unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.hashValue) { system in
                        Text(system.description).tag(system)
                    }
                } label: {
                    Text("Units")
                }

                LabeledContent("Weight") {
                    HStack(spacing: .small) {
                        TextField("Your weight", value: weightValueBinding, format: .number).fixedSize()
                        Text(formattedWeightUnit)
                    }
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
                ActionButton(verbatim: "Setup", action: setup)
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
        case nameEmpty
        
        var errorDescription: String? {
            switch self {
            case .nameEmpty: "The field \"Name\" must not be empty."
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
        case .system: "System"
        case .metric: "Metric"
        case .imperial: "Imperial"
        }
    }
}
