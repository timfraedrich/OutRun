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

import UIKit

extension UIColor {
    
    var rgbValue: Int {
        var (red, blue, green, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (.zero, .zero, .zero, .zero)
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Int)((red * 255).rounded()) << 16 | (Int)((green * 255).rounded()) << 8 | (Int)((blue * 255).rounded() * 255) << 0
    }
    
    var hexRepresentation: String {
        String(format: "%06x", rgbValue)
    }
}
