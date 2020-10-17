//
//  RouteStatsView.swift
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

class RouteStatsView: UIView, ApplicationStateObserver {
    
    let headerView: WorkoutHeaderView
    let workout: Workout
    let stats: WorkoutStats
    let controller: UIViewController
    
    let mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .foregroundColor
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let noDataLabel: UILabel = {
        let label = UILabel(
            text: LS["NoDataAvailable"],
            font: .systemFont(ofSize: 14),
            textAlignment: .center)
        label.isHidden = true
        return label
    }()
    
    init(controller: UIViewController, workout: Workout, stats: WorkoutStats) {
        
        self.headerView = WorkoutHeaderView(title: LS["WorkoutStats.Route"])
        
        self.controller = controller
        self.workout = workout
        self.stats = stats
        
        super.init(frame: .zero)
        self.backgroundColor = .backgroundColor
        
        self.addSubview(headerView)
        self.addSubview(mapImageView)
        
        mapImageView.addSubview(noDataLabel)
        
        headerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(5)
            make.left.right.equalToSuperview()
        }
        noDataLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30))
        }
        mapImageView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(5)
            make.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 5, right: 20))
            make.height.equalTo(300)
        }
        
        DispatchQueue.main.async {
            if workout.hasRouteData {
                let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openMapController))
                tapRecognizer.numberOfTapsRequired = 1
                self.mapImageView.isUserInteractionEnabled = true
                self.mapImageView.addGestureRecognizer(tapRecognizer)
                self.loadImage()
            } else {
                self.noDataLabel.isHidden = false
            }
        }
        
        self.startObservingApplicationState()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func loadImage() {
        let request = WorkoutMapImageRequest(workoutUUID: workout.uuid.value, size: .stats, highPriority: true) { (success, image) in
            if let image = image {
                self.mapImageView.image = image
            } else {
                self.mapImageView.isHidden = true
            }
        }
        WorkoutMapImageManager.execute(request)
    }
    
    @objc func openMapController() {
        let workoutMapController = WorkoutMapViewController()
        workoutMapController.workout = self.workout
        workoutMapController.stats = self.stats
        
        self.controller.showDetailViewController(workoutMapController, sender: self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? false {
                self.mapImageView.image = nil
                self.loadImage()
            }
        }
    }
    
    func didUpdateApplicationState(to state: ApplicationState) {
        if state == .foreground {
            self.loadImage()
        }
    }
    
}
