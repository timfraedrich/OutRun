//
//  WorkoutShareAlert.swift
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

class WorkoutShareAlert: UIAlertController {
    
    convenience init(controller: UIViewController, workout: Workout) {
        
        let orBackupOption: (title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?) = (
            title: LS["WorkoutShareAlert.OutRunBackup"],
            style: .default,
            action: { action in
                ShareManager.exportBackupAlertAction(forWorkouts: [workout], controller: controller)
            }
        )
        
        let gpxOption: (title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?) = (
            title: LS["WorkoutShareAlert.GPXExport"],
            style: .default,
            action: { action in
                ShareManager.exportGPXAlertAction(for: workout, on: controller)
            }
        )
        
        let cancel: (title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?) = (
            title: LS["Cancel"],
            style: .cancel,
            action: nil
        )
        
        self.init(
            title: LS["WorkoutShareAlert.Title"],
            message: LS["WorkoutShareAlert.Message"],
            preferredStyle: .actionSheet,
            options: [
                orBackupOption,
                gpxOption,
                cancel
            ]
        )
        
        
    }
    
}
