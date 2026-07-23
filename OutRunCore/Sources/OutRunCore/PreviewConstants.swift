import CoreLocation

public enum PreviewConstants {
    
    public static let coordinates: [CLLocationCoordinate2D] = [
        .init(latitude: 37.33135095, longitude: -122.03073463),
        .init(latitude: 37.33131509, longitude: -122.03073779),
        .init(latitude: 37.33128013, longitude: -122.03073774),
        .init(latitude: 37.33124551, longitude: -122.03073664),
        .init(latitude: 37.33121136, longitude: -122.03073097),
        .init(latitude: 37.33117775, longitude: -122.03072292),
        .init(latitude: 37.33114614, longitude: -122.03071071),
        .init(latitude: 37.3311133, longitude: -122.03069859),
        .init(latitude: 37.33108059, longitude: -122.03068245),
        .init(latitude: 37.33104629, longitude: -122.03067027),
        .init(latitude: 37.33101308, longitude: -122.03065487),
        .init(latitude: 37.33097983, longitude: -122.03063943),
        .init(latitude: 37.33094637, longitude: -122.0306305),
        .init(latitude: 37.33091383, longitude: -122.03061321),
        .init(latitude: 37.33087803, longitude: -122.0305999),
        .init(latitude: 37.33084313, longitude: -122.03058427),
        .init(latitude: 37.33080974, longitude: -122.03057107),
        .init(latitude: 37.33077759, longitude: -122.03056052),
        .init(latitude: 37.3307498, longitude: -122.03054302),
        .init(latitude: 37.33072336, longitude: -122.0305179),
        .init(latitude: 37.3307092, longitude: -122.03048122),
        .init(latitude: 37.33070386, longitude: -122.03044428),
        .init(latitude: 37.33070704, longitude: -122.03039943),
        .init(latitude: 37.33069778, longitude: -122.03035543),
        .init(latitude: 37.33069131, longitude: -122.03031299),
        .init(latitude: 37.33068392, longitude: -122.03028038),
        .init(latitude: 37.33067157, longitude: -122.0302499),
        .init(latitude: 37.33067599, longitude: -122.03021599),
        .init(latitude: 37.33067203, longitude: -122.03018068),
        .init(latitude: 37.33067237, longitude: -122.03014382),
    ]
    
    public static var route: [RawWorkoutRouteDataSample] {
        coordinates.enumerated().map { (index, coordinate) in
            .init(
                timestamp: .init(timeIntervalSinceNow: .init(index)),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                altitude: -1,
                horizontalAccuracy: -1,
                verticalAccuracy: -1,
                speed: -1
            )
        }
    }
    
    /// An example running workout to use for previews. Has optional fields energy, name and route.
    public static let runningWorkout = RawWorkout(
        id: .init(),
        type: .running,
        distance: 1300,
        startDate: .now.addingTimeInterval(-900000),
        endDate: .now.addingTimeInterval(-900000 + 901),
        energy: 900 * 1000,
        repetitions: nil,
        isRace: false,
        name: "Morning Run",
        comment: nil,
        creationDate: .now,
        lastEditDate: .now,
        source: .native,
        route: PreviewConstants.route
    )
    
    /// An example cycling workout to use for previews. Has optional fields energy and repetitions. Is marked as a race.
    public static let cyclingWorkout = RawWorkout(
        id: .init(),
        type: .cycling,
        distance: 7892,
        startDate: .now,
        endDate: .now.addingTimeInterval(1201),
        energy: 2300 * 1000,
        repetitions: 2403,
        isRace: true,
        name: nil,
        comment: nil,
        creationDate: .now,
        lastEditDate: .now,
        source: .native
    )
}
