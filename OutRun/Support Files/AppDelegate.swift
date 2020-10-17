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
            
            DataManager.setup(completion: {
                
                let controller: UIViewController = {
                    if UserPreferences.isSetUp.value {
                        return TabBarController()
                    } else {
                        return StartScreenViewController()
                    }
                }()
                
                self.setRootViewController(for: controller, withSmoothTransition: true) {
                    self.checkPermissionStatus(controller: controller) {
                        self.checkForTerminationWorkout(controller: controller) {
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
                }
                
            }, migrationClosure: {
                
                let progressController = ProgressViewController()
                self.setRootViewController(for: progressController, withSmoothTransition: true)
                
                return { newProgressValue in
                    progressController.setProgress(newProgressValue)
                }
                
            })
            
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

    func applicationWillTerminate(_ application: UIApplication) {
        
        self.tryToSaveRecodingWorkout()
        
    }
    
    func tryToSaveRecodingWorkout() {
        
        if let workoutBuilder = WorkoutBuilder.currentlyActive {
            
            print("[AppDelegate] Trying to save workout before termination...")
            WorkoutBuilder.didSaveWorkoutOnTermination.value = true
            
            if let snapshot = workoutBuilder.createSnapshot() {
                
                do {
                    
                    let workoutData = try JSONEncoder().encode(snapshot)
                    
                    WorkoutBuilder.termWorkoutData.value = workoutData
                    WorkoutBuilder.termWorkoutSaveSuccess.value = true
                    
                    print("[AppDelegate] Successfully saved workout before termination:", snapshot)
                    
                } catch {
                    
                    WorkoutBuilder.termWorkoutSaveSuccess.value = false
                    
                    print("[AppDelegate] Error: Was not able to encode termination workout data")
                    
                }
                
            } else {
                
                print("[AppDelegate] Was not able to initiate workout to save before termination")
                
            }
            
        }
        
    }
    
    func checkForTerminationWorkout(controller: UIViewController, completion: (() -> Void)? = nil) {
        
        let safeCompletion: () -> Void = {
            DispatchQueue.main.async {
                completion?()
            }
        }
        
        if WorkoutBuilder.didSaveWorkoutOnTermination.value {
            if WorkoutBuilder.termWorkoutSaveSuccess.value {
                
                if let workoutData = WorkoutBuilder.termWorkoutData.value {
                    
                    do {
                        let tempWorkout = try JSONDecoder().decode(TempWorkout.self, from: workoutData)
                        print("Saved workout on last termination:\n\(tempWorkout)")
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController(
                                title: LS["TerminationBackup.SaveAlert.Title"],
                                message: LS["TerminationBackup.SaveAlert.Message"],
                                preferredStyle: .alert,
                                options: [
                                    (
                                        title: LS["Cancel"],
                                        style: .destructive,
                                        action: { _ in
                                            safeCompletion()
                                        }
                                    ),
                                    (
                                        title: LS["Save"],
                                        style: .default,
                                        action: { _ in
                                            
                                            DataManager.saveWorkout(
                                                tempWorkout: tempWorkout,
                                                completion: { (success, error, workout) in
                                                    
                                                    guard let workout = workout, success else {
                                                        print("Error: Termination Workout could not be saved:", error ?? "no error")
                                                        controller.displayError(withMessage: LS["TerminationBackup.Save.Error"], dismissAction: { _ in
                                                                safeCompletion()
                                                            }
                                                        )
                                                        return
                                                    }
                                                    
                                                    if UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                                                    
                                                        HealthStoreManager.saveHealthWorkout(forWorkout: workout, completion: { (success, healthWorkout) in
                                                            guard success else {
                                                                controller.displayError(withMessage: LS["TerminationBackup.Save.Health.Error"], dismissAction: { _ in
                                                                        safeCompletion()
                                                                    }
                                                                )
                                                                return
                                                            }
                                                            safeCompletion()
                                                        })
                                                        
                                                    }
                                                    
                                                    let workoutController = WorkoutViewController()
                                                    workoutController.workout = workout
                                                    controller.present(workoutController, animated: true)
                                                    
                                                }
                                            )
                                            
                                    }
                                    )
                                ]
                            )
                            controller.present(alert, animated: true)
                        }
                    } catch {
                        print("Error: could not decode termination workout data")
                        safeCompletion()
                    }
                    
                } else {
                    print("Error: failed to get access to workout saved on last termination")
                    safeCompletion()
                }
                
            } else {
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: LS["TerminationBackup.LostAlert.Title"],
                        message: LS["TerminationBackup.LostAlert.Message"],
                        preferredStyle: .alert,
                        options: [
                            (
                                title: LS["Okay"],
                                style: .default,
                                action: nil
                            )
                        ],
                        dismissAction: {
                            safeCompletion()
                        }
                    )
                    controller.present(alert, animated: true)
                }
                
            }
            
            // clear term data
            WorkoutBuilder.didSaveWorkoutOnTermination.delete()
            WorkoutBuilder.termWorkoutSaveSuccess.delete()
            WorkoutBuilder.termWorkoutData.delete()
            
        } else {
            safeCompletion()
        }
    }
    
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

