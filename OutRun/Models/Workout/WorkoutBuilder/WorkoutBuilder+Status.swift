//
//  WorkoutBuilder+Status.swift
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
import UIKit

extension WorkoutBuilder {
    
    /**
     Enumaration of the different kind of status the `WorkoutBuilder` can take on
     */
    enum Status {
        
        /// indicating that the `WorkoutBuilder` is neither recording nor ready to do so, but instead waiting for all components to be ready
        case waiting
        /// indicating that the `WorkoutBuilder` is ready to record a workout
        case ready
        /// indicating that the `WorkoutBuilder` is recording a workout at the moment
        case recording
        /// indicating that the `WorkoutBuilder` was manually paused by the user, data is still supposed to be recorded in the background and the workout might be resumed at any point in time
        case paused
        /// indicating that the `WorkoutBuilder` was paused by the automatic pause detection, it should act as if it was manually paused, which a user should still be able to do in this scenario
        case autoPaused
        
        /// a localised title for the status
        var title: String {
            switch self {
            case .waiting:
                return LS["WorkoutBuilder.Status.Waiting"]
            case .ready:
                return LS["WorkoutBuilder.Status.Ready"]
            case .recording:
                return LS["WorkoutBuilder.Status.Recording"]
            case .paused:
                return LS["WorkoutBuilder.Status.Paused"]
            case .autoPaused:
                return LS["WorkoutBuilder.Status.AutoPaused"]
            }
            
        }
        
        /// a color representing the status
        var color: UIColor {
            switch self {
            case .waiting:
                return .yellow
            case .ready:
                return .green
            case .recording:
                return .red
            case .paused, .autoPaused:
                return .systemGray
            }
        }
        
        /// a boolean indicating whether the status is a paused status
        var isPausedStatus: Bool {
            return [.paused, .autoPaused].contains(self)
        }
        
        /// a boolean indicating whether the status is an active status meaning data is recorded while one of these status is the current one
        var isActiveStatus: Bool {
            return [.recording, .paused, .autoPaused].contains(self)
        }
    }
    
}
