import CoreLocation
import SwiftData
import SwiftUI

public struct StaticWorkoutMap: View {
    
    @Environment(\.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var insertedOrCachedCoordinates: [CLLocationCoordinate2D]?
    @State private var image: UIImage?
    @State private var size: CGSize = .zero
    @State private var task: Task<Void, Never>?
    @State private var error: Error?
    @State private var animate: Bool = false
    @State private var showError: Bool = false
    @State private var tintColor: CGColor?
    // We set this explicitly rather than using the Environment property wrapper, as the wrapped colorScheme exposed the old value even
    // after the onChange notification was received.
    @State private var colorScheme: ColorScheme?
    private let identifier: UUID
    
    public var body: some View {
        ZStack {
            Rectangle().fill(.tint.tertiary)
            if let image {
                Image(uiImage: image).resizable()
            } else if let error {
                Button {
                    showError = true
                } label: {
                    Image(systemName: "photo.trianglebadge.exclamationmark")
                        .symbolVariant(.fill)
                        .foregroundStyle(.tint)
                        .font(.title)
                }
                .popover(isPresented: $showError, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                    Text(error.localizedDescription).padding().presentationCompactAdaptation(.popover)
                }
            } else {
                Rectangle()
                    .fill(.background.opacity(animate ? 0.75 : 0.25))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
                    .onAppear { animate = true }
            }
        }
        .onChange(of: environment.colorScheme, initial: true) { oldValue, newValue in
            colorScheme = newValue
            reloadImage()
        }
        .onChange(of: scenePhase, sceneChangeAction)
        .background {
            ResolveTintColorView { color in
                tintColor = color
                reloadImage()
            }
        }
        .background {
            GeometryReader { geo in
                DispatchQueue.main.async {
                    guard geo.size != size else { return }
                    size = geo.size
                    loadImage()
                }
                return Color.clear
            }
        }
    }
    
    /// - note: Due to the way the tint of a view is resolved in SwiftUI the color for the route and general tint color for other components
    /// must be provided through the ``accentColor`` parameter. The environment's tint color is not respected by this view.
    public init(identifier: UUID, coordinates: [CLLocationCoordinate2D]? = nil) {
        self.identifier = identifier
        self._insertedOrCachedCoordinates = .init(initialValue: coordinates)
    }
    
    /// - note: Due to the way the tint of a view is resolved in SwiftUI the color for the route on map must be explicitly provided. The
    /// environment's tint color is not respected by this view.
    public init(workout: any WorkoutProtocol) {
        self.init(identifier: workout.id, coordinates: workout.route.map(\.coordinate))
    }
    
    private func sceneChangeAction() {
        if scenePhase == .active, image == nil, size != .zero {
            loadImage()
        } else if scenePhase == .background {
            task?.cancel()
        }
    }
    
    private func loadImage() {
        guard let tintColor, let colorScheme, size.width != .zero, size.height != .zero else { return }
        let insertedOrCachedCoordinates = self.insertedOrCachedCoordinates
        task?.cancel()
        if let cachedImage = StaticWorkoutMapService.getCachedImage(for: identifier, size: size, colorScheme: colorScheme, tintColor: tintColor) {
            image = cachedImage
            return
        }
        let container = modelContext.container
        task = Task { @BackgroundActor [insertedOrCachedCoordinates, colorScheme, container] in
            do {
                let coordinates: [CLLocationCoordinate2D]
                if let insertedOrCachedCoordinates {
                    coordinates = insertedOrCachedCoordinates
                } else {
                    let context = ModelContext(container)
                    let descriptor = FetchDescriptor(
                        predicate: #Predicate<WorkoutRouteDataSample> { $0.workout?.id == identifier },
                        sortBy: [SortDescriptor(\.timestamp)]
                    )
                    coordinates = try context.fetch(descriptor).map(\.coordinate)
                    await MainActor.run { self.insertedOrCachedCoordinates = coordinates }
                }
                guard !Task.isCancelled else { return }
                let image = try await StaticWorkoutMapService.generateImage(
                    for: identifier,
                    coordinates: coordinates,
                    size: size,
                    colorScheme: colorScheme,
                    tintColor: tintColor
                )
                guard !Task.isCancelled else { return }
                await MainActor.run { self.image = image }
            } catch {
                await MainActor.run { self.error = error }
            }
        }
    }
    
    private func reloadImage() {
        image = nil
        loadImage()
    }
}

#Preview {
    List {
        LazyVStack {
            StaticWorkoutMap(workout: PreviewConstants.runningWorkout)
                .frame(height: 300)
                .clipShape(.rect(cornerRadius: 32))
                .padding()
        }
    }
}
