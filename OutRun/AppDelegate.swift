//
//  AppDelegate.swift
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
import Foundation
import CoreStore
import HealthKit
import CoreLocation

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    
    @Published var appLaunchState: AppLaunchState = .loading
    
    static let lastVersion = UserPreference.Optional<String>(key: "lastVersion", initialValue: "1.0")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        DataManager.setup(
            completion: { error in
                
                self.appLaunchState = .done

                // check permissions
                // show changelog
                //
                
                // self.checkPermissionStatus(controller: controller) {
                //     guard UserPreferences.isSetUp.value else { return }
                //     HealthStoreManager.setupObservers()
                //
                //     if AppDelegate.lastVersion.value != Config.version && AppDelegate.lastVersion.value != nil {
                //
                //         if let changeLog = Config.changeLogs[Config.version] {
                //             // show changelog
                //         }
                //
                //         AppDelegate.lastVersion.value = Config.version
                //
                //     } else if AppDelegate.lastVersion.value == nil {
                //         AppDelegate.lastVersion.value = Config.version
                //     }
                // }

            }, migration: { progress in

                // show migration screen
                self.appLaunchState = .migration

            }
        )
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        WorkoutMapImageManager.suspendRenderProcess()
        ApplicationStateObservation.stateChanged(to: .background)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        WorkoutMapImageManager.resumeRenderProcess()
        ApplicationStateObservation.stateChanged(to: .foreground)
    }

    func applicationWillTerminate(_ application: UIApplication) {}

    func checkPermissionStatus(controller: UIViewController, completion: (() -> Void)? = nil) {

        let safeCompletion: () -> Void = {
            DispatchQueue.main.async {
                completion?()
            }
        }

        if UserPreferences.isSetUp.value {

            func checkHealthPermission() {
                if UserPreferences.synchronizeWorkoutsWithAppleHealth.value || UserPreferences.synchronizeWeightWithAppleHealth.value {
                    PermissionManager.standard.checkHealthPermission { (success) in
                        if !success {
                            DispatchQueue.main.async {
                                controller.displayError(withMessage: LS["Setup.Permission.AppleHealth.Error"], dismissAction: { _ in
                                    safeCompletion()
                                })
                            }
                        } else {
                            safeCompletion()
                        }
                    }
                } else {
                    safeCompletion()
                }
            }

            func checkMotionPermission() {
                PermissionManager.standard.checkMotionPermission { (success) in
                    if !success {
                        DispatchQueue.main.async {
                            controller.displayOpenSettingsAlert(
                                withTitle: LS["Error"],
                                message: LS["Setup.Permission.Motion.Error"],
                                dismissAction: {
                                    checkHealthPermission()
                                }
                            )
                        }
                    } else {
                        checkHealthPermission()
                    }
                }
            }

            PermissionManager.standard.checkLocationPermission { (status) in
                switch status {
                case .granted:
                    checkMotionPermission()
                    break
                case .restricted:
                    DispatchQueue.main.async {
                        controller.displayOpenSettingsAlert(
                            withTitle: LS["Setup.Permission.Location.Restricted.Title"],
                            message: LS["Setup.Permission.Location.Restricted.Message"],
                            dismissAction: {
                                checkMotionPermission()
                            }
                        )
                    }
                default:
                    DispatchQueue.main.async {
                        controller.displayOpenSettingsAlert(
                            withTitle: LS["Error"],
                            message: LS["Setup.Permission.Location.Error"],
                            dismissAction: {
                                checkMotionPermission()
                            }
                        )
                    }
                }
            }

        } else {
            safeCompletion()
        }
    }
    
    enum AppLaunchState {
        case loading
        case migration
        case done
    }
}

