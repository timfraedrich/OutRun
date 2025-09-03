//
//  PickerSetting.swift
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

class PickerSetting<Object: CustomStringConvertible>: InputViewSetting, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let selectionAction: ((Object, Setting) -> Void)?
    let possibleValues: [Object]
    
    private lazy var picker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        return picker
    }()
    
    init(title: @escaping () -> String, selectedIndex: Int = 0, possibleValues: [Object], selectionAction: ((Object, Setting) -> Void)? = nil) {
        
        self.selectionAction = selectionAction
        self.possibleValues = possibleValues
        
        super.init(title: title)

        if let initialValue = possibleValues.safeValue(for: selectedIndex) {
            self.setDateString(for: initialValue)
        }
        
        self.dummyTextField.inputView = picker
        self.picker.selectRow(selectedIndex >= possibleValues.count ? possibleValues.count - 1 : selectedIndex, inComponent: 0, animated: true)
    }
    
    convenience init(title: String, selectedIndex: Int = 0, possibleValues: [Object], selectionAction: ((Object, Setting) -> Void)? = nil) {
        self.init(title: { return title }, selectedIndex: selectedIndex, possibleValues: possibleValues, selectionAction: selectionAction)
        self.usesClosures = false
    }
    
    func setDateString(for object: Object) {
        self.tableViewCell.detailTextLabel?.text = object.description
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.possibleValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.possibleValues[row].description
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let value = possibleValues[row]
        self.setDateString(for: value)
        guard let action = selectionAction else {
            return
        }
        action(value, self)
    }
    
}
