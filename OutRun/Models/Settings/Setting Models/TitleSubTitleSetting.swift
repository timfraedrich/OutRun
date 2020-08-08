//
//  TitleSubTitleSetting.swift
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

class TitleSubTitleSetting: TitleSetting {
    
    var subTitle: String {
        return subTitleClosure()
    }
    
    private let subTitleClosure: () -> String
    
    fileprivate lazy var internalTableViewCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        
        cell.backgroundColor = .backgroundColor
        cell.textLabel?.textColor = .primaryColor
        cell.detailTextLabel?.textColor = .secondaryColor
        
        cell.accessoryType = self.doesRedirect ? .disclosureIndicator : .none
        cell.detailTextLabel?.text = self.subTitle
        cell.textLabel?.text = self.title
        
        return cell
    }()
    
    init(title: @escaping () -> String, subTitle: @escaping () -> String, doesRedirect: @escaping () -> Bool = { return false }, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil) {
        self.subTitleClosure = subTitle
        super.init(title: title, doesRedirect: doesRedirect, selectAction: selectAction)
    }
    
    convenience init(title: String, subTitle: String, doesRedirect: Bool = false, selectAction: ((Setting, SettingsViewController, UITableViewCell) -> Void)? = nil) {
        self.init(title: { return title }, subTitle: { return subTitle }, doesRedirect: { return doesRedirect }, selectAction: selectAction)
        self.usesClosures = false
    }
    
    convenience init(title: @escaping () -> String, subTitle: @escaping () -> String, _ settingsModel: SettingsModel) {
        self.init(title: title, subTitle: subTitle, doesRedirect: { return true }, selectAction: { (setting, controller, cell) in
            
            let newSettingsController = SettingsViewController()
            newSettingsController.settingsModel = settingsModel
            controller.notifyOfPresentation(newSettingsController)
            controller.show(newSettingsController, sender: controller)
            
        })
    }
    
    convenience init(title: String, subTitle: String, _ settingsModel: SettingsModel) {
        self.init(title: { return title }, subTitle: { return subTitle }, settingsModel)
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
                self.tableViewCell.accessoryType = self.doesRedirect ? .disclosureIndicator : .none
                self.tableViewCell.detailTextLabel?.text = self.subTitle
                self.tableViewCell.textLabel?.text = self.title
            }
        }
    }
    
}
