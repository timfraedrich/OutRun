//
//  UIImage.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

extension UIImage {
    
    static let plus = UIImage(named: "plus")!.withRenderingMode(.alwaysTemplate)
    static let close = UIImage(named: "close")!.withRenderingMode(.alwaysTemplate)
    static let checkmark = UIImage(named: "checkmark")!.withRenderingMode(.alwaysTemplate)
    static let play = UIImage(named: "play")!.withRenderingMode(.alwaysTemplate)
    static let pause = UIImage(named: "pause")!.withRenderingMode(.alwaysTemplate)
    static let share = UIImage(named: "share")!.withRenderingMode(.alwaysTemplate)
    
    static let setupChart = UIImage(named: "setupChart")!.withRenderingMode(.alwaysTemplate)
    static let setupLock = UIImage(named: "setupLock")!.withRenderingMode(.alwaysTemplate)
    static let setupRoute = UIImage(named: "setupRoute")!.withRenderingMode(.alwaysTemplate)
    
    static let runningGlyph = UIImage(named: "runningGlyph")!
    
    static let tabbarPlus = UIImage(named: "plus tabbar")!.withRenderingMode(.alwaysTemplate)
    static let tabbarSettings = UIImage(named: "settings 23px")!.withRenderingMode(.alwaysTemplate)
    static let tabbarSettingsFilled = UIImage(named: "settings filled 23px")!.withRenderingMode(.alwaysTemplate)
    static let tabbarTimeline = UIImage(named: "timeline 23px")!.withRenderingMode(.alwaysTemplate)
    static let tabbarTimelineFilled = UIImage(named: "timeline filled 23px")!.withRenderingMode(.alwaysTemplate)
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
      let rect = CGRect(origin: .zero, size: size)
      UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
      color.setFill()
      UIRectFill(rect)
      let image = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      guard let cgImage = image?.cgImage else { return nil }
      self.init(cgImage: cgImage)
    }
    
    public func withFillColor(_ fillColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        fillColor.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
}
