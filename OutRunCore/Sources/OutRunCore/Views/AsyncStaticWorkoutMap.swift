import CoreLocation
import SwiftUI

/// - warning: This view can only be used where an ``OutRunCore`` is part of the view environment.
public struct AsyncStaticWorkoutMap: View {
    
    @Environment(OutRunCore.self) private var core
    private let identifier: UUID
    private let coordinates: [CLLocationCoordinate2D]?
    private let accentColor: Color
    
    public var body: some View {
        StaticWorkoutMap(identifier: identifier, coordinates: coordinates, accentColor: accentColor, database: core.database)
    }
    
    /// - note: Due to the way the tint of a view is resolved in SwiftUI the color for the route and general tint color for other components
    /// must be provided through the ``accentColor`` parameter. The environment's tint color is not respected by this view.
    public init(identifier: UUID, coordinates: [CLLocationCoordinate2D]?, accentColor: Color = .accentColor) {
        self.identifier = identifier
        self.coordinates = coordinates
        self.accentColor = accentColor
    }
    
    /// - note: Due to the way the tint of a view is resolved in SwiftUI the color for the route on map must be explicitly provided. The
    /// environment's tint color is not respected by this view.
    public init(workout: any WorkoutProtocol, accentColor: Color = .accentColor) {
        self.init(identifier: workout.id, coordinates: nil, accentColor: accentColor)
    }
}
