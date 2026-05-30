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
