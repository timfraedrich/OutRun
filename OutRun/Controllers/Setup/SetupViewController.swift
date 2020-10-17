//
//  SetupViewController.swift
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

class SetupViewController: UIViewController {
    
    let numberOfPages = 4
    var currentPage = 0
    var isTransitioning = false
    
    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 40, right: 0)
        return scroll
    }()
    
    lazy var pageIndicator: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false
        pageControl.numberOfPages = self.numberOfPages
        pageControl.pageIndicatorTintColor = UIColor.accentColor.withAlphaComponent(0.25)
        pageControl.currentPageIndicatorTintColor = .accentColor
        return pageControl
    }()
    
    let nextButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.accentColor, for: .normal)
        button.setTitleColor(.secondaryColor, for: .disabled)
        button.setTitle(LS["Next"], for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.isEnabled = false
        return button
    }()
    
    // MARK: General
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nextButton.addTarget(self, action: #selector(nextButtonSelector), for: .touchUpInside)
        
        self.view.backgroundColor = .backgroundColor
        
        self.view.addSubview(scrollView)
        self.view.addSubview(pageIndicator)
        self.view.addSubview(nextButton)
        
        let safeLayout = self.view.safeAreaLayoutGuide
        let width = self.view.frame.width
        let edgeInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        scrollView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(safeLayout).inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
        pageIndicator.snp.makeConstraints { (make) in
            make.top.equalTo(scrollView.snp.bottom).offset(20)
            make.left.bottom.equalTo(safeLayout).inset(UIEdgeInsets(top: 0, left: 30, bottom: 20, right: 0))
            make.height.equalTo(30)
        }
        nextButton.snp.makeConstraints { (make) in
            make.top.equalTo(scrollView.snp.bottom).offset(20)
            make.right.bottom.equalTo(safeLayout).inset(UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 30))
            make.height.equalTo(30)
        }
        
        self.scrollView.addSubview(formalitiesView)
        self.scrollView.addSubview(userInfoView)
        self.scrollView.addSubview(appleHealthSyncView)
        self.scrollView.addSubview(permissionsView)
        
        formalitiesView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview().inset(edgeInset)
            make.width.equalTo(width - 40)
        }
        userInfoView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(edgeInset)
            make.left.equalTo(formalitiesView.snp.right).offset(20)
            make.width.equalTo(width - 40)
        }
        appleHealthSyncView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(edgeInset)
            make.left.equalTo(userInfoView.snp.right).offset(40)
            make.width.equalTo(width - 40)
        }
        permissionsView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(edgeInset)
            make.left.equalTo(appleHealthSyncView.snp.right).offset(40)
            make.width.equalTo(width - 40)
        }
        
    }
    
    @objc func nextButtonSelector() {
        if !isTransitioning {
            if currentPage + 1 < numberOfPages {
                let width = self.scrollView.frame.width - (currentPage == 0 ? 20 : 0)
                currentPage += 1
                self.pageIndicator.currentPage = currentPage
                self.isTransitioning = true
                
                switch self.currentPage {
                case 1:
                    self.toggleButtonStatusForUserInfo()
                case 2:
                    self.nextButton.setTitle(LS["Skip"], for: .normal)
                case 3:
                    self.healthPermissionView?.isHidden = !(self.shouldSyncWeight || self.shouldSyncWorkouts)
                    self.toggleButtonStatusForPermissions()
                default:
                    break
                }
                
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                    self.scrollView.contentOffset = CGPoint(x: width, y: -40)
                }, completion: { _ in
                    
                    func prepareNewConstrains(forFirstView firstView: UIView, secondView: UIView) {
                        firstView.snp.removeConstraints()
                        firstView.removeFromSuperview()
                        secondView.snp.makeConstraints { (make) in
                            make.left.equalToSuperview().offset(20)
                        }
                    }
                    
                    switch self.currentPage {
                    case 1:
                        prepareNewConstrains(forFirstView: self.formalitiesView, secondView: self.userInfoView)
                    case 2:
                        prepareNewConstrains(forFirstView: self.userInfoView, secondView: self.appleHealthSyncView)
                    case 3:
                        prepareNewConstrains(forFirstView: self.appleHealthSyncView, secondView: self.permissionsView)
                    default:
                        break
                    }
                    self.updateViewConstraints()
                    self.scrollView.contentOffset.x = 0
                    
                    self.isTransitioning = false
                })
                if currentPage + 1 == numberOfPages {
                    self.nextButton.setTitle(LS["Finish"], for: .normal)
                    self.nextButton.setTitle(LS["Finish"], for: .disabled)
                }
            } else {
                
                // finish setup
                self.scrollView.contentOffset.x = 0
                
                self.finishSetup()
                
                let controller = TabBarController()
                controller.modalTransitionStyle = .crossDissolve
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true)
                
            }
        }
    }
    
    func finishSetup() {
        
        UserPreferences.name.value = self.username
        UserPreferences.weight.value = self.userWeight
        
        if (Locale.current.usesMetricSystem ? 0 : 1) != self.preferredMeasurementSystem {
            
            switch self.preferredMeasurementSystem {
                
            case 0: // if standard is imperial and user chose metric
                
                UserPreferences.distanceMeasurementType.value = .kilometers
                UserPreferences.altitudeMeasurementType.value = .meters
                UserPreferences.speedMeasurementType.value = .kilometersPerHour
                UserPreferences.weightMeasurementType.value = .kilograms
                
            default: // if standard is metric and user chose imperial
                
                UserPreferences.distanceMeasurementType.value = .miles
                UserPreferences.altitudeMeasurementType.value = .yards
                UserPreferences.speedMeasurementType.value = .milesPerHour
                UserPreferences.weightMeasurementType.value = .pounds
                
            }
        }
        
        UserPreferences.synchronizeWorkoutsWithAppleHealth.value = self.shouldSyncWorkouts
        UserPreferences.synchronizeWeightWithAppleHealth.value = self.shouldSyncWeight
        UserPreferences.automaticallyImportNewHealthWorkouts.value = self.shouldAutoImportWorkouts
        
        UserPreferences.isSetUp.value = true
        HealthObserver.setupObservers()
        AppDelegate.lastVersion.value = Config.version
        
    }
    
    // MARK: Formalities
    
    var agreedToPrivacyPolicy = false
    var agreedToTermsOfService = false
    
    func toggleButtonStatusForAgreements() {
        if agreedToPrivacyPolicy && agreedToTermsOfService {
            self.nextButton.isEnabled = true
        } else {
            self.nextButton.isEnabled = false
        }
    }
    
    lazy var formalitiesView = SetupView(
        title: LS["Setup.Formalities.Title"],
        text: LS["Setup.Formalities.Message"],
        customViewClosure: { view -> UIView in
            
            let privacySwitchView = SetupSwitchView(
                title: LS["Settings.PrivacyPolicy"],
                isOn: false,
                switchAction: { (onStatus) in
                    
                    self.agreedToPrivacyPolicy = onStatus
                    self.toggleButtonStatusForAgreements()
                    
                }, buttonAction: {
                    let policyController = PolicyViewController()
                    policyController.type = .privacyPolicy
                    self.showDetailViewController(policyController, sender: self)
                }
            )
            let termsSwitchView = SetupSwitchView(
                title: LS["Settings.TermsOfService"],
                isOn: false,
                switchAction: { (onStatus) in
                    
                    self.agreedToTermsOfService = onStatus
                    self.toggleButtonStatusForAgreements()
                    
                }, buttonAction: {
                    let policyController = PolicyViewController()
                    policyController.type = .termsOfService
                    self.showDetailViewController(policyController, sender: self)
                }
            )
            
            view.addSubview(privacySwitchView)
            view.addSubview(termsSwitchView)
            
            privacySwitchView.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
            }
            termsSwitchView.snp.makeConstraints { (make) in
                make.top.equalTo(privacySwitchView.snp.bottom)
                make.left.right.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
                make.bottom.lessThanOrEqualToSuperview()
            }
            
            return view
        }
    )
    
    // MARK: User Info
    var username: String?
    var userWeight: Double?
    var preferredMeasurementSystem: Int = Locale.current.usesMetricSystem ? 0 : 1
    
    func getWeightFieldBehindLabelText(forIndex index: Int) -> String {
        return CustomMeasurementFormatting.string(forUnit: index == 0 ? UnitMass.kilograms : UnitMass.pounds, short: true)
    }
    
    func toggleButtonStatusForUserInfo() {
        if userWeight != nil {
            self.nextButton.isEnabled = true
        } else {
            self.nextButton.isEnabled = false
        }
    }
    
    lazy var userInfoView = SetupView(
        title: LS["Setup.UserInfo.Title"],
        text: LS["Setup.UserInfo.Message"],
        customViewClosure: { view -> UIView in
            
            let nameField = SetupTextFieldView(
                title: LS["Setup.UserInfo.Username"],
                placeholder: LS["Setup.UserInfo.Username.Placeholder"],
                textFieldAction: { (input) in
                    self.username = input
                }
            )
            var weightField: SetupTextFieldView?
            weightField = SetupTextFieldView(
                title: LS["Setup.UserInfo.Weight"],
                placeholder: LS["Setup.UserInfo.Weight"],
                keyboardType: .decimalPad,
                textBehindTextField: self.getWeightFieldBehindLabelText(forIndex: self.preferredMeasurementSystem),
                textFieldAction: { (input) in
                    guard let newValue = CustomNumberFormatting.number(from: input) else {
                        self.userWeight = nil
                        weightField!.textField.text = ""
                        self.toggleButtonStatusForUserInfo()
                        return
                    }
                    let sourceUnit: UnitMass = self.preferredMeasurementSystem == 0 ? .kilograms : .pounds
                    let convertedWeightValue = UnitConversion.conversion(of: newValue, from: sourceUnit, to: UnitMass.kilograms)
                    self.userWeight = convertedWeightValue
                    self.toggleButtonStatusForUserInfo()
                }
            )
            let systemSeg = SetupSegementedControlView(
                title: LS["Setup.UserInfo.PreferredSystem"],
                segmentTitles: [LS["Setup.UserInfo.PreferredSystem.Metric"], LS["Setup.UserInfo.PreferredSystem.Imperial"]],
                initialSegment: self.preferredMeasurementSystem,
                segmentedControlAction: { (newIndex) in
                    let oldIndex = self.preferredMeasurementSystem
                    self.preferredMeasurementSystem = newIndex
                    if newIndex != oldIndex {
                        weightField?.behindLabel.text = self.getWeightFieldBehindLabelText(forIndex: newIndex)
                        guard let userWeight = self.userWeight else {
                            return
                        }
                        let targetUnit: UnitMass = self.preferredMeasurementSystem == 0 ? .kilograms : .pounds
                        let weightValue = UnitConversion.conversion(of: userWeight, from: UnitMass.kilograms, to: targetUnit)
                        weightField?.textField.text = CustomNumberFormatting.string(from: weightValue)
                    }
                }
            )
            
            view.addSubview(nameField)
            view.addSubview(systemSeg)
            view.addSubview(weightField!)
            
            let edgeInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            
            nameField.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview().inset(edgeInset)
            }
            systemSeg.snp.makeConstraints { (make) in
                make.top.equalTo(nameField.snp.bottom)
                make.left.right.equalToSuperview().inset(edgeInset)
            }
            weightField!.snp.makeConstraints { (make) in
                make.top.equalTo(systemSeg.snp.bottom)
                make.left.right.equalToSuperview().inset(edgeInset)
                make.bottom.lessThanOrEqualToSuperview()
            }
            
            return view
        }
    )
    
    // MARK: Apple Health Sync
    
    var shouldSyncWorkouts = false
    var shouldSyncWeight = false
    var shouldAutoImportWorkouts = false
    
    func changeNextButtonTitleAppropriatelyToAppleHealth() {
        if shouldSyncWorkouts || shouldSyncWeight {
            self.nextButton.setTitle(LS["Next"], for: .normal)
        } else {
            self.nextButton.setTitle(LS["Skip"], for: .normal)
        }
    }
    
    lazy var appleHealthSyncView = SetupView(
        title: LS["Setup.AppleHealth.Title"],
        text: LS["Setup.AppleHealth.Message"],
        customViewClosure: { view -> UIView in
            
            let autoImport = SetupSwitchView(
                title: LS["Setup.AppleHealth.AutoImportWorkouts"],
                isOn: self.shouldAutoImportWorkouts,
                switchAction: { newStatus in
                    self.shouldAutoImportWorkouts = newStatus
                }
            )
            
            func toggleAutoImportOption() {
                autoImport.switch.setOn(self.shouldSyncWorkouts ? self.shouldAutoImportWorkouts : false, animated: true)
                autoImport.isUserInteractionEnabled = self.shouldSyncWorkouts
                autoImport.alpha = self.shouldSyncWorkouts ? 1 : 0.5
            }
            toggleAutoImportOption()
            
            let syncWorkouts = SetupSwitchView(
                title: LS["Setup.AppleHealth.SyncWorkouts"],
                isOn: self.shouldSyncWorkouts,
                switchAction: { newStatus in
                    self.shouldSyncWorkouts = newStatus
                    self.changeNextButtonTitleAppropriatelyToAppleHealth()
                    toggleAutoImportOption()
                }
            )
            let syncWeight = SetupSwitchView(
                title: LS["Setup.AppleHealth.SyncWeight"],
                isOn: self.shouldSyncWeight,
                switchAction: { newStatus in
                    self.shouldSyncWeight = newStatus
                    self.changeNextButtonTitleAppropriatelyToAppleHealth()
                }
            )
            
            view.addSubview(syncWorkouts)
            view.addSubview(syncWeight)
            view.addSubview(autoImport)
            
            let edgeInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            
            syncWorkouts.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview().inset(edgeInset)
            }
            syncWeight.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(edgeInset)
                make.top.equalTo(syncWorkouts.snp.bottom)
            }
            autoImport.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(edgeInset)
                make.top.equalTo(syncWeight.snp.bottom)
                make.bottom.lessThanOrEqualToSuperview()
            }
            
            return view
        }
    )
    
    // MARK: Permissions
    
    var locationPermissionGranted = false
    var motionPermissionGranted = false
    var appleHealthPermissionGranted = false
    
    func toggleButtonStatusForPermissions() {
        if locationPermissionGranted && motionPermissionGranted && (appleHealthPermissionGranted || !(shouldSyncWeight || shouldSyncWorkouts)) {
            nextButton.isEnabled = true
        } else {
            nextButton.isEnabled = false
        }
    }
    
    var healthPermissionView: SetupPermissionView?
    
    lazy var permissionsView = SetupView(
        title: LS["Setup.Permissions.Title"],
        text: LS["Setup.Permissions.Message"],
        customViewClosure: { view -> UIView in
            
            let locationPermission = SetupPermissionView(
                title: LS["Setup.Permission.Location"],
                permissionAction: { (button) in
                    PermissionManager.standard.checkLocationPermission(closure: { status in
                        if status == .granted || status == .restricted {
                            
                            self.locationPermissionGranted = true
                            self.toggleButtonStatusForPermissions()
                            button.transitionState(to: true)
                            
                            if status == .restricted {
                                
                                DispatchQueue.main.async {
                                    self.displayOpenSettingsAlert(
                                        withTitle: LS["Setup.Permission.Location.Restricted.Title"],
                                        message: LS["Setup.Permission.Location.Restricted.Message"]
                                    )
                                }
                                
                            }
                        } else {
                            self.locationPermissionGranted = false
                            self.toggleButtonStatusForPermissions()
                            button.transitionState(to: false)
                            
                            DispatchQueue.main.async {
                                self.displayOpenSettingsAlert(
                                    withTitle: LS["Error"],
                                    message: LS["Setup.Permission.Location.Error"]
                                )
                            }
                        }
                    })
                },
                buttonAction: {
                    DispatchQueue.main.async {
                        self.displayInfoAlert(withMessage: LS["Setup.Permission.Location.Message"])
                    }
                }
            )
            
            let motionPermission = SetupPermissionView(
                title: LS["Setup.Permission.Motion"],
                permissionAction: { (button) in
                    PermissionManager.standard.checkMotionPermission { (success) in
                        button.transitionState(to: success)
                        self.motionPermissionGranted = success
                        self.toggleButtonStatusForPermissions()
                        
                        if !success {
                            DispatchQueue.main.async {
                                self.displayOpenSettingsAlert(
                                    withTitle: LS["Error"],
                                    message: LS["Setup.Permission.Motion.Error"]
                                )
                            }
                        }
                    }
                },
                buttonAction: {
                    self.displayInfoAlert(withMessage: LS["Setup.Permission.Motion.Message"])
                }
            )
            
            self.healthPermissionView = SetupPermissionView(
                title: LS["Setup.Permission.AppleHealth"],
                permissionAction: { (button) in
                    PermissionManager.standard.checkHealthPermission(closure: { success in
                        button.transitionState(to: success)
                        self.appleHealthPermissionGranted = success
                        self.toggleButtonStatusForPermissions()
                        
                        if !success {
                            DispatchQueue.main.async {
                                self.displayError(withMessage: LS["Setup.Permission.AppleHealth.Error"])
                            }
                        }
                    })
                },
                buttonAction: {
                    DispatchQueue.main.async {
                        self.displayInfoAlert(withMessage: LS["Setup.Permission.AppleHealth.Message"])
                    }
                }
            )
            
            view.addSubview(locationPermission)
            view.addSubview(motionPermission)
            view.addSubview(self.healthPermissionView!)
            
            let edgeInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            
            locationPermission.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview().inset(edgeInset)
            }
            motionPermission.snp.makeConstraints { (make) in
                make.top.equalTo(locationPermission.snp.bottom)
                make.left.right.equalToSuperview().inset(edgeInset)
            }
            self.healthPermissionView!.snp.makeConstraints { (make) in
                make.top.equalTo(motionPermission.snp.bottom)
                make.left.right.equalToSuperview().inset(edgeInset)
                make.bottom.lessThanOrEqualToSuperview()
            }
            
            return view
        }
    )
}
