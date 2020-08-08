//
//  HKImportObjectCell.swift
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

class HKImportObjectCell: UITableViewCell {
    
    let queryObject: HKWorkoutQueryObject
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .foregroundColor
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        return view
    }()
    
    let dateLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .bold)
    )
    
    let timeLabel = UILabel(font: .systemFont(ofSize: 22, weight: .heavy))
    
    let typeLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .bold),
        textAlignment: .right
    )
    
    let distanceLabel = UILabel(
        font: .systemFont(ofSize: 22, weight: .heavy),
        textAlignment: .right
    )
    
    let durationLabel = UILabel(
        font: .systemFont(ofSize: 22, weight: .heavy),
        textAlignment: .right
    )
    
    init(queryObject: HKWorkoutQueryObject) {
        
        self.queryObject = queryObject
        
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none
        self.backgroundColor = .backgroundColor
        
        self.addSubview(containerView)
        
        containerView.snp.makeConstraints { (make) in
            make.height.equalTo(60)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        
        containerView.addSubview(dateLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(typeLabel)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(durationLabel)
        
        dateLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(10)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(dateLabel.snp.bottom)
            make.bottom.equalToSuperview().offset(-10)
        }
        typeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(10)
            make.left.greaterThanOrEqualTo(dateLabel.snp.right).offset(10)
        }
        durationLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(typeLabel.snp.bottom)
            make.bottom.equalToSuperview().offset(-10)
        }
        distanceLabel.snp.makeConstraints { (make) in
            make.right.equalTo(durationLabel.snp.left).offset(-10)
            make.top.equalTo(typeLabel.snp.bottom)
            make.bottom.equalToSuperview().offset(-10)
            make.left.greaterThanOrEqualTo(timeLabel).offset(10)
        }
        
        dateLabel.text = CustomTimeFormatting.dayString(forDate: queryObject.startDate).uppercased()
        timeLabel.text = CustomTimeFormatting.timeString(forDate: queryObject.startDate)
        typeLabel.text = queryObject.type.description.uppercased()
        durationLabel.text = CustomMeasurementFormatting.string(forMeasurement: queryObject.duration, type: .time, rounding: .wholeNumbers)
        distanceLabel.text = CustomMeasurementFormatting.string(forMeasurement: queryObject.distance, type: .distance, rounding: .oneDigit)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
