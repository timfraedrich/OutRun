//
//  SetupPermissionView.swift
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

class SetupPermissionView: SetupActionView {
    
    let permissionButton: PermissionButton
    
    init(title: String, permissionAction: @escaping (PermissionButton) -> Void, buttonAction: (() -> Void)? = nil) {
        
        self.permissionButton = PermissionButton(action: permissionAction)
        
        super.init(title: title, buttonAction: buttonAction)
        
        self.addSubview(permissionButton)
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }
        self.permissionButton.snp.makeConstraints { (make) in
            make.centerY.right.equalToSuperview()
            make.height.equalTo(24)
        }
        self.button.snp.makeConstraints { (make) in
            make.right.lessThanOrEqualTo(permissionButton.snp.left).offset(-5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
