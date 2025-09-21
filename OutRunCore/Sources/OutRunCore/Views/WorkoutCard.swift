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
