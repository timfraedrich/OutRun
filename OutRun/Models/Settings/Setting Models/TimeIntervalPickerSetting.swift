//
//  TimePickerSetting.swift
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

class TimeIntervalPickerSetting: InputViewSetting, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let timeIntervalSelectionAction: ((TimeInterval, Setting) -> Void)?
    var currentHour: Int = 0
    var currentMinute: Int = 0
    var currentSecond: Int = 0
    
    private lazy var picker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        return picker
    }()
    
    init(title: @escaping () -> String, startValue: TimeInterval = 0, timeIntervalSelectionAction: ((TimeInterval, Setting) -> Void)? = nil) {
        
        self.timeIntervalSelectionAction = timeIntervalSelectionAction
        
        super.init(title: title)
        
        self.dummyTextField.inputView = picker
        set(timeInterval: startValue)
        
        let startValue = Int(startValue)
        
        let seconds = startValue % 60
        self.currentSecond = seconds
        self.picker.selectRow(50 * 60 + self.currentSecond, inComponent: 4, animated: false)
        
        let minutes = (startValue - seconds) / 60 % 60
        self.currentMinute = minutes
        self.picker.selectRow(50 * 60 + self.currentMinute, inComponent: 2, animated: false)
        
        let hours = (startValue - seconds - minutes * 60) / 3600
        self.currentHour = hours < 96 ? hours : 96
        self.picker.selectRow(self.currentHour, inComponent: 0, animated: false)
    }
    
    convenience init(title: String, startValue: TimeInterval = 0, timeIntervalSelectionAction: ((TimeInterval, Setting) -> Void)? = nil) {
        self.init(title: { return title }, startValue: startValue, timeIntervalSelectionAction: timeIntervalSelectionAction)
        self.usesClosures = false
    }
    
    func set(timeInterval: TimeInterval) {
        self.tableViewCell.detailTextLabel?.text = CustomMeasurementFormatting.string(forMeasurement: NSMeasurement(doubleValue: timeInterval, unit: UnitDuration.seconds), type: .clock)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 5
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 1, 3:
            return 1
        case 0:
            return 96
        case 2, 4:
            return 100 * 60
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            let value = row % 96
            return String(format: "%02d", value)
        case 2, 4:
            let value = row % 60
            return String(format: "%02d", value)
        default:
            return ":"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            self.currentHour = row
        case 2:
            self.currentMinute = row % 60
        case 4:
            self.currentSecond = row % 60
        default:
            break
        }
        let timeInterval = Double(currentHour * 60 * 60 + currentMinute * 60 + currentSecond)
        set(timeInterval: timeInterval)
        
        guard let action = self.timeIntervalSelectionAction else {
            return
        }
        action(timeInterval, self)
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0, 2, 4:
            return 50
        default:
            return 25
        }
    }
    
}
