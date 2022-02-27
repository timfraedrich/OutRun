//
//  EditWorkoutController.swift
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

class EditWorkoutController: SettingsViewController {
    
    var workout: ORWorkoutInterface?
    var controller: UIViewController?
    
    var workoutType = Workout.WorkoutType.running
    var distance: Double?
    var steps: Int?
    var startDate = Date()
    var duration: TimeInterval = 0
    var isRace = false
    var comment: String? = nil
    
    lazy var addItem = UIBarButtonItem(title: LS["Save"], style: .done, target: self, action: #selector(saveWorkout))
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let workout = workout {
            self.workoutType = workout.workoutType
            self.distance = workout.distance / 1000
            self.steps = workout.steps
            self.startDate = workout.startDate
            self.duration = workout.endDate.distance(to: workout.startDate)
            self.isRace = workout.isRace
            self.comment = workout.comment
            self.addItem.isEnabled = true
        }
        
        let cancelItem = UIBarButtonItem(title: LS["Cancel"], style: .plain, target: self, action: #selector(closeSelector))
        self.navigationItem.leftBarButtonItem = cancelItem
        self.navigationItem.rightBarButtonItem = addItem
        self.addItem.isEnabled = false
        
        self.settingsModel = SettingsModel(
            title: self.workout == nil ? LS["EditWorkoutController.NewWorkout"] : LS["EditWorkoutController.EditWorkout"],
            sections: [
                SettingSection(
                    title: "Info",
                    settings: [
                        PickerSetting(
                            title: LS["Workout.Type"],
                            selectedIndex: self.workoutType.rawValue,
                            possibleValues: [Workout.WorkoutType.running, .walking, .cycling],
                            selectionAction: { (workoutType, setting) in
                                self.workoutType = workoutType
                                self.validateData()
                            }
                        ),
                        TextInputSetting(
                            title: LS["Workout.Distance"],
                            textFieldText: {
                                let value = UserPreferences.distanceMeasurementType.convert(fromValue: self.distance ?? 0, toPrefered: true)
                                return CustomNumberFormatting.string(from: value, fractionDigits: 2)
                            }(),
                            keyboardType: .decimalPad,
                            textBehindTextField: CustomMeasurementFormatting.string(forUnit: UserPreferences.distanceMeasurementType.safeValue, short: true),
                            textFieldValueAction: { (newValue, setting) in
                                guard let distance = CustomNumberFormatting.number(from: newValue) else {
                                    return
                                }
                                let newValue = UserPreferences.distanceMeasurementType.convert(fromValue: distance, toPrefered: false, rounded: false)
                                self.distance = newValue
                                self.validateData()
                            }
                        ),
                        TextInputSetting(
                            title: self.workoutType == .cycling ? LS["Workout.Strokes"] : LS["Workout.Steps"],
                            textFieldText: {
                                return self.steps != nil ? CustomNumberFormatting.string(from: Double(self.steps!), fractionDigits: 0) : nil
                            }(),
                            textFieldPlaceholder: LS["NotSet"],
                            keyboardType: .numberPad,
                            textFieldValueAction: { (newValue, setting) in
                                let newSteps = CustomNumberFormatting.number(from: newValue)
                                self.steps = newSteps != nil ? Int(newSteps!) : nil
                                self.validateData()
                            }
                        ),
                        DatePickerSetting(
                            title: LS["Workout.StartDate"],
                            date: self.startDate,
                            pickerMode: .dateAndTime,
                            dateSelectionAction: { (date, setting) in
                                self.startDate = date
                                self.validateData()
                            }
                        ),
                        TimeIntervalPickerSetting(
                            title: LS["Workout.Duration"],
                            startValue: self.duration,
                            timeIntervalSelectionAction: { (timeInterval, setting) in
                                self.duration = timeInterval
                                self.validateData()
                            }
                        ),
                        SwitchSetting(
                            title: LS["Workout.Race"],
                            isSwitchOn: self.isRace,
                            switchToggleAction: { (newValue, setting) in
                                self.isRace = newValue
                                self.validateData()
                            }
                        )
                    ]
                ),
                // MARK: not yet implemented
                /*SettingSection(
                    title: LS["Workout.Pauses"],
                    settings: [
                        TitleSetting(
                            title: LS["EditWorkoutController.EditPauses"],
                            doesRedirect: true,
                            selectAction: { (settings, controller, cell) in
                                let pauseContoller = EditWorkoutPauseController()
                                pauseContoller.editController = self
                                controller.show(pauseContoller, sender: nil)
                            }
                        )
                    ]
                ),*/
                SettingSection(
                    title: LS["Workout.Comment"],
                    settings: [
                        TextViewSetting(
                            text: self.comment,
                            placeholder: LS["Workout.Comment"],
                            textViewValueAction: { (newValue, setting) in
                                self.comment = newValue == "" ? nil : newValue
                                self.validateData()
                            }
                        )
                    ]
                )
            ]
        )
        
        super.viewDidLoad()
    }
    
    func validateData() {
        if self.distance != nil && self.duration != 0 && self.startDate.addingTimeInterval(self.duration) <= Date() {
            self.addItem.isEnabled = true
        } else {
            self.addItem.isEnabled = false
        }
    }
    
    @objc func saveWorkout() {
        
        let endDate = self.startDate.addingTimeInterval(self.duration)
        let distanceInMeters = (self.distance ?? 0) * 1000
        
        if let workout = self.workout {
            
            var tempWorkout = TempWorkout(from: workout)
            tempWorkout.workoutType = workoutType
            tempWorkout.startDate = startDate
            tempWorkout.endDate = endDate
            tempWorkout.distance = distanceInMeters
            tempWorkout.steps = steps
            tempWorkout.isRace = isRace
            tempWorkout.comment = comment
            
            DataManager.updateWorkout(object: tempWorkout) { success, error, workout in
                guard let workout = workout, error == nil else {
                    self.displayError(withMessage: LS["EditWorkoutController.SaveWorkout.Error"])
                    return
                }
                
                func customClose() {
                    self.close {
                        guard let oldController = self.controller else {
                            self.showWorkoutController(workout: workout)
                            return
                        }
                        
                        oldController.dismiss(animated: true) {
                            self.showWorkoutController(workout: workout)
                        }
                    }
                }
                
                if UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                    HealthStoreManager.updateHealthWorkout(for: workout) { error in
                        if error != nil {
                            if let uuid = workout.healthKitUUID {
                                DataManager.removeHealthReference(reference: uuid)
                            }
                            self.displayError(withMessage: LS["EditWorkoutController.AlterWorkout.AppleHealth.Error"]) { action in
                                customClose()
                            }
                        } else {
                            customClose()
                        }
                    }
                } else {
                    customClose()
                }
            }
            
        } else {
            
            let newWorkout = NewWorkout(
                workoutType: workoutType,
                distance: distanceInMeters,
                steps: steps,
                startDate: startDate,
                endDate: endDate,
                isRace: isRace,
                comment: comment,
                isUserModified: true,
                finishedRecording: true,
                heartRates: [],
                routeData: [],
                pauses: [],
                workoutEvents: []
            )
            
            DataManager.saveWorkout(object: newWorkout) { success, error, workout in
                guard let workout = workout, error == nil else {
                    self.displayError(withMessage: LS["EditWorkoutController.SaveWorkout.Error"])
                    return
                }
                
                if UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                    HealthStoreManager.saveHealthWorkout(for: workout) { error, healthWorkout in
                        if error != nil {
                            self.displayError(withMessage: LS["EditWorkoutController.SaveWorkout.AppleHealth.Error"]) { (_) in
                                self.close()
                            }
                        } else {
                            self.closeAndShowController(for: workout)
                        }
                    }
                } else {
                    self.closeAndShowController(for: workout)
                }
            }
        }
        
    }
    
    func showWorkoutController(workout: Workout) {
        if let mainController = TabBarController.lastCurrent {
            let workoutController = WorkoutViewController()
            workoutController.workout = workout
            mainController.showDetailViewController(workoutController, sender: self)
        }
    }
    
    func closeAndShowController(for workout: Workout) {
        self.close {
            self.showWorkoutController(workout: workout)
        }
    }
    
    func close(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: completion)
        }
    }
    
    @objc func closeSelector() {
        self.close(completion: nil)
    }
    
}
