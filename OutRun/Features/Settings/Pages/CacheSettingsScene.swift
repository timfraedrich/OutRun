import OutRunCore
import SwiftData
import SwiftUI

struct CacheSettingsScene: View {
    
    @State private var cacheSize: Int = StaticWorkoutMapService.cacheSize
    @State private var clearCacheError: Error?
    
    var body: some View {
        List {
            LabeledContent("Map Cache Size", value: cacheSize.formatted(.byteCount(style: .file)))
            Button("Clear Map Cache", role: .destructive, action: clearCache)
                .errorPopover($clearCacheError)
                .foregroundStyle(.tint)
                .tint(.red)
        }
        .navigationTitle("Cache")
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
