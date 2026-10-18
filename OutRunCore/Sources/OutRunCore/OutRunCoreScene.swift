//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
