//
//  WorkoutBuilder+LocationManagement.swift
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
    
    /// A `WorkoutBuilderComponent` to manage everything location related
    class LocationManagement: NSObject, WorkoutBuilderComponent, CLLocationManagerDelegate {
        
        // MARK: Public
        
        /// the recorded locations
        public private(set) var locations: [CLLocation] = [] {
            didSet {
                if let location = self.locations.last {
                    self.builder?.notfiyOfLocationUpdate(with: location)
                }
            }
        }
        /// the recorded distance in meters
        public private(set) var distance: Double = 0 {
            didSet {
                self.builder?.notifyOfDistanceUpdate()
            }
        }
        
        /**
         Stops location updates
         */
        public func stopLocationUpdates() {
            self.locationManager.stopUpdatingLocation()
        }
        /**
         Starts location updates
         */
        public func startLocationUpdates() {
            self.locationManager.startUpdatingLocation()
        }
        
        // MARK: Protected
        
        /// an instance of `CLLocationManager` used as the data source for locations
        private var locationManager: CLLocationManager = CLLocationManager()
        /// a boolean indicating whether locations should be recorded
        private var shouldRecord: Bool = false
        /// the minimum horizontal accuracy a location is supposed to have to be recorded; if `nil` the user does not want locations to be checked for accuracy
        private var desiredAccuracy: Double? = nil
        /// the average horizontal accuracy of incoming locations while recording
        private var averageAccuracy: Double = 0
        
        /**
         Checks a `CLLocation` for appropriate horizontal accuracy based on user preferences and gathered data
         - parameter location: the `CLLocation` that is supposed to be checked
         - returns: a boolean whether the `CLLocation` is appropriate for use or not
         */
        private func checkForAppropriateAccuracy(_ location: CLLocation) -> Bool {
            
            guard let desiredAccuracy = self.desiredAccuracy else {
                return true
            }
            
            guard location.horizontalAccuracy < 100, location.horizontalAccuracy <= desiredAccuracy else {
                return false
            }
            
            return true
            
        }
        
        /**
         Updates `desiredAccuracy` from the averageAccuracy of past and new location values
         - parameter locations: the new locations to retrieve accuracy values from
         */
        private func updateDesiredAccuracy(from locations: [CLLocation]) {
            
            if UserPreferences.gpsAccuracy.value == nil, !locations.isEmpty {
                
                var averageAccuracy: Double = 0
                
                for (index, location) in locations.enumerated() {
                    
                    let index = Double(index)
                    
                    averageAccuracy = ( averageAccuracy * index + location.horizontalAccuracy ) / ( index + 1 )
                    
                }
                
                let globalCount = Double(self.locations.count < 10 ? self.locations.count : 9)
                
                let localCount = Double(locations.count)
                
                self.averageAccuracy = ( self.averageAccuracy * globalCount + averageAccuracy * localCount ) / ( globalCount + localCount )
                
                self.desiredAccuracy = averageAccuracy < 20 ? 20 : self.averageAccuracy.rounded(decimalPlaces: -1, rule: .up)
                
            }
            
        }
        
        // MARK: Initialisers
        
        /**
         Initialises a `LocationManagement` instance, setting up the internal `CLLocationManager` and starting to receive locations
         */
        public override init() {
            
            super.init()
            
            if UserPreferences.gpsAccuracy.value != -1 {
                self.desiredAccuracy = UserPreferences.gpsAccuracy.value ?? 20
            }
            
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.allowsBackgroundLocationUpdates = true
            self.locationManager.activityType = .fitness
            self.locationManager.showsBackgroundLocationIndicator = true
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
            
        }
        
        /**
         Initialises the `LocationManagement` object with a `WorkoutBuilder`
         - parameter builder: the workout builder currently holding this instance of `LocationManagement`
         */
        convenience init(builder: WorkoutBuilder) {
            
            self.init()
            self.builder = builder
            
        }
        
        // MARK: WorkoutBuilderComponent - Protocol
        
        public weak var builder: WorkoutBuilder?
        
        public var isReady: Bool = false {
            didSet {
                self.builder?.notifyOfReadinessChange()
            }
        }
        
        func statusChanged(from oldStatus: WorkoutBuilder.Status, to newStatus: WorkoutBuilder.Status, timestamp: Date) {
            
            switch newStatus {
            case .recording, .paused, .autoPaused:
                self.shouldRecord = true
            default:
                self.shouldRecord = false
            }
            
        }
        
        func continueWorkout(from snapshot: TempWorkout, timestamp: Date) {
            
            self.locations = snapshot.locations.map({ (sample) -> CLLocation in
                sample.clLocation
            })
            self.distance = snapshot.distance
            self.shouldRecord = true
            self.startLocationUpdates()
            
        }
        
        func reset() {
            
            self.locations = []
            self.distance = 0
            self.shouldRecord = false
            self.startLocationUpdates()
            
        }
        
        // MARK: CLLocationManagerDelegate - Protocol
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            
            updateDesiredAccuracy(from: locations)
            
            if self.shouldRecord {
                
                for location in locations where checkForAppropriateAccuracy(location) {
                    
                    guard let lastLocation = self.locations.last else {
                        
                        self.locations.append(location)
                        continue
                        
                    }
                    
                    let tempDistance = location.distance(from: lastLocation)
                    
                    if let builder = self.builder, !builder.status.isPausedStatus {
                        self.distance = self.distance + tempDistance
                    }
                    
                    self.locations.append(location)
                    
                }
                
            } else {
                
                if let lastLocation = locations.last {
                    
                    self.builder?.notfiyOfLocationUpdate(with: lastLocation)
                    
                }
                
                let hasAtLeastOneAppropriateLocation = locations.contains(where: { (location) -> Bool in
                    checkForAppropriateAccuracy(location)
                })
                
                if self.isReady != hasAtLeastOneAppropriateLocation {
                    
                    self.isReady = hasAtLeastOneAppropriateLocation
                    
                }
                
            }
            
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            
            print("[WorkoutBuilder+LocationManager] CLLocationManager failed with error:", error.localizedDescription)
            
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            
            if ![.authorizedAlways, .authorizedWhenInUse].contains(status) {
                
                self.builder?.notifyOfInsufficientLocationPermission()
                
            }
            
        }
        
    }
    
}
