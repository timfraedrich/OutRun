import Foundation
import GPXKit
import OutRunCore

extension GPXTrack {
    
    init(from workout: any WorkoutProtocol) {
        let sortedRoute = workout.route.sorted(using: KeyPathComparator(\.timestamp))
        let sortedHeartRates = workout.heartRates.sorted(using: KeyPathComparator(\.timestamp))
        let trackPoints: [TrackPoint] = sortedRoute.map { sample in
            let index = sortedHeartRates.binarySearch { $0.timestamp < sample.timestamp }
            let heartRate = sortedHeartRates[safeIndex: index - 1].map(\.heartRate).map(UInt.init)
            return .init(
                coordinate: .init(
                    latitude: sample.latitude,
                    longitude: sample.longitude,
                    elevation: .init(sample.altitude)
                ),
                date: sample.timestamp,
                heartrate: heartRate,
                speed: .init(value: Double(sample.speed), unit: .metersPerSecond)
            )
        }
        self.init(
            date: workout.startDate,
            title: workout.name ?? workout.type.description,
            description: workout.comment,
            trackPoints: trackPoints,
            type: workout.type.gpxTypeIdentifier
        )
    }
}

extension RawWorkout {
    
    init(from track: GPXTrack) {
        let route = track.trackPoints.compactMap(RawWorkoutRouteDataSample.init)
        let heartRates = track.trackPoints.compactMap(RawWorkoutHeartRateDataSample.init)
        let startDate = route.first?.timestamp ?? track.date ?? .now
        let endDate = route.last?.timestamp
        let now = Date.now
        self.init(
            id: UUID(),
            type: .init(gpxTypeIdentifier: track.type),
            distance: track.graph.distance,
            startDate: startDate,
            endDate: endDate,
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: track.title.isEmpty ? nil : track.title,
            comment: track.description,
            creationDate: now,
            lastEditDate: now,
            source: .imported,
            heartRates: heartRates,
            route: route,
            pauses: [],
            events: [],
            serviceMappings: []
        )
    }
}

extension RawWorkoutRouteDataSample {
    
    init?(from trackPoint: TrackPoint) {
        guard let date = trackPoint.date else { return nil }
        self.init(
            timestamp: date,
            latitude: trackPoint.coordinate.latitude,
            longitude: trackPoint.coordinate.longitude,
            altitude: .init(trackPoint.coordinate.elevation),
            horizontalAccuracy: Self.invalidHorizontalAccuracy,
            verticalAccuracy: Self.invalidVerticalAccuracy,
            speed: trackPoint.speed.map { .init($0.converted(to: .metersPerSecond).value) } ?? Self.invalidSpeed
        )
    }
}

extension RawWorkoutHeartRateDataSample {
    
    init?(from trackPoint: TrackPoint) {
        guard let date = trackPoint.date, let heartrate = trackPoint.heartrate else { return nil }
        self.init(heartRate: .init(clamping: heartrate), timestamp: date)
    }
}

extension WorkoutType {
    
    var gpxTypeIdentifier: String {
        switch self {
        case .running: "running"
        case .walking: "walking"
        case .cycling: "cycling"
        case .skating: "skating"
        case .hiking: "hiking"
        case .unknown(let rawValue): "unknown_\(rawValue)"
        }
    }
    
    init(gpxTypeIdentifier: String?) {
        switch gpxTypeIdentifier?.lowercased() {
        case "running", "run": self = .running
        case "walking", "walk": self = .walking
        case "cycling", "cycle", "biking", "bike": self = .cycling
        case "skating", "skate": self = .skating
        case "hiking", "hike": self = .hiking
        default: self = .running
        }
    }
}
