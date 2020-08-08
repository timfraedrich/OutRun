//
//  WorkoutListCell.swift
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
import MapKit
import SnapKit

class WorkoutListCell: UITableViewCell, MKMapViewDelegate, ApplicationStateObserver {
    
    let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.accentColor.withAlphaComponent(0.25)
        return view
    }()
    
    let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 4
        view.layer.borderColor = UIColor.accentColor.cgColor
        return view
    }()
    
    lazy var headerView: UIView = WorkoutListHeader(dayIdentifier: workout.dayIdentifier.value)
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .foregroundColor
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        if self.workout.isRace.value {
            view.layer.borderColor = UIColor.accentColor.withAlphaComponent(0.5).cgColor
            view.layer.borderWidth = 4
        }
        return view
    }()
    
    let infoView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    let typeLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .bold)
    )
    
    let distanceLabel = UILabel(textColor: .primaryColor)
    
    let durationLabel = UILabel(textColor: .secondaryColor)
    
    let mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.backgroundColor.withAlphaComponent(0.5)
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        return imageView
    }()
    
    var workout: Workout

    init(workout: Workout) {
        
        self.workout = workout
        
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none
        self.backgroundColor = .backgroundColor
        
        self.addSubview(lineView)
        self.addSubview(circleView)
        self.addSubview(headerView)
        self.addSubview(containerView)
        
        lineView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(18)
            make.width.equalTo(4)
        }
        circleView.snp.makeConstraints { (make) in
            make.centerY.equalTo(containerView)
            make.centerX.equalTo(lineView.snp.centerX)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
        headerView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
        containerView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(10)
            make.left.equalTo(lineView.snp.right).offset(18)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        containerView.addSubview(infoView)
        containerView.addSubview(mapImageView)
        
        infoView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(mapImageView.snp.left).offset(20)
            make.centerY.equalToSuperview()
        }
        mapImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(120)
            make.width.equalTo(containerView.snp.width).dividedBy(2)
        }
        
        infoView.addSubview(typeLabel)
        infoView.addSubview(distanceLabel)
        infoView.addSubview(durationLabel)
        
        typeLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        distanceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        durationLabel.snp.makeConstraints { (make) in
            make.top.equalTo(distanceLabel.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            
        }
        
        self.setup()
        self.startObservingApplicationState()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setup() {
        self.typeLabel.text = workout.type.description.uppercased()
        
        self.loadLabels()
        
        if workout.hasRouteData {
            self.loadImage()
        } else {
            self.mapImageView.isHidden = true
        }
    }
    
    func loadImage() {
        let request = WorkoutMapImageRequest(workoutUUID: workout.uuid.value, size: .list) { (success, image) in
            if let image = image {
                self.mapImageView.image = image
            } else {
                self.mapImageView.isHidden = true
            }
        }
        WorkoutMapImageManager.execute(request)
    }
    
    func loadLabels() {
        
        let distanceMeasurement = NSMeasurement(doubleValue: workout.distance.value, unit: UnitLength.meters)
        let distanceString = CustomMeasurementFormatting.string(forMeasurement: distanceMeasurement, type: .distance, rounding: .wholeNumbers)
        let attributedDistanceString = WorkoutListCell.attributedStringWithBigNumbers(withString: distanceString, fontSize: 36)
        self.distanceLabel.attributedText = attributedDistanceString
        
        let durationMeasurement = NSMeasurement(doubleValue: workout.activeDuration.value, unit: UnitDuration.seconds)
        let timeString = CustomMeasurementFormatting.string(forMeasurement: durationMeasurement, type: .time, rounding: .wholeNumbers)
        let attributedTimeString = WorkoutListCell.attributedStringWithBigNumbers(withString: timeString, fontSize: 24)
        self.durationLabel.attributedText = attributedTimeString
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.accentColor
        renderer.lineCap = .round
        return renderer
    }
    
    private static func attributedStringWithBigNumbers(withString string: String, fontSize: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string.lowercased(), attributes: [.font:UIFont.systemFont(ofSize: fontSize, weight: .bold).withLowerCaseSmallCaps])
        for substring in string.components(separatedBy: " ") where NumberFormatter().number(from: substring) != nil {
            let numberRange = (string as NSString).range(of: substring, options: .numeric)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize, weight: .bold), range: numberRange)
        }
        return attributedString as NSAttributedString
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? false {
                self.circleView.layer.borderColor = UIColor.accentColor.cgColor
                self.mapImageView.image = nil
                self.loadImage()
                if workout.isRace.value {
                    self.containerView.layer.borderColor = UIColor.accentColor.withAlphaComponent(0.5).cgColor
                }
            }
        }
    }
    
    func didUpdateApplicationState(to state: ApplicationState) {
        if state == .foreground {
            self.loadImage()
        }
    }
    
}
