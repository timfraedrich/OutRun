import UIKit

extension UIColor {
    
    var rgbValue: Int {
        var (red, blue, green, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (.zero, .zero, .zero, .zero)
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
    }
    
    var hexRepresentation: String {
        String(format: "%06x", rgbValue)
    }
}
