import SwiftUI

@Observable
class CalendarRouter {
    
    var path: NavigationPath
    
    init(path: NavigationPath = .init()) {
        self.path = path
    }
    
    func reset() {
        path = .init()
    }
}
