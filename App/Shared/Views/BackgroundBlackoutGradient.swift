//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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
