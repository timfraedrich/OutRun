import SwiftUI

struct EstimatedTimeRemainingText: View {

    let estimatedEnd: Date?

    var body: some View {
        if let estimatedEnd {
            TimelineView(.periodic(from: .now, by: 10)) { context in
                let remainingTime = formattedRemainingTime(for: context.date, estimatedEnd: estimatedEnd)
                Text("legacy_migration_view_migration_estimated_time_\(remainingTime)")
            }
        } else {
            Text("legacy_migration_view_migration_estimating_time")
        }
    }

    private func formattedRemainingTime(for date: Date, estimatedEnd: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .full
        return formatter.string(from: date, to: estimatedEnd) ?? ""
    }
}
