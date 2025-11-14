import Cache
@preconcurrency import MapKit
import OSLog
import SwiftUI
import UIKit

@MainActor
public enum StaticWorkoutMapService {
    
    private static let logger = Logger(category: "StaticMapService")
    private static let imageCache: Storage<String, UIImage>? = try? Storage<String, UIImage>(
        diskConfig: DiskConfig(
            name: OutRunCore.moduleIdentifier + ".static-map-images",
            expiry: .date(Date().addingTimeInterval(7 * 24 * 60 * 60)),
            maxSize: 50 * 1024 * 1024
        ),
        memoryConfig: MemoryConfig(
            expiry: .date(Date().addingTimeInterval(60 * 60)),
            countLimit: 50,
            totalCostLimit: 10 * 1024 * 1024
        ),
        fileManager: FileManager.default,
        transformer: TransformerFactory.forImage()
    )
    
    public static func getCachedImage(
        for workout: any WorkoutProtocol,
        size: CGSize,
        colorScheme: ColorScheme,
        accentColor: Color
    ) -> UIImage? {
        getCachedImage(for: workout.id, size: size, colorScheme: colorScheme, accentColor: accentColor)
    }
    
    public static func getCachedImage(
        for identifier: UUID,
        size: CGSize,
        colorScheme: ColorScheme,
        accentColor: Color
    ) -> UIImage? {
        let userInterfaceStyle = UIUserInterfaceStyle(colorScheme)
        let tintColor = UIColor(accentColor).withAlphaComponent(1)
        let cacheKey = cacheKey(identifier: identifier, size: size, userInterfaceStyle: userInterfaceStyle, tintColor: tintColor)
        do {
            if let imageCache, try imageCache.existsObject(forKey: cacheKey) {
                return try imageCache.object(forKey: cacheKey)
            }
        } catch {
            logger.warning("Cache read error: \((error as NSError).debugDescription).")
        }
        return nil
    }
    
    /// - throws: Throws if the workout has no route data or rendering the image fails.
    public static func generateImage(
        for workout: any WorkoutProtocol,
        size: CGSize,
        colorScheme: ColorScheme,
        accentColor: Color
    ) async throws -> UIImage? {
        try await generateImage(
            for: workout.id,
            coordinates: workout.route.map(\.coordinate),
            size: size,
            colorScheme: colorScheme,
            accentColor: accentColor
        )
    }
    
    /// - throws: Throws if the provided coordinates are empty or rendering the image fails.
    public static func generateImage(
        for identifier: UUID,
        coordinates: [CLLocationCoordinate2D],
        size: CGSize,
        colorScheme: ColorScheme,
        accentColor: Color
    ) async throws -> UIImage? {
        guard coordinates.count > 1 else { throw StaticWorkoutMapServiceError.noCoordinates }
        if let cachedImage = getCachedImage(for: identifier, size: size, colorScheme: colorScheme, accentColor: accentColor) {
            return cachedImage
        }
        let userInterfaceStyle = UIUserInterfaceStyle(colorScheme)
        let tintColor = UIColor(accentColor).withAlphaComponent(1)
        let cacheKey = cacheKey(identifier: identifier, size: size, userInterfaceStyle: userInterfaceStyle, tintColor: tintColor)
        let renderedImage = try await Task(priority: .background) {
            try await generateMapImage(for: coordinates, size: size, userInterfaceStyle: userInterfaceStyle, tintColor: tintColor)
        }.value
        if let imageCache, let renderedImage = renderedImage {
            do {
                try imageCache.setObject(renderedImage, forKey: cacheKey)
            } catch {
                logger.error("Failed to cache image: \((error as NSError).debugDescription).")
            }
        }
        return renderedImage
    }
    
    /// Clears the image cache and frees space on disk.
    public static func clearCache() throws {
        do {
            try imageCache?.removeAll()
            logger.info("Successfully cleared cache.")
        } catch {
            logger.error("Failed to clear cache: \((error as NSError).debugDescription).")
        }
    }
    
    /// The total size the image cache takes up on disk in bytes.
    public static var cacheSize: Int {
        imageCache?.totalDiskStorageSize ?? .zero
    }
    
    private static func cacheKey(identifier: UUID, size: CGSize, userInterfaceStyle: UIUserInterfaceStyle, tintColor: UIColor) -> String {
        let sizeString = "\(Int(size.width))x\(Int(size.height))"
        let appearanceString = userInterfaceStyle == .dark ? "dark" : "light"
        let tintColorString = tintColor.hexRepresentation
        return "\(identifier.uuidString)_\(sizeString)_\(appearanceString)_\(tintColorString)"
    }
    
    private static func generateMapImage(
        for coordinates: [CLLocationCoordinate2D],
        size: CGSize,
        userInterfaceStyle: UIUserInterfaceStyle,
        tintColor: UIColor
    ) async throws -> UIImage? {
        let route = MKPolyline(coordinates: coordinates, count: coordinates.count)
        let routeRect = route.boundingMapRect
        let mapRect = routeRect.insetBy(dx: -routeRect.width * 0.05, dy: -routeRect.height * 0.05)
        let region = MKCoordinateRegion(mapRect)
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        let traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        options.traitCollection = traitCollection
        options.pointOfInterestFilter = .excludingAll
        do {
            let snapshotter = MKMapSnapshotter(options: options)
            let snapshot = try await snapshotter.start()
            let renderer = UIGraphicsImageRenderer(size: size, format: .init(for: traitCollection))
            return renderer.image { context in
                snapshot.image.draw(at: .zero)
                context.cgContext.setLineWidth(5.0)
                context.cgContext.setLineCap(.round)
                context.cgContext.setLineJoin(.round)
                context.cgContext.setStrokeColor(tintColor.resolvedColor(with: traitCollection).cgColor)
                context.cgContext.move(to: snapshot.point(for: coordinates[0]))
                guard coordinates.count > 0 else { return }
                let firstPoint = snapshot.point(for: coordinates[0])
                context.cgContext.move(to: firstPoint)
                for coordinate in coordinates.dropFirst() {
                    context.cgContext.addLine(to: snapshot.point(for: coordinate))
                }
                context.cgContext.strokePath()
            }
        } catch {
            logger.error("Snapshot error: \(error.localizedDescription)")
            throw StaticWorkoutMapServiceError.renderingFailed
        }
    }
    
    // MARK: - Error Types
    
    /// Errors that can occur during map image creation
    public enum StaticWorkoutMapServiceError: CustomDebugStringConvertible, Equatable, LocalizedError {
        
        case noCoordinates
        case renderingFailed
        
        public var debugDescription: String {
            switch self {
            case .noCoordinates: "StaticWorkoutMapServiceError.noCoordinates"
            case .renderingFailed: "StaticWorkoutMapServiceError.renderingFailed"
            }
        }
        
        public var errorDescription: String? {
            switch self {
            case .noCoordinates: R.string.localizable.static_workout_map_service_error_no_coordinates()
            case .renderingFailed: R.string.localizable.static_workout_map_service_error_rendering_failed()
            }
        }
    }
}
