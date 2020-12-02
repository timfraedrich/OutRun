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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static let lastVersion = UserPreference.Optional<String>(key: "lastVersion", initialValue: "1.0")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        let launchScreen = storyboard.instantiateViewController(withIdentifier: "launchScreen")
        
        setRootViewController(for: launchScreen) {
            DataManager.setup(
                completion: { error in
                    
                    let controller: UIViewController = {
                        if UserPreferences.isSetUp.value {
                            return TabBarController()
                        } else {
                            return StartScreenViewController()
                        }
                    }()
                    
                    self.setRootViewController(for: controller, withSmoothTransition: true) {
                        self.checkPermissionStatus(controller: controller) {
                            if UserPreferences.isSetUp.value {
                                HealthObserver.setupObservers()
                                
                                if AppDelegate.lastVersion.value != Config.version && AppDelegate.lastVersion.value != nil {
                                    
                                    if let changeLog = Config.changeLogs[Config.version] {
                                        let changeLogController = ChangeLogViewController()
                                        changeLogController.changeLog = changeLog
                                        changeLogController.modalPresentationStyle = .overFullScreen
                                        changeLogController.modalTransitionStyle = .crossDissolve
                                        
                                        controller.present(changeLogController, animated: true)
                                    }
                                    
                                    AppDelegate.lastVersion.value = Config.version
                                    
                                } else if AppDelegate.lastVersion.value == nil {
                                    AppDelegate.lastVersion.value = Config.version
                                }
                            }
                        }
                    }
                    
                },
                migration: { progress in
                    
                    let progressController = ProgressViewController()
                    self.setRootViewController(for: progressController, withSmoothTransition: true)
                    
                    progress.setProgressHandler { (progress) in
                        progressController.setProgress(progress.fractionCompleted)
                    }
                    
                }
            )
            
        }
        
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
    
    /// Setting a new root view controller for the applications current window
    func setRootViewController(for controller: UIViewController, withSmoothTransition shouldAnimate: Bool = false, completion: (() -> Void)? = nil) {
        
        guard self.window != nil else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.tintColor = .accentColor
            self.window?.rootViewController = controller
            self.window?.makeKeyAndVisible()
            completion?()
            return
        }
        
        guard shouldAnimate, let rootController = self.window?.rootViewController?.presentedViewController else {
            self.window?.rootViewController = controller
            completion?()
            return
        }
        
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        
        rootController.present(controller, animated: true, completion: {
            
            rootController.dismiss(animated: false) {
                
                self.window?.rootViewController = controller
                completion?()
                
            }
            
        })
        
    }
}

