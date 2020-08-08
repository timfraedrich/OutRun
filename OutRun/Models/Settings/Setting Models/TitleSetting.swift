//
//  TitleSetting.swift
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

class TitleSetting: Setting {
    
    var section: SettingSection?
    var usesClosures: Bool
    
    var title: String {
        return titleClosure()
    }
    var doesRedirect: Bool {
        return doesRedirectClosure()
    }
    
    private let titleClosure: () -> String
    private let doesRedirectClosure: () -> Bool
    private let selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)?
    
    fileprivate lazy var internalTableViewCell: UITableViewCell = {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        cell.backgroundColor = .backgroundColor
        cell.textLabel?.textColor = .primaryColor
        cell.textLabel?.text = title
        cell.accessoryType = doesRedirect ? .disclosureIndicator : .none
        
        return cell
    }()
    
    init(title: @escaping () -> String, doesRedirect: @escaping () -> Bool = { return false }, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil) {
        self.titleClosure = title
        self.doesRedirectClosure = doesRedirect
        self.selectAction = selectAction
        self.usesClosures = true
    }
    
    convenience init(title: String, doesRedirect: Bool = false, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil) {
        self.init(title: { return title }, doesRedirect: { return doesRedirect }, selectAction: selectAction)
        self.usesClosures = false
    }
    
    convenience init(title: String, _ settingsModel: SettingsModel) {
        self.init(title: title, doesRedirect: true, selectAction: { (setting, controller, cell) in
            
            let newSettingsController = SettingsViewController()
            newSettingsController.settingsModel = settingsModel
            controller.notifyOfPresentation(newSettingsController)
            controller.show(newSettingsController, sender: controller)
            
        })
    }
    
    var tableViewCell: UITableViewCell {
        get {
            return internalTableViewCell
        }
    }
    
    func runSelectAction(controller: SettingsViewController) {
        guard let selectAction = selectAction else {
            return
        }
        selectAction(self, controller, tableViewCell)
    }
    
    func updateClosures() {
        if self.usesClosures {
            DispatchQueue.main.async {
                self.tableViewCell.textLabel?.text = self.title
                self.tableViewCell.accessoryType = self.doesRedirect ? .disclosureIndicator : .none
            }
        }
    }
    
}
