//
//  PermissionManager.swift
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
import CoreMotion

class PermissionManager: NSObject, CLLocationManagerDelegate {
    
    static let standard = PermissionManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
    }
    
    // MARK: Apple Health
    
    func checkHealthPermission(closure: @escaping (Bool) -> Void) {
        for type in HealthStoreManager.requestedTypes where HealthStoreManager.healthStore.authorizationStatus(for: type) != .sharingAuthorized {
            HealthStoreManager.gainAuthorization { (success) in
                closure(success)
            }
            return
        }
        closure(true)
    }
    
    // MARK: Location
    
    private let locationManager = CLLocationManager()
    private var locationPermissionClosure: ((LocationPermissionStatus) -> Void)?
    func checkLocationPermission(closure: @escaping (LocationPermissionStatus) -> Void) {
        DispatchQueue.main.async {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                closure(.granted)
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
                self.locationPermissionClosure = closure
            default:
                closure(.denied)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        var tempLocationPermissionStatus: LocationPermissionStatus = .denied
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            tempLocationPermissionStatus = .granted
        case .notDetermined:
            return
        default:
            break
        }
        
        guard let closure = self.locationPermissionClosure else {
            return
        }
        
        closure(tempLocationPermissionStatus)
        self.locationPermissionClosure = nil
        
    }
    
    enum LocationPermissionStatus {
        case granted, restricted, denied, error
    }
    
    // MARK: Motion
    
    func checkMotionPermission(closure: @escaping (Bool) -> Void) {
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            closure(true)
        case .notDetermined:
            let activityManager = CMMotionActivityManager()
            activityManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { (activity, error) in
                let auth = CMPedometer.authorizationStatus()
                switch auth {
                case .authorized:
                    closure(true)
                default:
                    closure(false)
                }
            }
        default:
            closure(false)
        }
    }
    
}
