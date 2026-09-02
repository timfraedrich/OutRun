#if DEBUG
import SwiftUI
import TFRouting

// MARK: - Routes

/// - note: A tab route is a ``RoutePresentation/selection`` value of the root context, and its
/// ``RouteProtocol/scope()`` becomes the scope of the branch backing that tab.
enum DemoTabRoute: RouteProtocol {
    
    case library
    case profile
    
    var defaultPresentation: RoutePresentation { .selection }
    
    func content(in context: RouteContext) -> some View {
        switch self {
        case .library: DemoLibraryScreen()
        case .profile: DemoProfileScreen()
        }
    }
    
    func scope() -> (any RoutingScope)? {
        switch self {
        case .library: DemoLibraryScope()
        case .profile: DemoProfileScope()
        }
    }
}

/// The headline of this demo: one declaration, pushed by ``DemoLibraryScope`` and presented as a sheet
/// by ``DemoProfileScope``.
struct DemoItemRoute: RouteProtocol {
    
    let id: Int
    
    func content(in context: RouteContext) -> some View {
        DemoItemScreen(id: id, context: context)
    }
    
    func scope() -> (any RoutingScope)? {
        DemoItemScope()
    }
}

struct DemoEditRoute: RouteProtocol {
    
    let id: Int
    
    func content(in context: RouteContext) -> some View {
        DemoEditScreen(id: id, context: context)
    }
}

struct DemoSettingsRoute: RouteProtocol {
    
    func content(in context: RouteContext) -> some View {
        DemoSettingsScreen(context: context)
    }
}

/// - note: Claimed by no scope of its own; ``DefaultScope`` pushes it because that is its default presentation.
struct DemoSettingsPageRoute: RouteProtocol {
    
    var defaultPresentation: RoutePresentation { .push }
    
    func content(in context: RouteContext) -> some View {
        DemoSettingsPageScreen()
    }
}

struct DemoBlockedRoute: RouteProtocol {
    
    func content(in context: RouteContext) -> some View {
        Text("Never presented.")
    }
}

// MARK: - Scopes

struct DemoRootScope: RoutingScope {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is DemoTabRoute: .present(.selection)
        case is DemoSettingsRoute: .present(.sheet(.full))
        default: .pass
        }
    }
}

/// - note: ``DemoEditRoute`` is claimed here as well as by ``DemoItemScope``, because a push creates no
/// node of its own: a pushed item routes from this branch, a presented one from its own context.
struct DemoLibraryScope: RoutingScope {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is DemoItemRoute: .present(.push)
        case is DemoEditRoute: .present(.fullScreenCover)
        default: .pass
        }
    }
}

struct DemoProfileScope: RoutingScope {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is DemoItemRoute: .present(.sheet(.full))
        case is DemoBlockedRoute: .reject(.noHandler(routeType: String(describing: type(of: route))))
        default: .pass
        }
    }
}

struct DemoItemScope: RoutingScope {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is DemoEditRoute: .present(.sheet(.dynamic))
        default: .pass
        }
    }
}

// MARK: - Scene

struct DemoRoutingScene: View {
    
    @State private var router = Router(scope: DemoRootScope())
    
    var body: some View {
        @Bindable var root = router.root
        TabView(selection: $root.selection) {
            Tab("Library", systemImage: "books.vertical", value: DemoTabRoute.library.eraseToAnyRoute()) {
                branchHost(for: DemoTabRoute.library)
            }
            Tab("Profile", systemImage: "person.crop.circle", value: DemoTabRoute.profile.eraseToAnyRoute()) {
                branchHost(for: DemoTabRoute.profile)
            }
        }
        .environment(router)
        .task {
            guard router.root.selection == nil else { return }
            router.route(DemoTabRoute.library)
        }
    }
    
    @ViewBuilder
    private func branchHost(for tab: any RouteProtocol) -> some View {
        RouterHost(node: router.root.branch(for: tab)) {
            RouteContentView(route: tab, context: .init(presentation: .selection))
        }
    }
}

// MARK: - Tab screens

struct DemoLibraryScreen: View {
    
    @Environment(Router.self) private var router
    
    var body: some View {
        List {
            Section {
                Button("Open item 1") { router.route(DemoItemRoute(id: 1)) }
            } header: {
                Text("One route, two presentations")
            } footer: {
                Text("DemoLibraryScope pushes DemoItemRoute. The same button in Profile presents it as a sheet.")
            }
            Section {
                RouteLink("Item 2 via RouteLink", route: DemoItemRoute(id: 2))
                NavigationLink(route: DemoItemRoute(id: 3)) {
                    Text("Item 3 via NavigationLink(route:)")
                }
            } header: {
                Text("Links")
            } footer: {
                Text("RouteLink asks the scopes. NavigationLink(route:) appends to this stack directly and bypasses them.")
            }
            Section {
                RouteLink("Settings — passed up to DemoRootScope", route: DemoSettingsRoute())
                Button("Deep link: Profile → item 7 → edit 7") { router.open(Self.deepLink) }
            } header: {
                Text("Other presentations")
            } footer: {
                Text("The deep link runs open([…]) as one program: selection, then branch, then modal, then its modal.")
            }
            Section {
                Button("Blocked route — no scope claims it here") { router.route(DemoBlockedRoute()) }
            } header: {
                Text("Failures")
            } footer: {
                Text("Watch lastFailure in the inspector below.")
            }
            Section {
                Button("Discard the Profile branch") { router.root.discardBranch(for: DemoTabRoute.profile) }
            } header: {
                Text("Branches")
            } footer: {
                Text("Push an item, switch to Profile and back: the path survives. Discarding a branch resets it, visible after switching to that tab.")
            }
            DemoControlsSection()
        }
        .navigationTitle("Library")
        .safeAreaInset(edge: .bottom) { DemoStateInspector(label: "Library branch") }
    }
    
    private static let deepLink: [any RouteProtocol] = [DemoTabRoute.profile, DemoItemRoute(id: 7), DemoEditRoute(id: 7)]
}

struct DemoProfileScreen: View {
    
    @Environment(Router.self) private var router
    
    var body: some View {
        List {
            Section {
                Button("Open item 1") { router.route(DemoItemRoute(id: 1)) }
            } header: {
                Text("One route, two presentations")
            } footer: {
                Text("Identical call to the one in Library, decided here by DemoProfileScope as a sheet.")
            }
            Section {
                Button("Blocked route — DemoProfileScope rejects it") { router.route(DemoBlockedRoute()) }
            } header: {
                Text("Rejection")
            } footer: {
                Text("A rejection does not bubble up; the root scope never sees the route.")
            }
            Section {
                RouteLink("Settings — passed up to DemoRootScope", route: DemoSettingsRoute())
            } header: {
                Text("Bubbling")
            }
            Section {
                Button("Discard the Library branch") { router.root.discardBranch(for: DemoTabRoute.library) }
            } header: {
                Text("Branches")
            } footer: {
                Text("Switch to Library afterwards: its path and modal are gone.")
            }
            DemoControlsSection()
        }
        .navigationTitle("Profile")
        .safeAreaInset(edge: .bottom) { DemoStateInspector(label: "Profile branch") }
    }
}

// MARK: - Routed screens

struct DemoItemScreen: View {
    
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    
    let id: Int
    let context: RouteContext
    
    private var inspectorLabel: String {
        context.isModalRoot ? "Item \(id) sheet — its own node" : "Item \(id) pushed — still the branch node"
    }
    
    var body: some View {
        List {
            Section {
                Text(context.isModalRoot ? "isModalRoot: true — the toolbar shows a close button." : "isModalRoot: false — pushed, so no close button.")
            } header: {
                Text("Context")
            }
            Section {
                Button("Edit item \(id)") { router.route(DemoEditRoute(id: id)) }
            } header: {
                Text("Presentations from here")
            } footer: {
                Text("Decided by DemoItemScope in the sheet and by DemoLibraryScope when pushed, since a push creates no node.")
            }
            if context.isModalRoot {
                Section {
                    Button("Open item \(id) again") { router.route(DemoItemRoute(id: id)) }
                } header: {
                    Text("presentationBusy")
                } footer: {
                    Text("The route is already in the modal chain, so it is refused instead of presented twice.")
                }
            }
            DemoControlsSection()
        }
        .navigationTitle("Item \(id)")
        .toolbar(content: toolbarContent)
        .safeAreaInset(edge: .bottom) { DemoStateInspector(label: inspectorLabel) }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if context.isModalRoot {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close", systemImage: "xmark") { dismiss() }
            }
        }
    }
}

struct DemoEditScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let id: Int
    let context: RouteContext
    
    var body: some View {
        List {
            Section {
                Text("A sheet presented from within a sheet, on the deepest node of the chain.")
            } header: {
                Text("Modal stacking")
            }
            DemoControlsSection()
        }
        .navigationTitle("Edit \(id)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close", systemImage: "xmark") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) { DemoStateInspector(label: "Edit \(id) sheet — its own node") }
    }
}

struct DemoSettingsScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let context: RouteContext
    
    var body: some View {
        List {
            Section {
                Text("Triggered inside a tab, passed on by that tab's scope and claimed by DemoRootScope.")
            } header: {
                Text("Bubbling")
            }
            Section {
                RouteLink("Settings page", route: DemoSettingsPageRoute())
            } header: {
                Text("Push inside a modal")
            } footer: {
                Text("No scope claims this route; DefaultScope pushes it because that is its default presentation.")
            }
            DemoControlsSection()
        }
        .navigationTitle("Settings")
        .toolbar(content: toolbarContent)
        .safeAreaInset(edge: .bottom) { DemoStateInspector(label: "Settings sheet — its own node") }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if context.isModalRoot {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close", systemImage: "xmark") { dismiss() }
            }
        }
    }
}

struct DemoSettingsPageScreen: View {
    
    var body: some View {
        List {
            Section {
                Text("A push adds to the path of the node it was routed from, so the inspector below still shows the settings sheet's node.")
            } header: {
                Text("Same node, longer path")
            }
            DemoControlsSection()
        }
        .navigationTitle("Settings page")
        .safeAreaInset(edge: .bottom) { DemoStateInspector(label: "Settings sheet — its own node") }
    }
}

// MARK: - Shared controls

struct DemoControlsSection: View {
    
    @Environment(Router.self) private var router
    @Environment(RouterNode.self) private var node
    
    var body: some View {
        Section {
            Button("pop()") { node.pop() }
            Button("popToRoot()") { node.popToRoot() }
            Button("dismissModals(from: 1)") { router.root.dismissModals(from: 1) }
            Button("dismissAll()") { router.root.dismissAll() }
        } header: {
            Text("Controls")
        } footer: {
            Text("pop and popToRoot act on the nearest node; the dismissals act on the root and walk the whole chain.")
        }
    }
}

// MARK: - Inspector

struct DemoStateInspector: View {
    
    @Environment(Router.self) private var router
    @Environment(RouterNode.self) private var node
    
    let label: String
    
    /// - note: Counted by walking ``RouterNode/parent`` upwards, which is how the demo shows that
    /// `@Environment(RouterNode.self)` resolves to a different node inside a modal or a branch.
    private var nestingLevel: Int {
        var level = 0
        var current = node.parent
        while let ancestor = current {
            level += 1
            current = ancestor.parent
        }
        return level
    }
    
    private var selectionDescription: String {
        router.root.selection?.demoDescription ?? "none"
    }
    
    private var pathDescription: String {
        node.path.isEmpty ? "empty" : "\(node.path.count) · " + node.path.map(\.demoDescription).joined(separator: " › ")
    }
    
    private var localModalDescription: String {
        Self.describe(node.modalStack)
    }
    
    private var rootModalDescription: String {
        Self.describe(router.root.modalStack)
    }
    
    private var failureDescription: String {
        router.lastFailure.map { String(describing: $0) } ?? "none"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).bold()
                Spacer()
                Button("Clear failure") { router.lastFailure = nil }
                    .buttonStyle(.borderless)
            }
            row("nesting", "\(nestingLevel)")
            row("path", pathDescription)
            row("modals here", localModalDescription)
            row("root selection", selectionDescription)
            row("root modals", rootModalDescription)
            row("lastFailure", failureDescription)
                .foregroundStyle(router.lastFailure == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))
        }
        .font(.caption2.monospaced())
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.thinMaterial)
        .overlay(alignment: .top) { Divider() }
    }
    
    @ViewBuilder
    private func row(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(key + ":").frame(width: 104, alignment: .leading)
            Text(value).foregroundStyle(.primary)
        }
    }
    
    private static func describe(_ stack: [RouterNode.Presented]) -> String {
        stack.isEmpty ? "none" : stack.map { "\($0.route.demoDescription) \(describe($0.presentation))" }.joined(separator: " › ")
    }
    
    private static func describe(_ presentation: RoutePresentation) -> String {
        switch presentation {
        case .push: "[push]"
        case .sheet(.full): "[sheet .full]"
        case .sheet(.dynamic): "[sheet .dynamic]"
        case .fullScreenCover: "[cover]"
        case .selection: "[selection]"
        }
    }
}

private extension AnyRoute {
    
    var demoDescription: String {
        String(describing: base)
    }
}

#Preview {
    DemoRoutingScene()
}
#endif
