//
//  MeasurementUserPreference.swift
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

import Foundation

public class MeasurementUserPreference<UnitType> where UnitType: Unit {
    
    private let base: UserPreference.Optional<Int>
    public let possibleValues: [UnitType]
    public let bigUnits: Bool
    
    public init(key: String, possibleValues: [UnitType], bigUnits: Bool = true) {
        guard !possibleValues.isEmpty else {
            fatalError("MeasurementUserPreference - Tried to initialise without providing at least one possible value")
        }
        self.base = UserPreference.Optional<Int>(key: key)
        self.possibleValues = possibleValues
        self.bigUnits = bigUnits
    }
    
    public var value: UnitType? {
        get { possibleValues.safeValue(for: base.value ?? -1) }
        set { base.value = possibleValues.firstIndex { $0 == newValue } }
    }
    
    public var safeValue: UnitType {
        value ?? standardLocalValue ?? possibleValues[0]
    }
    
    public var standardValue: UnitType? {
        let Unit = (UnitType.self as? StandardizedUnit.Type)
        return (bigUnits ? Unit?.standardBigUnit : Unit?.standardUnit) as? UnitType
    }
    
    public var standardLocalValue: UnitType? {
        let Unit = (UnitType.self as? StandardizedUnit.Type)
        return (bigUnits ? Unit?.standardBigLocalUnit : Unit?.standardSmallLocalUnit) as? UnitType
    }
    
    public func convert(fromValue value: Double, toPrefered: Bool, rounded: Bool = true) -> Double {
        guard let standardUnit = self.standardValue else { return -1 }
        let preferedUnit = self.safeValue
        let sourceUnit = toPrefered ? standardUnit : preferedUnit
        let targetUnit = toPrefered ? preferedUnit : standardUnit
        let value = UnitConversion.conversion(of: value, from: sourceUnit, to: targetUnit)
        return rounded ? ((value * 100).rounded() / 100) : value
    }
    
    func setting(forTitle title: String) -> Setting {
        
        let settingsModel = SettingsModel(title: title, sections: [
            SettingSection(
                title: LS["Settings.UnitPick.Headline"],
                message: LS["Settings.UnitPick.Message"],
                settings: {
                    var settings = [SelectionSetting]()
                    
                    if let standardUnit = self.standardLocalValue {
                        let selectSetting = SelectionSetting(
                            title: LS["Standard"] + " (\(MeasurementFormatter().string(from: standardUnit)))",
                            subTitle: "",
                            isSelected: { () -> Bool in
                                return self.value == nil
                            }
                        ) { (setting, controller, cell) in
                            self.value = nil
                        }
                        settings.append(selectSetting)
                    }
                    
                    for unit in self.possibleValues {
                        let selectSetting = SelectionSetting(
                            title: MeasurementFormatter().string(from: unit),
                            subTitle: "",
                            isSelected: { () -> Bool in
                                return self.value == unit
                            }
                        ) { (setting, controller, cell) in
                            self.value = unit
                        }
                        settings.append(selectSetting)
                    }
                    return settings
                }()
            )
        ])
        
        return TitleSubTitleSetting(
            title: title,
            subTitle: MeasurementFormatter().string(from: self.safeValue),
            settingsModel
        )
        
    }
    
    public func delete() {
        self.base.delete()
    }
    
}
