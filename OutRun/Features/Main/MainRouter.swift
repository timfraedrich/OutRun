import SwiftUI

@Observable
class MainRouter {
    
    var sheets: [MainSheetDestination]
    var currentSheet: MainSheetDestination? {
        get { sheets.last }
        set {
            if let newValue {
                sheets.append(newValue)
            } else if !sheets.isEmpty {
                sheets.removeLast()
            }
        }
    }
    
    init(sheets: [MainSheetDestination] = []) {
        self.sheets = sheets
    }
}
