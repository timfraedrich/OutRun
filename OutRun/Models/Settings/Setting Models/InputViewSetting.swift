//
//  InputViewSetting.swift
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

class InputViewSetting: NSObject, Setting, KeyboardAvoidanceSetting, UITextFieldDelegate {
    
    var section: SettingSection?
    var usesClosures: Bool
    
    private let titleClosure: () -> String
    
    public var registerForKeyboardAvoidanceClosure: ((UITableViewCell) -> Void)?
    
    lazy var dummyTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.addDoneToolbar()
        return textField
    }()
    
    fileprivate lazy var internalTableViewCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1 , reuseIdentifier: nil)
        cell.backgroundColor = .backgroundColor
        cell.accessoryType = .none
        cell.selectionStyle = .none
        _ = cell.heightAnchor.constraint(equalToConstant: 44)
        cell.textLabel?.textColor = .primaryColor
        cell.textLabel?.text = titleClosure()
        return cell
    }()
    
    var tableViewCell: UITableViewCell {
        get {
            return internalTableViewCell
        }
    }
    
    init(title: @escaping () -> String) {
        self.titleClosure = title
        self.usesClosures = true
        
        super.init()
        
        internalTableViewCell.contentView.addSubview(dummyTextField)
        dummyTextField.snp.makeConstraints { (make) in
            make.height.width.equalTo(0)
        }
    }
    
    convenience init(title: String) {
        self.init(title: { return title })
        self.usesClosures = false
    }
    
    func runSelectAction(controller: SettingsViewController) {
        dummyTextField.becomeFirstResponder()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        registerForKeyboardAvoidanceClosure?(self.tableViewCell)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
    }
    
    func updateClosures() {
        if self.usesClosures {
            DispatchQueue.main.async {
                self.tableViewCell.textLabel?.text = self.titleClosure()
            }
        }
    }
    
}

