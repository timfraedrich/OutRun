import Charts
import SwiftUI

/// Positions a selection bubble above the chart, horizontally at the selected date, drawn over surrounding content.
/// Optionally hosts the scrubbing and tap gestures for charts that do not use native selection.
struct ChartSelectionOverlay<Bubble: View>: View {
    
    let proxy: ChartProxy
    let selectedDate: Date?
    let handlesGestures: Bool
    @Binding var selection: Date?
    let dateRange: ClosedRange<Date>
    let onTap: (() -> Void)?
    @ViewBuilder let bubble: () -> Bubble
    
    var body: some View {
        GeometryReader { geometry in
            let plotFrame = proxy.plotFrame.map { geometry[$0] } ?? .zero
            ZStack(alignment: .topLeading) {
                if handlesGestures {
                    gestureLayer(plotFrame: plotFrame)
                }
                if let selectedDate, let x = proxy.position(forX: selectedDate) {
                    BubbleLayout(anchorX: plotFrame.minX + x) {
                        bubble()
                    }
                    .allowsHitTesting(false)
                }
            }
        }
    }
    
    @ViewBuilder
    private func gestureLayer(plotFrame: CGRect) -> some View {
        let layer = Color.clear
            .contentShape(.rect)
            .gesture(ChartInteractionGesture(.hold()) { phase, location in
                switch phase {
                case .changed:
                    guard let date: Date = proxy.value(atX: location.x - plotFrame.minX) else { return }
                    selection = min(max(date, dateRange.lowerBound), dateRange.upperBound)
                case .ended:
                    selection = nil
                }
            })
        if let onTap {
            layer.gesture(ChartInteractionGesture(.tap) { _, _ in onTap() })
        } else {
            layer
        }
    }
    
    private struct BubbleLayout: Layout {
        
        let anchorX: CGFloat
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            proposal.replacingUnspecifiedDimensions()
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            guard let subview = subviews.first else { return }
            let size = subview.sizeThatFits(.unspecified)
            let x = min(max(bounds.minX + anchorX - size.width / 2, bounds.minX), bounds.maxX - size.width)
            let y = bounds.minY - size.height - Spacing.extraSmall.rawValue
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
        }
    }
}
