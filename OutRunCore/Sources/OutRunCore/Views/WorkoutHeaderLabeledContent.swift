//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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
                typeView
            } label: {
                dateView
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
