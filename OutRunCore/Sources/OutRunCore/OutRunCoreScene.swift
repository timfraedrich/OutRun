#if os(iOS)
import SwiftUI
import SwiftData

public struct OutRunCoreScene<Content: View>: Scene {
    
    @State private var core: OutRunCore
    private let makeContent: (OutRunCoreStatus) -> Content
    
    public var body: some Scene {
        WindowGroup {
            makeContent(core.status)
                .environment(core)
                .environment(core.recorder)
                .environment(core.userPreferences)
        }
        .modelContainer(core.modelContainer)
    }
    
    public init(config: OutRunCoreConfiguration, @ViewBuilder makeContent: @escaping (OutRunCore.Status) -> Content) {
        self.core = OutRunCore(config: config)
        self.makeContent = makeContent
    }
}
#endif
