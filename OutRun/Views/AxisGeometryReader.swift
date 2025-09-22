import SwiftUI

struct AxisGeometryReader<Content: View>: View {
    
    @State private var size: CGFloat = SizeKey.defaultValue
    
    var axis: Axis = .horizontal
    var alignment: Alignment = .center
    let content: (_ size: CGFloat) -> Content
    
    var body: some View {
        content(size)
            .frame(
                maxWidth:  axis == .horizontal ? .infinity : nil,
                maxHeight: axis == .vertical   ? .infinity : nil,
                alignment: alignment)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: SizeKey.self,
                        value: axis == .horizontal ? proxy.size.width : proxy.size.height
                    )
                }
            )
            .onPreferenceChange(SizeKey.self) { size = $0 }
    }
    
    private struct SizeKey: PreferenceKey {
        
        static var defaultValue: CGFloat { 10 }
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
