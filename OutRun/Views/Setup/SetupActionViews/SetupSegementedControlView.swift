//
//  SetupSegementedControlView.swift
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

class SetupSegementedControlView: SetupActionView {

    let segmentedControlActionClosure: (Int) -> Void
    
    let segmentedControl: UISegmentedControl = {
        let seg = UISegmentedControl()
        if #available(iOS 13.0, *) {
            seg.tintColor = .accentColor
            seg.styleLikeIOS12()
        }
        return seg
    }()
    
    var currentValue: Int {
        get {
            return segmentedControl.selectedSegmentIndex
        }
    }
    
    init(title: String, segmentTitles: [String], initialSegment: Int, segmentedControlAction: @escaping (Int) -> Void, buttonAction: (() -> Void)? = nil) {
        
        self.segmentedControlActionClosure = segmentedControlAction
        
        super.init(title: title, buttonAction: buttonAction)
        
        for (index, title) in segmentTitles.enumerated() {
            self.segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        self.segmentedControl.selectedSegmentIndex = initialSegment
        self.segmentedControl.addTarget(self, action: #selector(segmentedControlActionSelector(sender:)), for: .valueChanged)
        
        self.addSubview(self.segmentedControl)
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }
        self.segmentedControl.snp.makeConstraints { (make) in
            make.centerY.right.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(30)
        }
        self.button.snp.makeConstraints { (make) in
            make.right.lessThanOrEqualTo(segmentedControl.snp.left).offset(-5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func segmentedControlActionSelector(sender: UISegmentedControl) {
        segmentedControlActionClosure(sender.selectedSegmentIndex)
    }

}
