//
//  EditWorkoutPauseController.swift
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

/// WARNING: This class is not functional yet
class EditWorkoutPauseController: UITableViewController {
    
    var editController: EditWorkoutController?
    
    private var startDate: Date {
        return self.editController?.startDate ?? Date.init(timeIntervalSince1970: 0)
    }
    
    private var events: [TempWorkoutEvent] {
        get {
            return self.editController?.pauseResumeEvents ?? []
        } set {
            self.editController?.pauseResumeEvents = newValue.sorted(by: { (event1, event2) -> Bool in
                event1.startDate <= event2.startDate
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard editController != nil else {
            self.dismiss(animated: true)
            return
        }
    }
    
}
