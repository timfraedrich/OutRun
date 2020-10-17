//
//  DeleteWorkoutView.swift
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

class DeleteWorkoutView: WorkoutActionView {
    
    init(controller: UIViewController, workout: Workout) {
        super.init(title: { return LS["Delete"] }, color: .systemRed, controller: controller, workout: workout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func action(button: UIButton) {
        let alert = UIAlertController(
            title: LS["WorkoutDeletion.Title"],
            message: LS["WorkoutDeletion.Message"],
            preferredStyle: .alert,
            options: [
                (
                    title: LS["Delete"],
                    style: .destructive,
                    action: { _ in
                        
                        DispatchQueue.main.async {
                            
                            func deleteWorkout() {
                                DataManager.delete(workout: self.workout) { success in
                                    
                                    self.controller.endLoading(completion: {
                                        
                                        if success {
                                            guard let controller = self.controller as? DetailViewController else {
                                                return
                                            }
                                            controller.close()
                                        } else {
                                            self.controller.displayError(withMessage: LS["WorkoutDeletion.Error.Message"])
                                        }
                                    })
                                }
                            }
                            
                            if self.workout.healthKitUUID.value != nil {
                                
                                let appleHealthAlert = UIAlertController(
                                    title: LS["WorkoutDeletion.AppleHealth.Title"],
                                    message: LS["WorkoutDeletion.AppleHealth.Message"],
                                    preferredStyle: .alert,
                                    options: [
                                        (
                                            title: LS["Delete"],
                                            style: .destructive,
                                            action: { _ in
                                                HealthStoreManager.deleteHealthWorkout(fromWorkout: self.workout) { (success) in
                                                    
                                                    if !success {
                                                        self.controller.displayError(withMessage: LS["WorkoutDeletion.Error.AppleHealth.Message"], dismissAction: { _ in
                                                            deleteWorkout()
                                                        })
                                                    } else {
                                                        deleteWorkout()
                                                    }
                                                }
                                            }
                                        ),
                                        (
                                            title: LS["Keep"],
                                            style: .cancel,
                                            action: { _ in
                                                deleteWorkout()
                                            }
                                        )
                                    ]
                                )
                                
                                self.controller.present(appleHealthAlert, animated: true, completion: nil)
                                
                            } else {
                                deleteWorkout()
                            }
                            
                        }
                    }
                ),
                (
                    title: LS["Cancel"],
                    style: .cancel,
                    action: nil
                )
            ]
        )
        self.controller.present(alert, animated: true, completion: nil)
    }
    
}
