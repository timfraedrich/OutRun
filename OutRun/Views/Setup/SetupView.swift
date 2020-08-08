//
//  SetupView.swift
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

class SetupView: UIView {
    
    let titleLabel = UILabel(
        textColor: .primaryColor,
        font: .systemFont(ofSize: 24, weight: .bold),
        numberOfLines: 0,
        textAlignment: .center
    )
    
    let textLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .medium),
        numberOfLines: 0,
        textAlignment: .center
    )
    
    init(title: String, text: String, customViewClosure closure: ((UIView) -> UIView)? = nil)  {
        super.init(frame: .zero)
        
        self.titleLabel.text = title
        self.textLabel.text = text
        
        self.addSubview(titleLabel)
        self.addSubview(textLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        textLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
        }
        
        guard let customViewClosure = closure else {
            return
        }
        
        let custom = customViewClosure(UIView())
        
        self.addSubview(custom)
        
        custom.snp.makeConstraints { (make) in
            make.top.equalTo(textLabel.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
