import OutRunCore
import SwiftUI
import WidgetKit

struct WorkoutLiveActivityTimer: View {

    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        HStack(spacing: 4) {
            if context.state.isPaused {
                Image(systemName: "pause.fill")
                    .imageScale(.small)
            }
            switch context.state.duration {
            case let .constant(timeInterval):
                let future = Date.distantFuture
                Text(future..<future.addingTimeInterval(timeInterval), format: .timeDuration)
            case let .increasing(since, offset):
                Text(since.addingTimeInterval(offset), style: .timer)
            }
        }
    }
}
