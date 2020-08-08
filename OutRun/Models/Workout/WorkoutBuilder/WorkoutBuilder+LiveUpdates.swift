//
//  WorkoutBuilder+LiveUpdates.swift
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
import CoreLocation

extension WorkoutBuilder {
    
    // MARK: Supporting Functions
    
    /**
     Performs a live update action on the main thread only if appropriate looking at background update suspension and if the `WorkoutBuilder` even has a delegate
     - parameter closure: the update action that is supposed to be performed
     */
    private func performIfAppropriate(closure: @escaping (WorkoutBuilderDelegate) -> Void) {
        
        if self.shouldPerformBackgroundUpdates, let delegate = self.delegate {
            
            DispatchQueue.main.async {
                closure(delegate)
            }
            
        }
        
    }
    
    /**
     Gets the start date relative ranges for pauses used to determine if something was recorded inside a pause
     - parameter referenceDate: the date the range intervals should be relative to
     - returns: start date relative ranges for pauses
     */
    private func getPauseRanges(with referenceDate: Date) -> [ClosedRange<Double>] {
        
        var pauseRanges: [ClosedRange<Double>] = []
        
        for (index, event) in self.manualPauseEvents.enumerated() where event.realEventType == .pause {
            
            if let nextEvent = self.manualPauseEvents.safeValue(for: index + 1), nextEvent.realEventType == .resume, event.startDate < nextEvent.startDate {
                
                let startInterval = event.startDate.distance(to: referenceDate)
                let endInterval = nextEvent.startDate.distance(to: referenceDate)
                
                pauseRanges.append(startInterval...endInterval)
                
            }
            
        }
        
        // after continuing a workout there could be auto pauses
        for (index, event) in self.manualPauseEvents.enumerated() where event.realEventType == .autoPause {
            
            if let nextEvent = self.manualPauseEvents.safeValue(for: index + 1), nextEvent.realEventType == .autoResume, event.startDate < nextEvent.startDate {
                
                let startInterval = event.startDate.distance(to: referenceDate)
                let endInterval = nextEvent.startDate.distance(to: referenceDate)
                
                pauseRanges.append(startInterval...endInterval)
                
            }
            
        }
        
        return pauseRanges + self.autoPauseDetection.getPauseRanges(with: referenceDate)
        
    }
    
    /**
     Gets the duration of the workout
     - returns the duration of the workout in a measurement
     */
    private func getDurationMeasurement() -> NSMeasurement {
        
        let measurement: NSMeasurement
        
        if let startDate = self.startDate {
            
            var duration = startDate.distance(to: self.endDate ?? Date())
            
            for pauseRange in self.getPauseRanges(with: startDate) {
                
                duration -= pauseRange.length
                
            }
            
            measurement = NSMeasurement(doubleValue: duration, unit: UnitDuration.seconds)
            
        } else {
            
            measurement = NSMeasurement(doubleValue: 0, unit: UnitDuration.seconds)
            
        }
        
        return measurement
        
    }
    
    /**
    Gets the distance of the workout
    - returns the distance of the workout in a measurement
    */
    private func getDistanceMeasurement() -> NSMeasurement {
        
        let measurement = NSMeasurement(doubleValue: self.locationManagement.distance, unit: UnitLength.standardUnit)
        
        return measurement
        
    }
    
    /**
     Checks if a date is inside a pause range
     - parameter date: the date that is supposed to be checked
     - parameter referenceDate: the referenceDate used to generate the ranges
     - parameter ranges: the interval ranges for pauses
     - returns: a boolean indicating whether the provided date is inside a pause range
     */
    private func checkForPause(for date: Date, with referenceDate: Date, and ranges: [ClosedRange<Double>]) -> Bool {
        
        let value = date.distance(to: referenceDate)
        
        return ranges.contains { (range) -> Bool in
            return range.contains(value)
        }
        
    }
    
    private func getPaceMeasurementFrom(duration: NSMeasurement, distance: NSMeasurement) -> RelativeMeasurement {
        
        let duration = duration.converting(to: UnitDuration.minutes)
        
        let distance = distance.converting(to: UserPreferences.distanceMeasurementType.safeValue)
        
        return RelativeMeasurement(primary: duration, dividing: distance)
        
    }
    
    // MARK: Live Updates
    
    /**
     Live updates the status of the `WorkoutBuilder` by sending it to the delegate
     */
    public func liveUpdateStatus() {
        
        performIfAppropriate { (delegate) in
            
            delegate.didUpdate(status: self.status)
            
        }
        
    }
    
    /**
     Live updates the distance of the current workout by sending it to the delegate
     */
    public func liveUpdateDistance() {
        
        performIfAppropriate { (delegate) in
            
            let measurement = NSMeasurement(doubleValue: self.locationManagement.distance, unit: UnitLength.standardUnit)
            delegate.didUpdate(distanceMeasurement: measurement)
            
        }
        
    }
    
    /**
     Live updates the current location and route of the workout
     - parameter locations: the locations recorded so far
     - parameter force: a boolean describing whether a delegate update for the current location should be forced (carried out without an animation)
     */
    public func liveUpdateLocations(withLast lastLocation: CLLocation? = nil, force: Bool = false) {
        
        performIfAppropriate { (delegate) in
            
            delegate.didUpdate(routeData: self.locationManagement.locations)
            if let location = lastLocation {
                delegate.didUpdate(currentLocation: location, force: force)
            }
            
        }
        
    }
    
    /**
     Informs the delegate of an insufficient location permission for recording a workout
     */
    public func liveUpdateInsufficientPermission() {
        
        performIfAppropriate { (delegate) in
            
            delegate.informOfInsufficientLocationPermission()
            
        }
        
    }
    
    /**
     Live updates the duration of the workout by sending it to the delegate
     */
    public func liveUpdateDuration() {
        
        performIfAppropriate { (delegate) in
            
            let duration = self.getDurationMeasurement()
            delegate.didUpdate(durationMeasurement: duration)
            
        }
        
    }
    
    /**
     Live updates the energy burned during the workout by sending it to the delegate
     */
    public func liveUpdateBurnedEnergy() {
        
        performIfAppropriate { (delegate) in
            
            if let userWeight = UserPreferences.weight.value {
                
                let burnedEnergy = BurnedEnergyCalculator.calculateBurnedCalories(for: self.workoutType, distance: self.locationManagement.distance, weight: userWeight)
                
                delegate.didUpdate(energyMeasurement: burnedEnergy)
                
            }
            
        }
        
    }
    
    /**
     Live updates the speed based on user preferences by sending it to the delegate
     */
    public func liveUpdateSpeed() {
        
        performIfAppropriate { (delegate) in
            
            if UserPreferences.displayRollingSpeed.value {
                
                guard let startDate = self.startDate else {
                    return
                }
                
                let pauseRanges = self.getPauseRanges(with: startDate)
                
                var tempDistance: Double = 0
                var tempDuration: Double = 0
                var lastLocation: CLLocation?
                
                for location in self.locationManagement.locations.reversed() where tempDistance < 1000 {
                    
                    if self.checkForPause(for: location.timestamp, with: startDate, and: pauseRanges) {
                        
                        lastLocation = nil
                        continue
                        
                    }
                    
                    if let lastLocation = lastLocation {
                        
                        tempDistance += location.distance(from: lastLocation)
                        tempDuration += location.timestamp.distance(to: lastLocation.timestamp)
                        
                    }
                    
                    lastLocation = location
                    
                }
                
                guard tempDuration > 0, tempDistance > 0 else {
                    return
                }
                
                if UserPreferences.usePaceForSpeedDisplay.value {
                    
                    // rolling pace
                    
                    let duration = NSMeasurement(doubleValue: tempDuration, unit: UnitDuration.seconds)
                    
                    let distance = NSMeasurement(doubleValue: tempDistance, unit: UnitLength.standardUnit)
                    
                    let pace = self.getPaceMeasurementFrom(duration: duration, distance: distance)
                    
                    delegate.didUpdate(paceMeasurement: pace, rolling: true)
                    
                } else {
                    
                    // rolling speed
                    
                    let speed = NSMeasurement(doubleValue: tempDistance / tempDuration, unit: UnitSpeed.metersPerSecond)
                    
                    delegate.didUpdate(speedMeasurement: speed, rolling: true)
                    
                }
                
            } else {
                
                if UserPreferences.usePaceForSpeedDisplay.value {
                    
                    // total pace
                    
                    let pace = self.getPaceMeasurementFrom(duration: self.getDurationMeasurement(), distance: self.getDistanceMeasurement())
                    
                    delegate.didUpdate(paceMeasurement: pace, rolling: false)
                    
                } else {
                    
                    // current speed (last 3 values averaged)
                    
                    var averageSpeed: Double = 0
                    
                    for (index, location) in self.locationManagement.locations.reversed().enumerated() where index < 3 && location.speed > 0 {
                        
                        let index = Double(index)
                        
                        averageSpeed = ( averageSpeed * index + location.speed ) / ( index + 1 )
                        
                    }
                    
                    let speed = NSMeasurement(doubleValue: averageSpeed, unit: UnitSpeed.standardUnit)
                    
                    delegate.didUpdate(speedMeasurement: speed, rolling: false)
                    
                }
                
            }
            
        }
        
    }
    
}
