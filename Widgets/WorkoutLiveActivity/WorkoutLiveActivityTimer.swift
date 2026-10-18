//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
