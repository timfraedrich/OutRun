//
//  LocationManagement.swift
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
import RxSwift
import RxCocoa

/// A `WorkoutBuilderComponent` to manage everything location related
public class LocationManagement: NSObject, WorkoutBuilderComponent, CLLocationManagerDelegate {
    
    /// An instance of `CLLocationManager` used as the data source for locations.
    private var locationManager: CLLocationManager = CLLocationManager()
    /// A boolean indicating whether locations should be recorded.
    private var shouldRecord: Bool = false
    /// A boolean indicating whether the distance should be updated.
    private var shouldUpdateDistance: Bool = false
    /// The minimum horizontal accuracy a location is supposed to have to be recorded; if `nil` the user does not want locations to be checked for accuracy.
    private var desiredAccuracy: Double? = nil
    /// The average horizontal accuracy of incoming locations while recording.
    private var averageAccuracy: Double = 0
    /// An array of altitude samples provided by the `WorkoutBuilder`.
    private var altitudeData: [AltitudeManagement.AltitudeSample] = []
    
    /**
     Checks a `CLLocation` for appropriate horizontal accuracy based on user preferences and gathered data
     - parameter location: the `CLLocation` that is supposed to be checked
     - returns: a boolean whether the `CLLocation` is appropriate for use or not
     */
    private func checkForAppropriateAccuracy(_ location: CLLocation) -> Bool {
        guard let desiredAccuracy = self.desiredAccuracy else { return true }
        return location.horizontalAccuracy < 100 && location.horizontalAccuracy <= desiredAccuracy
    }
    
    /**
     Updates `desiredAccuracy` from the averageAccuracy of past and new location values
     - parameter locations: the new locations to retrieve accuracy values from
     */
    private func updateDesiredAccuracy(from locations: [CLLocation]) {
        
        guard UserPreferences.gpsAccuracy.value == nil, !locations.isEmpty else { return }
        
        var averageAccuracy: Double = 0
        for (index, location) in locations.enumerated() {
            let index = Double(index)
            averageAccuracy = ( averageAccuracy * index + location.horizontalAccuracy ) / ( index + 1 )
        }
        
        let globalCount = Double(min(self.locationsRelay.value.count, 9))
        let localCount = Double(locations.count)
        
        self.averageAccuracy = (self.averageAccuracy * globalCount + averageAccuracy * localCount) / (globalCount + localCount)
        self.desiredAccuracy = min(averageAccuracy.rounded(decimalPlaces: -1, rule: .up), 20)
    }
    
    /**
     Refines the provided location with altitude data.
     - parameter location: the location that is supposed to be refined
     - returns: the refined location
     */
    private func refineLocation(_ location: CLLocation) -> CLLocation {
        let altitude = altitudeData.last { $0.timestamp < location.timestamp }?.altitude
        return location.replacing(altitude: altitude)
    }
    
    // MARK: - Dataflow
    
    /// The `DisposeBag` used for binding to the workout builder.
    private let disposeBag = DisposeBag()
    
    /// The relay to publish the status of readiness to the workout builder.
    private let readinessRelay = BehaviorRelay<WorkoutBuilderComponentStatus>(value: .preparing(LocationManagement.self))
    /// The relay to publish that insufficient permission was granted to the workout builder.
    private let insufficientPermissionRelay = PublishRelay<String>()
    /// The relay to publish the distance travelled to the workout builder.
    private let distanceRelay = BehaviorRelay<Double>(value: 0)
    /// The relay to publish the current location to the workout builder.
    private let currentLocationRelay = BehaviorRelay<TempWorkoutRouteDataSample?>(value: nil)
    /// The relay to publish all recorded locations to the workout builder.
    private let locationsRelay = BehaviorRelay<[TempWorkoutRouteDataSample]>(value: [])
    
    // MARK: Binders
    
    /// Binds the current workout builder status to this component.
    private var statusBinder: Binder<WorkoutBuilder.Status> {
        Binder(self) { `self`, newStatus in
            self.shouldRecord = newStatus.isActiveStatus
            self.shouldUpdateDistance = newStatus.isActiveStatus && !newStatus.isPausedStatus
        }
    }
    
    /// Binds altititude updates to this component.
    private var altitudesBinder: Binder<[AltitudeManagement.AltitudeSample]> {
        Binder(self) { `self`, altitudes in
            self.altitudeData = altitudes
        }
    }
    
    /// Binds suspension events to this component.
    private var isSuspendedBinder: Binder<Bool> {
        Binder(self) { `self`, isSuspended in
            if isSuspended {
                self.locationManager.stopUpdatingLocation()
            } else {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    /// Binds reset events to this component.
    private var onResetBinder: Binder<ORWorkoutInterface?> {
        Binder(self) { `self`, snapshot in
            self.locationsRelay.accept(snapshot?.routeData.map { .init(from: $0) } ?? [])
            self.distanceRelay.accept(snapshot?.distance ?? 0)
            self.locationManager.startUpdatingLocation()
        }
    }
    
    
    // MARK: WorkoutBuilderComponent
    
    public func bind(builder: WorkoutBuilder) {
        
        let input = Input(
            readiness: readinessRelay.asBackgroundObservable(),
            insufficientPermission: insufficientPermissionRelay.asBackgroundObservable(),
            distance: distanceRelay.asBackgroundObservable(),
            currentLocation: currentLocationRelay.asBackgroundObservable(),
            locations: locationsRelay.asBackgroundObservable()
        )
        
        let output = builder.tranform(input)
     
        output.status
            .bind(to: statusBinder)
            .disposed(by: disposeBag)
        
        output.altitudes
            .bind(to: altitudesBinder)
            .disposed(by: disposeBag)
        
        output.isSuspended
            .bind(to: isSuspendedBinder)
            .disposed(by: disposeBag)
        
        output.onReset
            .bind(to: onResetBinder)
            .disposed(by: disposeBag)
    }
    
    public func prepare() {
        
        if UserPreferences.gpsAccuracy.value != -1 {
            self.desiredAccuracy = UserPreferences.gpsAccuracy.value ?? 20
        }
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.activityType = .fitness
        self.locationManager.showsBackgroundLocationIndicator = true
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.pausesLocationUpdatesAutomatically = true
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateDesiredAccuracy(from: locations)
        
        guard self.shouldRecord else {
            if let lastLocation = locations.last {
                currentLocationRelay.accept(lastLocation.asTemp)
            }
            let isReady = locations.contains { checkForAppropriateAccuracy($0) }
            let newStatus: WorkoutBuilderComponentStatus = isReady ? .ready(LocationManagement.self) : .preparing(LocationManagement.self)
            
            guard readinessRelay.value != newStatus else { return }
            readinessRelay.accept(newStatus)
            return
        }
        
        // recording
        for location in locations where checkForAppropriateAccuracy(location) {
            
            let location = refineLocation(location)
            locationsRelay.accept(locationsRelay.value + [location.asTemp])
            
            guard shouldUpdateDistance, let lastLocation = self.locationsRelay.value.last else { continue }
            let newDistance = location.distance(from: lastLocation.clLocation) + distanceRelay.value
            distanceRelay.accept(newDistance)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManagement] CLLocationManager failed with error:", error.localizedDescription)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard ![.authorizedAlways, .authorizedWhenInUse].contains(status) else { return }
        insufficientPermissionRelay.accept(LS["Setup.Permission.Location.Error"])
    }
}
