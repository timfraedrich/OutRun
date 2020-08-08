//
//  TextViewSetting.swift
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

class TextViewSetting: NSObject, Setting, KeyboardAvoidanceSetting, UITextViewDelegate {
    
    var section: SettingSection?
    var usesClosures: Bool
    
    private let placeholderClosure: () -> String
    private let textViewValueAction: ((String?, Setting) -> Void)?
    
    public var registerForKeyboardAvoidanceClosure: ((UITableViewCell) -> Void)?
    
    lazy var placeholderLabel = UILabel(
        text: self.placeholderClosure(),
        textColor: .secondaryColor,
        font: .preferredFont(forTextStyle: .body),
        numberOfLines: 1,
        textAlignment: .left
    )
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .backgroundColor
        textView.textColor = .primaryColor
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textAlignment = .left
        textView.addDoneToolbar()
        textView.delegate = self
        textView.contentInset = UIEdgeInsets(top: -(UIFont.preferredFont(forTextStyle: .body).pointSize / 2), left: -5, bottom: 0, right: -5)
        return textView
    }()
    
    fileprivate lazy var internalTableViewCell: UITableViewCell = {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        cell.backgroundColor = .backgroundColor
        cell.accessoryType = .none
        cell.selectionStyle = .none
        
        self.placeholderLabel.isHidden = !self.textView.text.isEmpty
        
        cell.contentView.addSubview(textView)
        cell.contentView.addSubview(placeholderLabel)
        
        let safeArea = cell.layoutMarginsGuide
        
        self.textView.snp.makeConstraints { (make) in
            make.edges.equalTo(safeArea)
            make.height.equalTo(100)
        }
        self.placeholderLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(safeArea)
        }
        
        return cell
    }()
    
    init(text: String? = nil, placeholder: @escaping () -> String, textViewValueAction: ((String?, Setting) -> Void)? = nil) {
        
        self.placeholderClosure = placeholder
        self.textViewValueAction = textViewValueAction
        self.usesClosures = true
        
        super.init()
        
        self.textView.text = text
    }
    
    convenience init(text: String? = nil, placeholder: String, textViewValueAction: ((String?, Setting) -> Void)? = nil) {
        self.init(text: text, placeholder: { return placeholder }, textViewValueAction: textViewValueAction)
        self.usesClosures = false
    }
    
    var tableViewCell: UITableViewCell {
        get {
            internalTableViewCell
        }
    }
    
    func runSelectAction(controller: SettingsViewController) {
        self.textView.becomeFirstResponder()
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        registerForKeyboardAvoidanceClosure?(self.tableViewCell)
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let valueAction = self.textViewValueAction {
            valueAction(textView.text, self)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func updateClosures() {
        if self.usesClosures {
            DispatchQueue.main.async {
                self.placeholderLabel.text = self.placeholderClosure()
            }
        }
    }
    
}
