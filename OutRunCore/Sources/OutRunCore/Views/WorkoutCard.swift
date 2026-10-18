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

public struct WorkoutCard: View {
    
    @Environment(\.workoutCardStyle) private var style
    private let workout: any WorkoutProtocol
    
    public var body: some View {
        AnyView(style.makeBody(configuration: WorkoutCardStyleConfiguration(workout: workout)))
    }
    
    public init(workout: any WorkoutProtocol) {
        self.workout = workout
    }
}

@MainActor
public protocol WorkoutCardStyle: Sendable {
    
    associatedtype Body: View
    typealias Configuration = WorkoutCardStyleConfiguration
    
    func makeBody(configuration: Configuration) -> Body
}

@MainActor
public struct AnyWorkoutCardStyle: WorkoutCardStyle {
    
    private let makeBody: (Configuration) -> AnyView
    
    public init<W: WorkoutCardStyle>(_ style: W) {
        self.makeBody = { AnyView(style.makeBody(configuration: $0)) }
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        makeBody(configuration)
    }
}

public struct WorkoutCardStyleConfiguration {
    
    public let workout: any WorkoutProtocol
    
    init(workout: any WorkoutProtocol) {
        self.workout = workout
    }
}

private struct WorkoutCardStyleKey: EnvironmentKey {
    static let defaultValue: any WorkoutCardStyle = DefaultWorkoutCardStyle()
}

public extension EnvironmentValues {
    var workoutCardStyle: any WorkoutCardStyle {
        get { self[WorkoutCardStyleKey.self] }
        set { self[WorkoutCardStyleKey.self] = newValue }
    }
}

public extension View {
    func workoutCardStyle<S: WorkoutCardStyle>(_ style: S) -> some View {
        environment(\.workoutCardStyle, style)
    }
}

private struct DefaultWorkoutCardStyle: WorkoutCardStyle {
    func makeBody(configuration: Configuration) -> some View {
        Text(configuration.workout.id.uuidString)
    }
}
