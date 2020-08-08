//
//  SettingSection.swift
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

import Foundation

class SettingSection {
    
    var model: SettingsModel?
    
    public let title: String
    public let message: String?
    public let settings: [Setting]
    
    public init(title: String, message: String? = nil, settings: [Setting]) {
        self.title = title
        self.message = message
        self.settings = settings
        settings.forEach { (setting) in
            var set = setting
            set.section = self
        }
    }
    
    public var count: Int {
        get {
            return self.settings.count
        }
    }
    
    func refresh() {
        model?.refresh()
    }
    
    /// unsafely returns a `Setting` for the given `itemIndex`
    public subscript(_ itemIndex: Int) -> Setting {
        return self.settings[itemIndex]
    }
    
    /// safely returns a `Setting` for the given `itemIndex`
    public func safeSetting(itemIndex: Int) -> Setting? {
        guard self.settings.indices.contains(itemIndex) else {
            return nil
        }
        return self[itemIndex]
    }
    
}
