//
//  WorkoutBuilderTypeView.swift
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

class WorkoutBuilderTypeView: UIView {
    
    let typeLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 12, weight: .bold)
    )
    
    init(type: Workout.WorkoutType) {
        super.init(frame: .zero)
        
        self.backgroundColor = .backgroundColor
        self.layer.cornerRadius = 15
        
        snp.makeConstraints { (make) in
            make.height.equalTo(30)
        }
        
        self.typeLabel.text = type.description.uppercased()
        
        self.addSubview(typeLabel)
        
        typeLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
