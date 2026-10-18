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

struct WorkoutLiveActivityContent: View {

    @Environment(\.activityFamily) private var family

    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        switch family {
        case .medium:
            WorkoutLiveActivityMediumContent(context: context)
                .userPreferences(of: context)
        case .small:
            WorkoutLiveActivitySmallContent(context: context)
                .userPreferences(of: context)
        @unknown default:
            EmptyView()
        }
    }
}
