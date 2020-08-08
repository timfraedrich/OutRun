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
    
    var value: NSMeasurement? {
        didSet {
            self.setData(for: self.value)
        }
    }
    
    private let headlineLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .bold)
    )
    
    private let informationLabel = UILabel(
        text: "--",
        font: .systemFont(ofSize: 25, weight: .heavy)
    )
    
    init(title: String, measurement: NSMeasurement?, isAltitude: Bool = false) {
        super.init(frame: .zero)
        
        self.headlineLabel.text = title.uppercased()
        self.setData(for: measurement, isAltitude: isAltitude)
        
        self.addSubview(headlineLabel)
        self.addSubview(informationLabel)
        
        headlineLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        informationLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.headlineLabel.snp.bottom)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
    
    private func setData(for measurement: NSMeasurement?, isAltitude: Bool = false) {
        
        guard let newValue = measurement else {
            self.informationLabel.text = "--"
            return
        }
        
        let type = CustomMeasurementFormatting.FormattingMeasurementType(for: newValue.unit, asClock: true, asAltitude: isAltitude)
        self.informationLabel.text = CustomMeasurementFormatting.string(forMeasurement: newValue, type: type, rounding: .twoDigits)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
