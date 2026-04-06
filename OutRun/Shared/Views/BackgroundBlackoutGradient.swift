import SwiftUI

struct BackgroundBlackoutGradient<ForegroundStyle: ShapeStyle>: View {
    
    private let startPoint: UnitPoint
    private let endPoint: UnitPoint
    private let foregroundStyle: ForegroundStyle
    private var maskColors: [Color] { [.clear, .black] }
    
    var body: some View {
        Rectangle().foregroundStyle(foregroundStyle).mask {
            LinearGradient(colors: maskColors, startPoint: startPoint, endPoint: endPoint)
        }
    }
    
    init(startPoint: UnitPoint, endPoint: UnitPoint, foregroundStyle: ForegroundStyle = .background) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.foregroundStyle = foregroundStyle
    }
}
