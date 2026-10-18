//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
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

import OutRunCore
import SwiftData
import SwiftUI

struct CacheSettingsScene: View {
    
    @State private var cacheSize: Int = StaticWorkoutMapService.cacheSize
    @State private var clearCacheError: Error?
    
    var body: some View {
        List {
            LabeledContent("cache_settings_maps_size", value: cacheSize.formatted(.byteCount(style: .file)))
            Button("cache_settings_clear_maps_action", role: .destructive, action: clearCache)
                .errorPopover($clearCacheError)
                .foregroundStyle(.tint)
                .tint(.red)
        }
        .safeAreaPadding(.top, .regular)
        .navigationTitle("cache")
    }
    
    private func clearCache() {
        Task {
            do {
                try StaticWorkoutMapService.clearCache()
                cacheSize = StaticWorkoutMapService.cacheSize
            } catch {
                clearCacheError = error
            }
        }
    }
}
