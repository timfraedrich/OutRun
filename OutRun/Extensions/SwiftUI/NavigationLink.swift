//
//  NavigationLink.swift
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

import SwiftUI

extension NavigationLink {

    init<T: Identifiable, D: View>(
        item: Binding<T?>,
        @ViewBuilder destination: (T) -> D,
        @ViewBuilder label: () -> Label
    ) where Destination == D? {
        
        let isActive = Binding(
            get: { item.wrappedValue != nil },
            set: { value in
                guard !value else { return }
                item.wrappedValue = nil
            }
        )
        self.init(
            destination: item.wrappedValue.map(destination),
            isActive: isActive,
            label: label
        )
    }
}
