//
//  WorkoutControllerView.swift
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
import Charts

class WorkoutViewController: DetailViewController {
    
    var workout: Workout?
    
    let contentView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .backgroundColor
        return scrollView
    }()
    
    let dateLabel = UILabel(
        textColor: .secondaryColor,
        font: UIFont.systemFont(ofSize: 14, weight: .bold)
    )
    
    let shareButton: UIButton = {
        let button = UIButton()
        button.setImage(.share, for: .normal)
        button.addTarget(self, action: #selector(share), for: .touchUpInside)
        return button
    }()
    
    let loadingView = LoadingView()
    
    override func viewDidLoad() {
        
        self.headline = workout?.type.description ?? "ERROR"
        self.dateLabel.text = (CustomTimeFormatting.dayString(forDate: workout?.startDate.value ?? .init(timeIntervalSince1970: 0)).uppercased() ) + (workout?.isRace.value ?? false ? " - " + LS["Workout.Race"] : "").uppercased()
        super.viewDidLoad()
        
        headlineContainerView.addSubview(dateLabel)
        headlineContainerView.addSubview(shareButton)
        
        dateLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(headlineLabel.snp.top)
            make.left.equalTo(headlineLabel)
        }
        shareButton.snp.makeConstraints { (make) in
            make.top.equalTo(headlineContainerView.safeAreaLayoutGuide).offset(10)
            make.right.equalTo(closeButton.snp.left).offset(-10)
            make.height.width.equalTo(32)
        }
        
        self.view.addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(headlineContainerView.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
        }
        
        self.view.addSubview(loadingView)
        
        loadingView.snp.makeConstraints { (make) in
            make.center.equalTo(contentView)
        }
        
        self.setupContent()
    }
    
    private func setupContent() {
        
        DispatchQueue.main.async {
            guard let workout = self.workout else {
                return
            }
            
            DataQueryManager.queryStats(for: workout) { stats in
                
                self.loadingView.isHidden = true
                
                guard let stats = stats else {
                    self.displayError(withMessage: LS["WorkoutViewController.LoadingError"]) { _ in
                        self.close()
                    }
                    return
                }
                
                let distanceStatsView = DistanceStatsView(stats: stats)
                let timeStatsView = TimeStatsView(stats: stats)
                let speedStatsView = SpeedStatsView(stats: stats)
                let energyStatsView = EnergyStatsView(stats: stats)
                let routeStatsView = RouteStatsView(controller: self, workout: workout, stats: stats)
                let deleteView = DeleteWorkoutView(controller: self, workout: workout)
                let editView = EditWorkoutView(controller: self, workout: workout)
                let commentView = TextStatsView(workout: workout)
                let appleHealthView = WorkoutActionView(title: { () -> String in
                    workout.healthKitUUID.value != nil ? LS["AppleHealth.Remove"] : LS["AppleHealth.Add"]
                }, controller: self, workout: workout) { (workout, actionView) in
                    
                    func updateOrShowError(for success: Bool, message: String) {
                        if success {
                            actionView.updateTitle()
                        } else {
                            self.displayError(withMessage: message)
                        }
                    }
                    
                    if workout.healthKitUUID.value == nil {
                        
                        HealthStoreManager.saveHealthWorkout(forWorkout: workout) { (success, hkWorkout) in
                            updateOrShowError(for: success, message: LS["AppleHealth.Add.Error"])
                        }
                        
                    } else {
                        
                        HealthStoreManager.deleteHealthWorkout(fromWorkout: workout) { (success) in
                            updateOrShowError(for: success, message: LS["AppleHealth.Remove.Error"])
                        }
                        
                    }
                }
                
                self.contentView.addSubview(distanceStatsView)
                self.contentView.addSubview(timeStatsView)
                self.contentView.addSubview(speedStatsView)
                self.contentView.addSubview(editView)
                self.contentView.addSubview(deleteView)
                
                distanceStatsView.snp.makeConstraints { (make) in
                    make.left.right.top.equalToSuperview()
                    make.width.equalToSuperview()
                }
                timeStatsView.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(distanceStatsView.snp.bottom).offset(20)
                }
                speedStatsView.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(timeStatsView.snp.bottom).offset(20)
                }
                editView.snp.makeConstraints { (make) in
                    make.left.equalToSuperview().offset(20)
                    make.right.equalTo(deleteView.snp.left).offset(-20)
                    make.width.equalTo(deleteView)
                    make.bottom.equalTo(deleteView)
                }
                deleteView.snp.makeConstraints { (make) in
                    make.right.equalToSuperview().offset(-20)
                    make.bottom.equalToSuperview().offset(-20)
                }
                
                var firstActionView: UIView?
                var lastView: UIView?
                
                self.contentView.addSubview(appleHealthView)
                
                appleHealthView.snp.makeConstraints { (make) in
                    make.right.left.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
                    make.bottom.equalTo(deleteView.snp.top).offset(-20)
                }
                
                firstActionView = appleHealthView
                
                if stats.hasRouteSamples && stats.hasEnergyValue {
                    
                    self.contentView.addSubview(energyStatsView)
                    self.contentView.addSubview(routeStatsView)
                    
                    energyStatsView.snp.makeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.top.equalTo(speedStatsView.snp.bottom).offset(20)
                    }
                    routeStatsView.snp.makeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.top.equalTo(energyStatsView.snp.bottom).offset(20)
                    }
                    
                    lastView = routeStatsView
                    
                } else if stats.hasRouteSamples {
                    
                    self.contentView.addSubview(routeStatsView)
                    
                    routeStatsView.snp.makeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.top.equalTo(speedStatsView.snp.bottom).offset(20)
                    }
                    
                    lastView = routeStatsView
                    
                } else if stats.hasEnergyValue {
                    
                    self.contentView.addSubview(energyStatsView)
                    
                    energyStatsView.snp.makeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.top.equalTo(speedStatsView.snp.bottom).offset(20)
                    }
                    
                    lastView = energyStatsView
                    
                } else {
                    
                    lastView = speedStatsView
                    
                }
                
                if (workout.comment.value != nil || workout.isUserModified.value), let lastView = lastView, let firstActionView = firstActionView {
                    
                    self.contentView.addSubview(commentView)
                    
                    commentView.snp.makeConstraints({ (make) in
                        make.bottom.equalTo(firstActionView.snp.top).offset(-30)
                        make.top.equalTo(lastView.snp.bottom).offset(20)
                        make.left.right.equalToSuperview()
                    })
                    
                } else {
                    
                    lastView?.snp.makeConstraints({ (make) in
                        make.bottom.equalTo((firstActionView ?? deleteView).snp.top).offset(-30)
                    })
                    
                }
            }
        }
    }
    
    override func close() {
        self.dismiss(animated: true)
    }
    
    @objc func share() {
        if let workout = self.workout {
            let shareAlert = WorkoutShareAlert(controller: self, workout: workout)
            self.present(shareAlert, animated: true)
        }
    }
    
}
