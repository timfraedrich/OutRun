#if os(iOS)
import SwiftUI
import SwiftData

public struct OutRunCoreScene<Content: View>: Scene {
    
    @State private var core: OutRunCore
    private let makeContent: (OutRunCore.Status) -> Content
    
    public var body: some Scene {
        WindowGroup {
            makeContent(core.status).environment(core)
        }
        .modelContainer(core.modelContainer)
    }
    
    public init(@ViewBuilder makeContent: @escaping (OutRunCore.Status) -> Content) {
        self.core = OutRunCore()
        self.makeContent = makeContent
    }
}
#endif
