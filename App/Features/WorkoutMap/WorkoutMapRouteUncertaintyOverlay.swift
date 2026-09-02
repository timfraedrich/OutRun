import CoreLocation
import MapKit
import OutRunCore
import SwiftUI

struct WorkoutMapRouteUncertaintyOverlay: MapContent {
    
    private static let earthRadiusMeters: Double = 6_371_000
    private static let endCapSegmentCount: Int = 12
    
    private let coordinates: [CLLocationCoordinate2D]
    private let fillStyle: AnyShapeStyle
    private let strokeStyle: AnyShapeStyle
    private let lineWidth: CGFloat
    
    init<Fill: ShapeStyle, Stroke: ShapeStyle>(
        samples: [WorkoutRouteDataSample],
        fill: Fill,
        stroke: Stroke,
        lineWidth: CGFloat = 1
    ) {
        self.coordinates = Self.uncertaintyPolygon(for: samples)
        self.fillStyle = AnyShapeStyle(fill)
        self.strokeStyle = AnyShapeStyle(stroke)
        self.lineWidth = lineWidth
    }
    
    var body: some MapContent {
        if coordinates.count >= 3 {
            MapPolygon(coordinates: coordinates)
                .foregroundStyle(fillStyle)
                .stroke(strokeStyle, lineWidth: lineWidth)
        }
    }
    
    private static func uncertaintyPolygon(
        for samples: [WorkoutRouteDataSample]
    ) -> [CLLocationCoordinate2D] {
        let valid = simplifyByAccuracy(samples.filter { $0.horizontalAccuracy > 0 })
        guard valid.count >= 2 else { return [] }
        
        var leftSide: [CLLocationCoordinate2D] = []
        var rightSide: [CLLocationCoordinate2D] = []
        leftSide.reserveCapacity(valid.count)
        rightSide.reserveCapacity(valid.count)
        
        for index in valid.indices {
            let sample = valid[index]
            let radius = Double(sample.horizontalAccuracy)
            let incoming: Double? = index > 0
                ? bearing(from: valid[index - 1].coordinate, to: sample.coordinate)
                : nil
            let outgoing: Double? = index < valid.count - 1
                ? bearing(from: sample.coordinate, to: valid[index + 1].coordinate)
                : nil
            let localBearing = averageBearing(incoming, outgoing)
            
            leftSide.append(offset(
                from: sample.coordinate,
                bearing: localBearing - .pi / 2,
                distance: radius
            ))
            rightSide.append(offset(
                from: sample.coordinate,
                bearing: localBearing + .pi / 2,
                distance: radius
            ))
        }
        
        let first = valid.first!
        let last = valid.last!
        let startForward = bearing(from: first.coordinate, to: valid[1].coordinate)
        let endForward = bearing(from: valid[valid.count - 2].coordinate, to: last.coordinate)
        
        let startCap = semicircle(
            center: first.coordinate,
            radius: Double(first.horizontalAccuracy),
            centerBearing: startForward + .pi
        )
        let endCap = semicircle(
            center: last.coordinate,
            radius: Double(last.horizontalAccuracy),
            centerBearing: endForward
        )
        
        return leftSide + endCap + rightSide.reversed() + startCap
    }
    
    // Drops samples that sit closer to the previously kept sample than half the
    // smaller of their accuracy radii. Tightly-spaced samples make bearing
    // estimates dominated by GPS noise, which collapses the ribbon into a
    // self-intersecting zigzag once perpendicular offsets are much larger than
    // the spacing between sample points.
    private static func simplifyByAccuracy(
        _ samples: [WorkoutRouteDataSample]
    ) -> [WorkoutRouteDataSample] {
        guard let firstSample = samples.first else { return [] }
        var kept: [WorkoutRouteDataSample] = [firstSample]
        kept.reserveCapacity(samples.count)
        
        for sample in samples.dropFirst() {
            let last = kept.last!
            let spacing = distance(last.coordinate, sample.coordinate)
            let minSpacing = max(
                Double(min(last.horizontalAccuracy, sample.horizontalAccuracy)) * 0.5,
                1
            )
            if spacing < minSpacing { continue }
            kept.append(sample)
        }
        
        // Preserve the true endpoint so the buffer reaches the actual finish.
        if let originalLast = samples.last, kept.last?.timestamp != originalLast.timestamp {
            if kept.count >= 2,
               distance(kept[kept.count - 1].coordinate, originalLast.coordinate) <
                max(Double(originalLast.horizontalAccuracy) * 0.25, 1) {
                kept[kept.count - 1] = originalLast
            } else {
                kept.append(originalLast)
            }
        }
        return kept
    }
    
    private static func distance(
        _ a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let deltaLatitude = lat2 - lat1
        let deltaLongitude = (b.longitude - a.longitude) * .pi / 180
        let h = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return 2 * earthRadiusMeters * asin(min(1, sqrt(h)))
    }
    
    private static func bearing(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLongitude = (to.longitude - from.longitude) * .pi / 180
        let y = sin(deltaLongitude) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLongitude)
        return atan2(y, x)
    }
    
    private static func averageBearing(_ a: Double?, _ b: Double?) -> Double {
        switch (a, b) {
        case let (.some(a), .some(b)):
            // average direction handling angle wraparound via unit-vector sum
            return atan2(sin(a) + sin(b), cos(a) + cos(b))
        case let (.some(a), .none): return a
        case let (.none, .some(b)): return b
        case (.none, .none): return 0
        }
    }
    
    private static func offset(
        from coordinate: CLLocationCoordinate2D,
        bearing: Double,
        distance: Double
    ) -> CLLocationCoordinate2D {
        let angularDistance = distance / earthRadiusMeters
        let lat1 = coordinate.latitude * .pi / 180
        let lon1 = coordinate.longitude * .pi / 180
        let lat2 = asin(
            sin(lat1) * cos(angularDistance) +
            cos(lat1) * sin(angularDistance) * cos(bearing)
        )
        let lon2 = lon1 + atan2(
            sin(bearing) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2)
        )
        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }
    
    private static func semicircle(
        center: CLLocationCoordinate2D,
        radius: Double,
        centerBearing: Double
    ) -> [CLLocationCoordinate2D] {
        guard radius > 0 else { return [center] }
        let start = centerBearing - .pi / 2
        let sweep = Double.pi
        return (0...endCapSegmentCount).map { step in
            let progress = Double(step) / Double(endCapSegmentCount)
            return offset(
                from: center,
                bearing: start + sweep * progress,
                distance: radius
            )
        }
    }
}
