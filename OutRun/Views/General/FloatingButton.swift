//
//  FloatingButton.swift
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

class FloatingButton: UIButton {
    
    let action: (FloatingButton) -> Void
    
    init(title: String, action: @escaping (FloatingButton) -> Void) {
        
        self.action = action
        
        super.init(frame: .zero)
        
        self.backgroundColor = .backgroundColor
        self.layer.cornerRadius = 15
        
        self.setTitle(title.uppercased(), for: .normal)
        self.titleLabel?.snp.makeConstraints({ (make) in
            make.left.right.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
            make.height.equalTo(30)
        })
        self.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        self.setTitleColor(.secondaryColor, for: .normal)
        
        self.addTarget(self, action: #selector(performAction), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        self.action = { button in
            return
        }
        super.init(coder: coder)
    }
    
    @objc func performAction() {
        action(self)
    }
    
}
