//
//  SelectionSetting.swift
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

class SelectionSetting: TitleSubTitleSetting {
    
    var isSelected: Bool {
        return isSelectedClosure()
    }
    private let isSelectedClosure: () -> Bool
    
    init(title: @escaping () -> String, subTitle: @escaping () -> String = { return "" }, isSelected: @escaping () -> Bool, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil) {
        self.isSelectedClosure = isSelected
        let action: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = { (setting, controller, cell) in
            selectAction?(setting, controller, cell)
            setting.refresh()
        }
        super.init(title: title, subTitle: subTitle, selectAction: action)
        self.tableViewCell.accessoryType = self.isSelected ? .checkmark : .none
    }
    
    convenience init(title: String, subTitle: String = "", isSelected: @escaping () -> Bool, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil) {
        self.init(title: { return title }, subTitle: { return subTitle }, isSelected: isSelected, selectAction: selectAction)
        self.usesClosures = false
    }
    
    override var tableViewCell: UITableViewCell {
        get {
            return super.tableViewCell
        }
    }
    
    override func updateClosures() {
        DispatchQueue.main.async {
            self.tableViewCell.accessoryType = self.isSelected ? .checkmark : .none
            if self.usesClosures {
                self.tableViewCell.detailTextLabel?.text = self.subTitle
                self.tableViewCell.textLabel?.text = self.title
            }
        }
    }
    
}
