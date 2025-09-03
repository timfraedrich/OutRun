//
//  AltitudeManagement.swift
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
import Combine
import CombineExt

/// A `WorkoutBuilderComponent` for measuring changes in altitude and recording them for the refinement of route data
public class AltitudeManagement: WorkoutBuilderComponent {
    
    /// An instance of `CMAltimeter` to measure releative altitude changes.
    private let altimeter = CMAltimeter()
    
    /**
     Starts updating the relative altitude data
     */
    private func startUpdating() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        
        self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (altitudeData, error) in
            guard let altitudeData = altitudeData else { return }
            let differenceInMeters = Double(truncating: altitudeData.relativeAltitude)
            let altitude = AltitudeSample(timestamp: Date(), altitude: differenceInMeters)
            self.altitudesRelay.accept(self.altitudesRelay.value + [altitude])
        }
    }
    
    // MARK: - Dataflow
    
    /// An Array of cancellables for binding to the workout builder.
    private var cancellables: [AnyCancellable] = []
    
    /// The relay to publish that insufficient permission was granted to the workout builder.
    private let insufficientPermissionRelay = PassthroughRelay<String>()
    /// The relay to publish the altitudes recorded to the workout builder.
    private let altitudesRelay = CurrentValueRelay<[AltitudeSample]>([])
    
    // MARK: Binders
    
    /// Binds the current and previous status of the workout builder to this component.
    private var statusBinder: ((WorkoutBuilder.Status?, WorkoutBuilder.Status)) -> Void {
        return { [weak self] value in
            guard let self else { return }
            let (oldStatus, newStatus) = value
            guard newStatus.isActiveStatus && !(oldStatus?.isActiveStatus ?? false) else { return }
            self.startUpdating()
        }
    }
    
    /// Binds reset events to this component.
    private var onResetBinder: (ORWorkoutInterface?) -> Void {
        return { [weak self] snapshot in
            guard let self else { return }
            if snapshot != nil { // continue
                self.startUpdating()
            } else { // reset
                self.altimeter.stopRelativeAltitudeUpdates()
                self.altitudesRelay.accept([])
            }
        }
    }
    
    // MARK: WorkoutBuilderComponent
    
    public required init(builder: WorkoutBuilder) {
        self.bind(builder: builder)
    }
    
    public func bind(builder: WorkoutBuilder) {
        
        let input = Input(
            insufficientPermission: insufficientPermissionRelay.asBackgroundPublisher(),
            altitudes: altitudesRelay.asBackgroundPublisher()
        )
        
        let output = builder.tranform(input)
        
        output.status.withPrevious().sink(receiveValue: statusBinder).store(in: &cancellables)
        output.onReset.sink(receiveValue: onResetBinder).store(in: &cancellables)
    }
    
    // MARK: - AltitudeSample
    
    /// A data type to provide altitude updates to other components.
    public struct AltitudeSample {
        /// The timestamp at which the altitude was recorded.
        public let timestamp: Date
        /// The relative value of the altitude.
        public let altitude: Double
    }
}
