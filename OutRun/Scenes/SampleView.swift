import OutRunCore
import SwiftUI

/// A sample view implementing the Figma design for the home screen with workout list
struct SampleView: View {

    // Sample data - in a real implementation this would come from @Query or @Environment
    private let userName: String = "Tim"
    private let sampleWorkouts: [SampleWorkout] = [
        .init(date: "Yesterday", type: "Running", distance: "7,12 km", time: "0:47:12", pace: "6:38", energy: "431 kcal"),
        .init(date: "Yesterday", type: "Running", distance: "7,12 km", time: "0:47:12", pace: "6:29"),
        .init(date: "Yesterday", type: "Running", distance: "7,12 km", time: "0:47:12", pace: "6:29"),
        .init(date: "Yesterday", type: "Running", distance: "7,12 km", time: "0:47:12", pace: "6:29"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: .regular) {
                    // Greeting section
                    greetingView
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Last workout card (larger, with more details)
                    lastWorkoutCard

                    // List of workout cards
                    ForEach(sampleWorkouts) { workout in
                        workoutCard(for: workout)
                    }
                }
                .padding(.horizontal, .regular)
            }
            .background()
            .safeAreaInset(edge: .bottom, content: bottomSafeAreaInsetContent)
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gear") {
                        // Settings action
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
    }

    @ViewBuilder
    private var greetingView: some View {
        HStack(spacing: Spacing.small.rawValue) {
            Text("Good morning").bold()
            Text(userName).bold().foregroundStyle(.tint)
        }
    }

    @ViewBuilder
    private var lastWorkoutCard: some View {
        VStack(alignment: .leading, spacing: .small) {
            // Header
            VStack(alignment: .leading, spacing: .extraSmall) {
                Text("YESTERDAY")
                    .font(.caption)
                    .foregroundStyle(.tertiaryLabel)
                    .bold()
                Text("Last Workout")
                    .font(.title2)
                    .bold()
            }
            .padding(.small)

            // Metrics
            VStack(alignment: .leading, spacing: .small) {
                HStack(spacing: .regular) {
                    metricLabel(label: "TYPE", value: "Running")
                    metricLabel(label: "BURNED ENERGY", value: "431 kcal")
                }

                HStack(spacing: .regular) {
                    metricLabel(label: "DISTANCE", value: "7,12 km")
                    metricLabel(label: "TIME", value: "0:47:12")
                    metricLabel(label: "PACE", value: "6:38")
                }
            }
            .padding(.horizontal, .small)

            // Map placeholder
            RoundedRectangle(cornerRadius: CornerRadius.regular.rawValue)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 128)
                .overlay {
                    Text("Map View")
                        .foregroundStyle(.secondary)
                }
                .padding(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.small)
        .background()
        .clipShape(.rect(cornerRadius: CornerRadius.regular.rawValue))
        .backgroundStyle(.secondaryBackground)
    }

    @ViewBuilder
    private func workoutCard(for workout: SampleWorkout) -> some View {
        HStack(alignment: .top, spacing: .small) {
            VStack(alignment: .leading, spacing: .small) {
                // Header
                VStack(alignment: .leading, spacing: .extraSmall) {
                    Text(workout.date.uppercased())
                        .font(.caption)
                        .foregroundStyle(.tertiaryLabel)
                        .bold()
                    Text(workout.type)
                        .font(.title2)
                        .bold()
                }

                // Metrics
                VStack(alignment: .leading, spacing: .small) {
                    metricLabel(label: "DISTANCE", value: workout.distance)

                    HStack(spacing: .regular) {
                        metricLabel(label: "TIME", value: workout.time)
                        metricLabel(label: "PACE", value: workout.pace)
                    }
                }
            }
            .padding(.small)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Map placeholder
            RoundedRectangle(cornerRadius: CornerRadius.regular.rawValue)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 140, height: 140)
                .overlay {
                    Text("Map")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
        }
        .padding(.small)
        .background()
        .clipShape(.rect(cornerRadius: .regular))
        .backgroundStyle(.secondaryBackground)
    }

    @ViewBuilder
    private func metricLabel(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiaryLabel)
                .bold()
            Text(value)
                .font(.callout)
                .bold()
        }
    }

    @ViewBuilder
    private func bottomSafeAreaInsetContent() -> some View {
        ActionButton("Start Workout", maxWidth: .infinity) {
            // Start workout action
        }
        .padding(.extraLarge)
        .background { BackgroundBlackoutGradient(startPoint: .top, endPoint: .center) }
    }
}

// MARK: - Sample Data Model

private struct SampleWorkout: Identifiable {
    let id = UUID()
    let date: String
    let type: String
    let distance: String
    let time: String
    let pace: String
    let energy: String?

    init(date: String, type: String, distance: String, time: String, pace: String, energy: String? = nil) {
        self.date = date
        self.type = type
        self.distance = distance
        self.time = time
        self.pace = pace
        self.energy = energy
    }
}

// MARK: - Preview

#Preview {
    SampleView().backgroundStyle(.primaryBackground)
}
