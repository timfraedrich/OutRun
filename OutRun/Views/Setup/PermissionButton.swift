//
//  PermissionButton.swift
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

class PermissionButton: UIView {
    
    let actionClosure: (PermissionButton) -> Void
    var successState = false
    
    let label = UILabel(
        text: LS["Grant"].uppercased(),
        textColor: .backgroundColor,
        font: .systemFont(ofSize: 12, weight: .bold)
    )
    
    let checkmarkIcon: UIImageView = {
        let image = UIImageView(image: .checkmark)
        image.tintColor = .white
        image.contentMode = .scaleAspectFit
        image.alpha = 0
        return image
    }()
    
    init(action: @escaping (PermissionButton) -> Void) {
        
        self.actionClosure = action
        
        super.init(frame: .zero)
        
        self.backgroundColor = .secondaryColor
        self.layer.cornerRadius = 12
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(actionSelector))
        self.addGestureRecognizer(gestureRecognizer)
        
        self.addSubview(label)
        self.addSubview(checkmarkIcon)
        
        label.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
            make.width.equalTo(label.intrinsicContentSize.width)
        }
        checkmarkIcon.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func transitionState(to success: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            switch success {
            case true:
                self.label.alpha = 0
                self.checkmarkIcon.alpha = 1
                self.backgroundColor = .accentColor
            case false:
                self.label.alpha = 1
                self.checkmarkIcon.alpha = 0
                self.backgroundColor = .secondaryColor
            }
        }, completion: nil)
    }
    
    @objc func actionSelector() {
        actionClosure(self)
    }
    
}
