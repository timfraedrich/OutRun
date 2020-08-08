//
//  UIColor.swift
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

extension UIColor {
    
    static let accentColor = UIColor(named: "accentColor") ?? .orange
    static let accentColorSwapped = UIColor(named: "accentColorSwapped") ?? UIColor.orange.withAlphaComponent(0.9)
    static let primaryColor = UIColor(named: "primaryColor") ?? .black
    static let secondaryColor = UIColor(named: "secondaryColor") ?? UIColor(white: 118/255, alpha: 1)
    static let backgroundColor = UIColor(named: "backgroundColor") ??  UIColor.white
    static let foregroundColor = UIColor(named: "foregroundColor") ?? UIColor(white: 248/255, alpha: 1)
    static let tableViewSeparator = UIColor(white: 0.5, alpha: 0.25)
    
}
