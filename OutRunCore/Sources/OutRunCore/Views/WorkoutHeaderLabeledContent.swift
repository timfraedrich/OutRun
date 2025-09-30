import SwiftUI

public struct WorkoutHeaderLabeledContent: View {
    
    private let name: String?
    private let type: WorkoutType
    private let date: Date
    
    public var body: some View {
        if let name {
            LabeledContent {
                Text(name)
            } label: {
                HStack {
                    typeView
                    dateView
                }
            }
        } else {
            LabeledContent {
                dateView
            } label: {
                typeView
            }
        }
    }
    
    @ViewBuilder private var dateView: some View {
        RelativeDayDateText(date)
    }
    
    @ViewBuilder private var typeView: some View {
        WorkoutMetricText(metricValue: .type(type))
    }
    
    public init(name: String?, type: WorkoutType, date: Date) {
        self.name = name
        self.type = type
        self.date = date
    }
    
    public init(workout: any WorkoutProtocol) {
        self.init(
            name: workout.name,
            type: workout.type,
            date: workout.startDate
        )
    }
}
