import SwiftUI

@Observable
class SettingsRouter {
    
    var path: NavigationPath
    
    init(path: NavigationPath = .init()) {
        self.path = path
    }
    
    func reset() {
        path = .init()
    }
}
