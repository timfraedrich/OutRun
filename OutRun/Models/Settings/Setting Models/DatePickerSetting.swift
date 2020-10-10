//
//  DatePickerSetting.swift
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

class DatePickerSetting: InputViewSetting {
    
    let dateSelectionAction: ((Date, Setting) -> Void)?
    
    private let initialDate: Date
    
    private let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.date = Date()
        datePicker.maximumDate = Date()
        datePicker.minuteInterval = 1
        return datePicker
    }()
    
    init(title: @escaping () -> String, date: Date, pickerMode: UIDatePicker.Mode, dateSelectionAction: ((Date, Setting) -> Void)? = nil) {
        
        self.dateSelectionAction = dateSelectionAction
        self.initialDate = date
        
        super.init(title: title)
        
        self.setDateString(for: date)
        
        datePicker.setDate(date, animated: false)
        datePicker.datePickerMode = pickerMode
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.addTarget(self, action: #selector(newDateSelected(datePicker:)), for: .valueChanged)
        self.dummyTextField.inputView = datePicker
    }
    
    convenience init(title: String, date: Date, pickerMode: UIDatePicker.Mode, dateSelectionAction: ((Date, Setting) -> Void)? = nil) {
        self.init(title: { return title }, date: date, pickerMode: pickerMode, dateSelectionAction: dateSelectionAction)
        self.usesClosures = false
    }
    
    func setDateString(for date: Date) {
        self.tableViewCell.detailTextLabel?.text = CustomTimeFormatting.fullDateString(forDate: date)
    }
    
    @objc func newDateSelected(datePicker: UIDatePicker) {
        
        self.setDateString(for: datePicker.date)
        guard let action = dateSelectionAction else {
            return
        }
        action(datePicker.date, self)
        
    }
    
}
