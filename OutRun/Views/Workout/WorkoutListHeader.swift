//
//  WorkoutListHeader.swift
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

class WorkoutListHeader: UIView {
    
    let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.accentColor.withAlphaComponent(0.25)
        return view
    }()
    
    let label = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 16, weight: .bold)
    )

    init(title: String) {
        super.init(frame: .zero)
        self.backgroundColor = .backgroundColor
        
        self.label.text = title
        
        self.addSubview(lineView)
        self.addSubview(label)
        
        lineView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(18)
            make.width.equalTo(4)
        }
        
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(lineView.snp.right).offset(18)
            make.right.equalToSuperview().offset(20)
            make.height.equalTo(30)
        }
    }
    
    convenience init(dayIdentifier: String) {
        self.init(title: CustomTimeFormatting.dayString(forIdentifier: dayIdentifier) ?? "ERROR")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
