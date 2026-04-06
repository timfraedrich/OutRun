import SwiftUI

extension HFlowLayout {
    
    init(verticalSpacing: Spacing, alignment: HorizontalAlignment = .leading) {
        self.init(verticalSpacing: verticalSpacing.rawValue, alignment: alignment)
    }
    
    init(horizontalSpacing: Spacing, alignment: HorizontalAlignment = .leading) {
        self.init(horizontalSpacing: horizontalSpacing.rawValue, alignment: alignment)
    }
    
    init(horizontalSpacing: Spacing, verticalSpacing: Spacing, alignment: HorizontalAlignment = .leading) {
        self.init(horizontalSpacing: horizontalSpacing.rawValue, verticalSpacing: verticalSpacing.rawValue, alignment: alignment)
    }
}
