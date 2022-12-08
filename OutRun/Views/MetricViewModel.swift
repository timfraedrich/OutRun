//
//  MetricViewModel.swift
//
//  OutRun
//  Copyright (C) 2022 Tim Fraedrich <timfraedrich@icloud.com>
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

import Combine
import Foundation
import SwiftUI

class MetricViewModel: ObservableObject {
    
    @Published private(set) var title: String
    @Published private(set) var value: String
    let size: Size
    
    init(title: Published<String>, value: Published<String>, size: Size = .big) {
        self._title = title
        self._value = value
        self.size = size
    }
    
    convenience init(title: Published<String>, value: String, size: Size = .big) {
        self.init(title: title, value: Published(initialValue: value), size: size)
    }
    
    convenience init(title: String, value: Published<String>, size: Size = .big) {
        self.init(title: Published(initialValue: title), value: value, size: size)
    }
    
    convenience init(title: String, value: String, size: Size = .big) {
        self.init(title: Published(initialValue: title), value: Published(initialValue: value), size: size)
    }
    
    enum Size {
        case small
        case big
        
        var titleFont: Font {
            switch self {
            case .small:
                return .footnote
            case .big:
                return .subheadline
            }
        }
        
        var valueFont: Font {
            switch self {
            case .small:
                return .body
            case .big:
                return .title2
            }
        }
    }
}
