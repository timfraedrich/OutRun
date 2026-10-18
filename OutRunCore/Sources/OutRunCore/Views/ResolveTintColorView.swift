//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import SwiftUI
import UIKit

private class ResolveTintColorUIView: UIView {

    private var oldHexValue: String?
    private let onResolve: (CGColor) -> Void

    init(onResolve: @escaping (CGColor) -> Void) {
        self.onResolve = onResolve
        super.init(frame: .zero)
        self.tintAdjustmentMode = .normal
        observeForegroundTransitions()
        updateColor()
    }

    required init?(coder: NSCoder) {
        self.onResolve = { _ in }
        super.init(coder: coder)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Traits are only meaningful once attached to a real window.
        updateColor()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        guard !isRenderingForSnapshot else { return }
        updateColor()
    }

    /// True while UIKit re-renders the scene in the opposite appearance to
    /// prepare app-switcher snapshots. That pass flips the style and flips
    /// back, so the resolved color is transient and must not be published.
    private var isRenderingForSnapshot: Bool {
        if let scene = window?.windowScene {
            return scene.activationState == .background
                || scene.activationState == .unattached
        }
        return UIApplication.shared.applicationState == .background
    }

    private func observeForegroundTransitions() {
        // A genuine appearance change can happen while we're backgrounded and
        // ignoring updates, so re-resolve unconditionally on the way back in.
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func handleWillEnterForeground() {
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

public struct ResolveTintColorView: UIViewRepresentable {
    
    private let onResolve: (CGColor) -> Void
    
    public init(onResolve: @escaping (CGColor) -> Void) {
        self.onResolve = onResolve
    }
    
    public func makeUIView(context: Context) -> some UIView {
        ResolveTintColorUIView(onResolve: onResolve)
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {}
}
