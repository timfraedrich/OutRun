//
//  LabelledDataView.swift
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

class LabelledDataView: UIView, SmallStatView {
    
    fileprivate let titleLabel = UILabel(
        text: "",
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .bold)
    )
    
    fileprivate let dataLabel = UILabel(
        text: "--",
        font: .systemFont(ofSize: 25, weight: .heavy)
    )
    
    init(title: String = "") {
        super.init(frame: .zero)
        
        self.titleLabel.text = title
        
        self.addSubview(titleLabel)
        self.addSubview(dataLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        dataLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
