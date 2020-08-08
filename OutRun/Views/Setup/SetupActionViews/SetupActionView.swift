//
//  SetupActionView.swift
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

/// This class is not finished and only meant to be used as a superclass
class SetupActionView: UIView {

    let buttonActionClosure: (() -> Void)?
    
    lazy var button: UIButton = {
        let button = UIButton()
        button.setTitleColor(.accentColor, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    init(title: String, buttonAction: (() -> Void)? = nil) {
        
        self.buttonActionClosure = buttonAction ?? nil
        
        super.init(frame: .zero)
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: buttonAction != nil ? .bold : .medium)
        button.setTitle(title, for: .normal)
        if buttonAction != nil {
            button.setTitleColor(.secondaryColor, for: .disabled)
            button.addTarget(self, action: #selector(buttonActionSelector), for: .touchUpInside)
        } else {
            button.setTitleColor(.primaryColor, for: .disabled)
            button.isEnabled = false
        }
        
        self.addSubview(button)
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }
        
        button.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonActionSelector() {
        guard let buttonClosure = self.buttonActionClosure else {
            return
        }
        buttonClosure()
    }

}
