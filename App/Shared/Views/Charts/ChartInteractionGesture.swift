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

/// A chart gesture backed by a UIKit recognizer so that it can coexist with an enclosing scroll view. Touches that are meant to scroll the
/// page are never claimed: a hold fails as soon as the finger moves and a horizontal drag fails when the movement is mostly vertical.
struct ChartInteractionGesture: UIGestureRecognizerRepresentable {
    
    private let kind: Kind
    private let action: (Phase, CGPoint) -> Void
    
    init(_ kind: Kind, action: @escaping (Phase, CGPoint) -> Void) {
        self.kind = kind
        self.action = action
    }
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    
    func makeUIGestureRecognizer(context: Context) -> UIGestureRecognizer {
        let recognizer: UIGestureRecognizer
        switch kind {
        case .tap:
            recognizer = UITapGestureRecognizer()
        case .hold(let minimumDuration):
            let longPressRecognizer = UILongPressGestureRecognizer()
            longPressRecognizer.minimumPressDuration = minimumDuration
            recognizer = longPressRecognizer
        case .horizontalDrag:
            recognizer = UIPanGestureRecognizer()
        }
        recognizer.delegate = context.coordinator
        return recognizer
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UIGestureRecognizer, context: Context) {
        let location = context.converter.localLocation
        switch (kind, recognizer.state) {
        case (.tap, .ended):
            action(.ended, location)
        case (.tap, _):
            break
        case (_, .began), (_, .changed):
            action(.changed, location)
        case (_, .ended), (_, .cancelled), (_, .failed):
            action(.ended, location)
        default:
            break
        }
    }
    
    enum Kind {
        case tap
        case hold(minimumDuration: TimeInterval = 0.2)
        case horizontalDrag
    }
    
    enum Phase {
        case changed
        case ended
    }
    
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = panRecognizer.velocity(in: panRecognizer.view)
            return abs(velocity.x) > abs(velocity.y)
        }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            guard !(gestureRecognizer is UITapGestureRecognizer) else { return false }
            return otherGestureRecognizer.view is UIScrollView
        }
    }
}
