import SwiftUI
import UIKit

private class ResolveTintColorUIView: UIView {
    
    private var oldHexValue: String?
    private let onResolve: (CGColor) -> Void
    
    init(onResolve: @escaping (CGColor) -> Void) {
        self.onResolve = onResolve
        super.init(frame: .zero)
        self.tintAdjustmentMode = .normal
        updateColor()
    }
    
    required init?(coder: NSCoder) {
        self.onResolve = { _ in }
        super.init(coder: coder)
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColor()
    }
    
    private func updateColor() {
        let resolvedColor = tintColor.resolvedColor(with: traitCollection)
        let hexValue = resolvedColor.hexRepresentation
        guard hexValue != oldHexValue else { return }
        self.oldHexValue = hexValue
        DispatchQueue.main.async {
            self.onResolve(resolvedColor.cgColor)
        }
    }
}

struct ResolveTintColorView: UIViewRepresentable {
    
    private let onResolve: (CGColor) -> Void
    
    init(onResolve: @escaping (CGColor) -> Void) {
        self.onResolve = onResolve
    }
    
    func makeUIView(context: Context) -> some UIView {
        ResolveTintColorUIView(onResolve: onResolve)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
