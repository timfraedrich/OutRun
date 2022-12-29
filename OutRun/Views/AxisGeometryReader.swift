//
//  AxisGeometryReader.swift
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

struct AxisGeometryReader<Content: View>: View {
    
    @State private var size: CGFloat = SizeKey.defaultValue
    
    var axis: Axis = .horizontal
    var alignment: Alignment = .center
    let content: (_ size: CGFloat) -> Content
    
    var body: some View {
        content(size)
            .frame(
                maxWidth:  axis == .horizontal ? .infinity : nil,
                maxHeight: axis == .vertical   ? .infinity : nil,
                alignment: alignment)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: SizeKey.self,
                        value: axis == .horizontal ? proxy.size.width : proxy.size.height
                    )
                }
            )
            .onPreferenceChange(SizeKey.self) { size = $0 }
    }
    
    private struct SizeKey: PreferenceKey {
        
        static var defaultValue: CGFloat { 10 }
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
   
