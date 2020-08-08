//
//  SetupTextFieldView.swift
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

class SetupTextFieldView: SetupActionView, UITextFieldDelegate {
    
    let textFieldActionClosure: (String) -> Void
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .clear
        textField.textColor = .primaryColor
        textField.layer.cornerRadius = 10
        textField.textAlignment = .right
        textField.setPaddingPoints(10, 10)
        textField.clipsToBounds = true
        textField.font = .systemFont(ofSize: 16)
        textField.adjustsFontForContentSizeCategory = true
        
        textField.addDoneToolbar()
        
        return textField
    }()
    
    let behindLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 16)
    )
    
    init(title: String, placeholder: String? = nil, initialText: String? = nil, keyboardType: UIKeyboardType = .default, textBehindTextField: String? = nil, textFieldAction: @escaping (String) -> Void, buttonAction: (() -> Void)? = nil) {
        
        self.textFieldActionClosure = textFieldAction
        
        super.init(title: title, buttonAction: buttonAction)
        
        self.textField.text = initialText
        self.textField.placeholder = placeholder
        self.textField.delegate = self
        self.textField.keyboardType = keyboardType
        
        self.addSubview(self.textField)
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }
        self.textField.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2.5)
            make.height.equalTo(30)
        }
        
        if textBehindTextField == nil {
            
            self.textField.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
            }
            
        } else {
            
            self.behindLabel.text = textBehindTextField
            
            self.addSubview(behindLabel)
            
            behindLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(textField)
                make.right.equalToSuperview()
                make.left.equalTo(self.textField.snp.right).offset(5)
            }
            
        }
        
        self.button.snp.makeConstraints { (make) in
            make.right.lessThanOrEqualTo(textField.snp.left).offset(-5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            textFieldActionClosure(text)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
}
