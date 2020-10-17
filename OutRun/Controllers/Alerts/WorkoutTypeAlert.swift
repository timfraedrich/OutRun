//
//  WorkoutTypeAlert.swift
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

class WorkoutTypeAlert: UIAlertController {
    
    convenience init(action: @escaping (Workout.WorkoutType) -> Void, manualAction: (() -> Void)? = nil) {
        
        func typeOption(for type: Workout.WorkoutType) -> (title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?) {
            (
                title: type.description,
                style: .default,
                action: { _ in
                    action(type)
                }
            )
        }
        
        var options: [(title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?)] = [
            typeOption(for: .running),
            typeOption(for: .walking),
            typeOption(for: .hiking),
            typeOption(for: .cycling),
            typeOption(for: .skating)
        ]
        
        if let manualAction = manualAction {
            options.append(
                (
                    title: LS["NewWorkoutAlert.EnterManually"],
                    style: .default,
                    action: { _ in
                        manualAction()
                    }
                )
            )
        }
        
        options.append(
            (
                title: LS["Cancel"],
                style: .cancel,
                action: nil
            )
        )
        
        self.init(
            title: LS["NewWorkoutAlert.Title"],
            message: LS["NewWorkoutAlert.Message"],
            preferredStyle: .alert,
            options: options
        )
    }
    
    func present(on controller: UIViewController) {
        controller.present(self, animated: true, completion: nil)
    }
    
}
