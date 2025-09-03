//
//  CornerView.swift
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

import SwiftUI

public struct CornerView<Content: View>: View {
    
    private let corner: Corner
    private let content: () -> Content
    
    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if !corner.left { Spacer() }
            VStack(alignment: .leading, spacing: 0) {
                if !corner.top { Spacer() }
                content()
                if corner.top { Spacer() }
            }
            if corner.left { Spacer() }
        }
    }
    
    public init(corner: Corner, @ViewBuilder content: @escaping () -> Content) {
        self.corner = corner
        self.content = content
    }
    
    public enum Corner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        
        var top: Bool { self == .topLeft || self == .topRight }
        var left: Bool { self == .topLeft || self == .bottomLeft}
    }
}
