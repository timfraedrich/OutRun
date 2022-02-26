//
//  StepCounter.swift
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
import CoreMotion
import RxSwift
import RxCocoa

/// A `WorkoutBuilderComponent` for counting the steps taken during a workout
class StepCounter: WorkoutBuilderComponent {
    
    /// The number of steps before the last pause.
    private var stepsBeforeLastPause: Int? = nil
    /// A boolean indicating whether steps should be recorded.
    private var shouldRecord: Bool = false
    /// The pedometer instance used to count the steps.
    private let pedometer: CMPedometer = CMPedometer()
    
    /**
     Starts updating the steps from the provided date until it stops itself.
     - parameter date: the date from which on steps will be recognised
     */
    private func startUpdating(from date: Date) {
        
        guard CMPedometer.isStepCountingAvailable() else {
            insufficientPermissionRelay.accept(LS["Setup.Permission.Motion.Error"])
            return
        }
        
        self.pedometer.startUpdates(from: date) { (data, error) in
            
            guard self.shouldRecord else {
                self.stepsBeforeLastPause = self.stepsRelay.value
                self.pedometer.stopUpdates()
                return
            }
            
            let steps = Int(truncating: data?.numberOfSteps ?? 0) + (self.stepsBeforeLastPause ?? 0)
            self.stepsRelay.accept(steps)
        }
    }
    
    // MARK: - Dataflow
    
    /// The `DisposeBag` used for binding to the workout builder.
    private let disposeBag = DisposeBag()
    
    /// The relay to publish that insufficient permission was granted to the workout builder.
    private let insufficientPermissionRelay = PublishRelay<String>()
    /// The relay to publish the taken steps to the workout builder.
    private let stepsRelay = BehaviorRelay<Int?>(value: nil)
    
    // MARK: Binders
    
    /// Binds status updates from the `WorkoutBuilder` to this component.
    private var statusBinder: Binder<WorkoutBuilder.Status> {
        Binder(self) { `self`, newStatus in
            self.shouldRecord = newStatus == .recording
            
            guard newStatus == .recording else { return }
            self.startUpdating(from: Date())
        }
    }
    
    /// Binds reset events to this component.
    private var onResetBinder: Binder<ORWorkoutInterface?> {
        Binder(self) { `self`, snapshot in
            self.stepsRelay.accept(snapshot?.steps)
            self.stepsBeforeLastPause = snapshot?.steps
            self.shouldRecord = snapshot != nil
            
            if snapshot != nil { // continue
                self.startUpdating(from: Date())
            } else {
                self.pedometer.stopUpdates()
            }
        }
    }
    
    // MARK: WorkoutBuilderComponent
    
    public required init(builder: WorkoutBuilder) {
        self.bind(builder: builder)
    }
    
    func bind(builder: WorkoutBuilder) {
        
        let input = Input(
            insufficientPermission: insufficientPermissionRelay.asBackgroundObservable(),
            steps: stepsRelay.asBackgroundObservable()
        )
        
        let output = builder.tranform(input)
        
        output.status
            .bind(to: statusBinder)
            .disposed(by: disposeBag)
        
        output.onReset
            .bind(to: onResetBinder)
            .disposed(by: disposeBag)
    }
}
