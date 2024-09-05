//
//  WorkoutCompletionActionHandler.swift
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

class WorkoutCompletionActionHandler {
    
    /// A `TempWorkout` object to be saved, discarded or handed back to a `WorkoutBuilder` by this class
    private var snapshot: TempWorkout
    
    /// A weak reference to a `WorkoutBuilder` to continue the workout
    private weak var builder: WorkoutBuilder?
    
    /// If `true` the `WorkoutCompletionActionHandler` did already perform an action, so no additional action should be taken
    private var didPerformAction: Bool = false
    
    /**
     Initialises the `WorkoutCompletionActionHandler` with the needed snapshot of an `TempWorkout`
     - parameter snapshot: a `TempWorkout` object to be saved, discarded or continued
     */
    public init(snapshot: TempWorkout, builder: WorkoutBuilder) {
        
        self.snapshot = snapshot
        self.builder = builder
        
    }
    
    /**
     Displays a dismissable view over the current `UIWindow` that gives the user options on what to do with the just recorded workout, saving it automatically after a certain time
     */
    public func display() {
    // Create a new UIWindow overlay
    guard let window = UIApplication.shared.keyWindow else { return }
    
    // Create a container view for the pop-up
    let popupView = UIView()
    popupView.backgroundColor = .white
    popupView.layer.cornerRadius = 12
    popupView.translatesAutoresizingMaskIntoConstraints = false
    window.addSubview(popupView)
    
    // Set up Auto Layout constraints for the popup view
    NSLayoutConstraint.activate([
        popupView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
        popupView.centerYAnchor.constraint(equalTo: window.centerYAnchor),
        popupView.widthAnchor.constraint(equalToConstant: 300),
        popupView.heightAnchor.constraint(equalToConstant: 200)
    ])
    
    // "Continue" button
    let continueButton = UIButton(type: .system)
    continueButton.setTitle("Continue", for: .normal)
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    continueButton.addTarget(self, action: #selector(self.continueWorkout), for: .touchUpInside)
    continueButton.isAccessibilityElement = true
    continueButton.accessibilityLabel = "Continue workout"
    continueButton.accessibilityIdentifier = "continueButton"

    // "Discard" button
    let discardButton = UIButton(type: .system)
    discardButton.setTitle("Discard", for: .normal)
    discardButton.translatesAutoresizingMaskIntoConstraints = false
    discardButton.addTarget(self, action: #selector(self.discardWorkout), for: .touchUpInside)
    discardButton.isAccessibilityElement = true
    discardButton.accessibilityLabel = "Discard workout"
    discardButton.accessibilityIdentifier = "discardButton"

    // "Save" button
    let saveButton = UIButton(type: .system)
    saveButton.setTitle("Save", for: .normal)
    saveButton.translatesAutoresizingMaskIntoConstraints = false
    saveButton.addTarget(self, action: #selector(self.saveWorkout), for: .touchUpInside)
    saveButton.isAccessibilityElement = true
    saveButton.accessibilityLabel = "Save workout"
    saveButton.accessibilityIdentifier = "saveButton"
    
    popupView.addSubview(continueButton)
    popupView.addSubview(discardButton)
    popupView.addSubview(saveButton)

    
    NSLayoutConstraint.activate([
        continueButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
        continueButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 20),
        
        discardButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
        discardButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 10),
        
        saveButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
        saveButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -20)
    ])
}
    
    /**
     Saves the workout if no other action was already performed
     */
    public func saveWorkout() {
        
        guard !self.didPerformAction else {
            return
        }
        
        self.didPerformAction = true
        
        DataManager.saveWorkout(object: self.snapshot) { (success, error, workout) in
            // would normally show save success banner
        }
        
    }
    
    /**
     Continues the workout if no other action was already performed and the builder is still active
     */
    public func continueWorkout() {
        
        guard !self.didPerformAction else {
            return
        }
        
        self.didPerformAction = true
        
        var messageKey = ""
        
        if let builder = self.builder {
            
            builder.continueWorkout(from: self.snapshot)
            
            messageKey = "NewWorkoutCompletion.Continue.Success"
            
        } else {
            
            messageKey = "NewWorkoutCompletion.Continue.Error"
            
        }
        
        // would normally show continuing or error banner
        
        print("Imagine the workout would continue")
        
    }
    
    /**
     Discards the workout if no other action was already performed
     */
    public func discardWorkout() {
        
        guard !self.didPerformAction else {
            return
        }
        
        self.didPerformAction = true
        
    }
    
}
