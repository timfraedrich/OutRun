//
//  SetupSwitchView.swift
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

class SetupSwitchView: SetupActionView {
    
    let switchActionClosure: (Bool) -> Void
    
    let `switch`: UISwitch = {
        let swit = UISwitch()
        swit.onTintColor = .accentColor
        return swit
    }()
    
    init(title: String, isOn: Bool, switchAction: @escaping (Bool) -> Void, buttonAction: (() -> Void)? = nil) {
        
        self.switchActionClosure = switchAction
        
        super.init(title: title, buttonAction: buttonAction)
        
        self.switch.isOn = isOn
        self.switch.addTarget(self, action: #selector(switchActionSelector(sender:)), for: .valueChanged)
        
        self.addSubview(self.switch)
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }
        self.switch.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        self.button.snp.makeConstraints { (make) in
            make.right.lessThanOrEqualTo(self.switch.snp.left).offset(-5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func switchActionSelector(sender: UISwitch) {
        switchActionClosure(sender.isOn)
    }
    
}
