//
//  WorkoutBuilder+AltitudeManagement.swift
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
import CoreLocation

extension WorkoutBuilder {
    
    /// A `WorkoutBuilderComponent` for measuring changes in altitude and recording them for the refinement of route data
    class AltitudeManagement: WorkoutBuilderComponent {
        
        // MARK: Public
        
        /// If `true` the `AltitudeManager` will be able to collect data
        public var isDataAvailable: Bool {
            return CMAltimeter.isRelativeAltitudeAvailable()
        }
        
        /**
         Refines the altitude of provided locations
         - parameter locations: the array of locations supposed to be refined
         - returns: the refined array of locations
         */
        public func refine(locations: [CLLocation]) -> [CLLocation] {
            
            guard self.isDataAvailable, !locations.isEmpty else {
                return locations
            }
            
            // determining the average original altitude
            
            var averageCount: Double = 0
            var averageOriginalAltitude: Double = 0
            
            for location in locations {
                
                if let relativeAltitude = self.relativeAltitude(for: location.timestamp) {
                    
                    let originalAltitude = location.altitude - relativeAltitude
                    
                    averageOriginalAltitude = ( ( averageCount * averageOriginalAltitude ) + originalAltitude ) / ( averageCount + 1 )
                    
                    averageCount += 1
                    
                }
                
            }
            
            // refining
            
            var tempLocations = [CLLocation]()
            
            for location in locations {
                
                guard let relativeAltitude = self.relativeAltitude(for: location.timestamp) else {
                    tempLocations.append(location)
                    continue
                }
                
                let newAltitude = averageOriginalAltitude + relativeAltitude
                
                let newLocation = location.replacing(altitude: newAltitude.isFinite ? newAltitude : nil)
                
                tempLocations.append(newLocation)
                
            }
            
            return tempLocations
            
        }
        
        // MARK: Protected
        
        /// the data collected by the altimeter consisting of an array of timestamps and their relative altitudes
        private var altitudeData: [(timestamp: Date, relativeAltitude: Double)] = []
        
        /// an instance of `CMAltimeter` to measure releative altitude changes
        private let altimeter = CMAltimeter()
        
        /**
         Starts updating the relative altitude data
         */
        private func startUpdating() {
            
            if CMAltimeter.isRelativeAltitudeAvailable() {
                
                self.reset()
                
                self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (altitudeData, error) in
                    
                    guard let altitudeData = altitudeData else {
                        return
                    }
                    
                    let differenceInMeters = Double(truncating: altitudeData.relativeAltitude)
                    
                    self.altitudeData.append((timestamp: Date(), relativeAltitude: differenceInMeters))
                    
                }
                
            }
            
        }
        
        /**
         Provides the relative altitude for a specific date if available
         - parameter date: the date for which the relative altitude should be returned
         - returns: the relative altitude as a `Double`
         */
        private func relativeAltitude(for date: Date) -> Double? {
            
            for (index, dataPoint) in self.altitudeData.enumerated() {
                
                if let nextDataPoint = self.altitudeData.safeValue(for: index + 1) {
                    
                    if dataPoint.timestamp < date, nextDataPoint.timestamp > date {
                        
                        return dataPoint.relativeAltitude
                        
                    }
                    
                } else if dataPoint.timestamp < date, index + 1 == self.altitudeData.count {
                    
                    return dataPoint.relativeAltitude
                    
                }
                
            }
            
            return nil
            
        }
        
        // MARK: Initialisers
        
        /**
         Initialises the `AltitudeManagement` object with a `WorkoutBuilder`
         - parameter builder: the workout builder currently holding this instance of `AltitudeManagement`
         */
        convenience init(builder: WorkoutBuilder) {
            
            self.init()
            
            self.builder = builder
            
        }
        
        // MARK: WorkoutBuilderComponent - Protocol
        
        public weak var builder: WorkoutBuilder?
        
        public var isReady: Bool = true
        
        public func statusChanged(from oldStatus: WorkoutBuilder.Status, to newStatus: WorkoutBuilder.Status, timestamp: Date) {
            
            if newStatus.isActiveStatus && !oldStatus.isActiveStatus {
                
                self.startUpdating()
                
            }
            
        }
        
        func continueWorkout(from snapshot: TempWorkout, timestamp: Date) {
            
            // since the locations are already refined if possible here we just need to start updating again
            self.startUpdating()
            
        }
        
        public func reset() {
            
            self.altimeter.stopRelativeAltitudeUpdates()
            self.altitudeData = []
            
        }
        
    }
    
}
