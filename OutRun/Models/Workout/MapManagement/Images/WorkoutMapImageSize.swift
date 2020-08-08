//
//  WorkoutMapImageSize.swift
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

enum WorkoutMapImageSize {
    case list, stats
    
    var rawSize: CGSize {
        switch self {
        case .list:
            let ultimateScreenWidth = UIScreen.main.bounds.width
            let width = (ultimateScreenWidth - 50) / 2
            return CGSize(width: width, height: 120)
        case .stats:
            let ultimateScreenWidth = UIScreen.main.bounds.width
            let width = (ultimateScreenWidth - 40)
            return CGSize(width: width, height: 300)
        }
    }
    
    var identifier: String {
        switch self {
        case .list:
            return "list"
        case .stats:
            return "stats"
        }
    }
}
