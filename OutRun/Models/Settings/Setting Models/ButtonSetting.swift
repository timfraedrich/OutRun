//
//  ButtonSetting.swift
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

class ButtonSetting: TitleSetting {
    
    private let buttonColorClosure: () -> UIColor
    private let isEnabledClosure: () -> Bool
    
    fileprivate lazy var internalTableViewCell: UITableViewCell = {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = .backgroundColor
        cell.textLabel?.textColor = isEnabledClosure() ? buttonColorClosure() : .secondaryColor
        cell.selectionStyle = .none
        cell.textLabel?.text = self.title
        return cell
    }()
    
    init(title: @escaping () -> String, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil, buttonColor: @escaping () -> UIColor = { return .accentColor }, isEnabled: @escaping () -> Bool = { return true }) {
        self.buttonColorClosure = buttonColor
        self.isEnabledClosure = isEnabled
        super.init(title: title, selectAction: selectAction == nil ? nil : { (setting, controller, cell) in
            if isEnabled() {
                selectAction!(setting, controller, cell)
            }
        })
    }
    
    convenience init(title: String, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil, buttonColor: UIColor = .accentColor, isEnabled: Bool = true) {
        self.init(title: { return title }, selectAction: selectAction, buttonColor: { return buttonColor }, isEnabled: { return isEnabled })
        self.usesClosures = false
    }
    
    override var tableViewCell: UITableViewCell {
        get {
            return internalTableViewCell
        }
    }
    
    override func updateClosures() {
        if self.usesClosures {
            DispatchQueue.main.async {
                super.updateClosures()
                self.tableViewCell.textLabel?.textColor = self.isEnabledClosure() ? self.buttonColorClosure() : .secondaryColor
            }
        }
    }
    
}
