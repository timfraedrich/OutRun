//
//  TextBanner.swift
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

/**
 `TextBanner` is a subclass of `ORBaseBanner` and simply just shows a label with specified text, much like an alert
 */
class TextBanner: ORBaseBanner {
    
    /**
     Initialises an `ORBanner` with a simple label
     */
    init(text: String) {
        
        super.init(customise: { (banner, contentView) in
            
            let label = UILabel(
                text: text,
                textColor: .primaryColor,
                font: .systemFont(ofSize: 16, weight: .semibold),
                numberOfLines: 0
            )
            
            contentView.addSubview(label)
            
            label.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
        }, isDismissable: true)
        
    }
    
    required init?(coder: NSCoder) {
        
        return nil
        
    }
    
}
