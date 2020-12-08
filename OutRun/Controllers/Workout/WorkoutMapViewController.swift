//
//  WorkoutMapViewController.swift
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

class WorkoutMapViewController: MapViewControllerWithContainerView, LabelledDiagramViewDelegate {
    
    var workout: Workout?
    var stats: WorkoutStats?
    
    var annotation: MKPointAnnotation?
    lazy var marker = MKMarkerAnnotationView(annotation: self.annotation, reuseIdentifier: nil)
    
    lazy var diagramView = LabelledDiagramView(title: "", delegate: self)
    
    lazy var segementedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        
        if #available(iOS 13.0, *) {
            control.styleLikeIOS12()
        }
        
        control.insertSegment(withTitle: LS["WorkoutStats.Altitude"], at: 0, animated: false)
        control.insertSegment(withTitle: LS["WorkoutStats.Speed"], at: 1, animated: false)
        
        control.selectedSegmentIndex = 0
        
        control.addTarget(self, action: #selector(displayDiagramData(sender:)), for: .valueChanged)
        
        return control
    }()
    
    lazy var compass: MKCompassButton = {
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .adaptive
        return compass
    }()
    
    lazy var mapTypeButton = FloatingButton(
        title: LS["Standard"].uppercased(),
        action: { button in
            
            func option(for type: MKMapType) -> (title: String, style: UIAlertAction.Style, action: (UIAlertAction) -> Void) {
                let title: String = {
                    switch type {
                    case .standard:
                        return LS["Standard"]
                    case .hybrid:
                        return LS["MapView.MapType.Hybrid"]
                    case .satellite:
                        return LS["MapView.MapType.Satellite"]
                    default:
                        return LS["Error"]
                    }
                }()
                
                return (
                    title: title,
                    style: .default,
                    action: { action in
                        self.mapView?.mapType = type
                        button.setTitle(title.uppercased(), for: .normal)
                    }
                )
            }
            
            let alert = UIAlertController(
                title: LS["MapView.MapTypeAlert.Title"],
                message: LS["MapView.MapTypeAlert.Message"],
                preferredStyle: .alert,
                options: [
                    option(for: .standard),
                    option(for: .hybrid),
                    option(for: .satellite),
                    (
                        title: LS["Cancel"],
                        style: .cancel,
                        action: nil
                    )
                ]
            )
            
            self.present(alert, animated: true)
        }
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .backgroundColor
        
        self.view.addSubview(compass)
        self.view.addSubview(mapTypeButton)
        
        compass.snp.makeConstraints { (make) in
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(-20)
        }
        mapTypeButton.snp.makeConstraints { (make) in
            make.left.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(-10)
        }
        
        guard let workout = workout else {
            print("Workout map controller dismissed, because workout == nil")
            self.dismiss(animated: true)
            return
        }
        
        self.headline = LS["WorkoutMapController.Headline"]
        
        if let mapView = self.mapView {
            WorkoutMapViewManager.setupRoute(forWorkout: workout, mapView: mapView, customEdgePadding: UIEdgeInsets(top: 100, left: 20, bottom: 50, right: 20)) {
                print("Map set up")
            }
        }
        
        self.displayDiagramData(sender: segementedControl)
        
        containerView.addSubview(segementedControl)
        containerView.addSubview(diagramView)
        
        let spacing = 20
        
        segementedControl.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(containerView.safeAreaLayoutGuide).inset(spacing)
            make.height.equalTo(30)
        }
        diagramView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(containerView.safeAreaLayoutGuide).inset(spacing)
            make.top.equalTo(segementedControl.snp.bottom).offset(spacing / 2)
        }
    }
    
    override func close() {
        self.dismiss(animated: true)
    }
    
    @objc func displayDiagramData(sender: UISegmentedControl) {
        
        guard let stats = stats else {
            return
        }
        
        switch sender.selectedSegmentIndex {
        case 0:
            stats.queryAltitudes { (success, series) in
                if let series = series {
                    let convertedSections = series.convertedForChartView(includeSamples: true, yUnit: UserPreferences.altitudeMeasurementType.safeValue)
                    self.diagramView.title = LS["WorkoutStats.Altitude"]
                    self.diagramView.setData(for: convertedSections)
                }
            }
        case 1:
            stats.querySpeeds { (success, series) in
                if let series = series {
                    let convertedSections = series.convertedForChartView(includeSamples: true, yUnit: UserPreferences.speedMeasurementType.safeValue)
                    self.diagramView.title = LS["WorkoutStats.Speed"]
                    self.diagramView.setData(for: convertedSections)
                }
            }
        default:
            break
        }
        
    }
    
    func didSelect(sample: TempWorkoutSeriesDataSampleType) {
        DispatchQueue.main.async {
            if let sample = sample as? TempWorkoutRouteDataSample {
                if self.annotation == nil {
                    self.annotation = MKPointAnnotation()
                    self.mapView?.addAnnotation(self.annotation!)
                }
                let latitude = sample.latitude
                let longitude = sample.longitude
                self.annotation!.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? false {
                segementedControl.styleLikeIOS12()
            }
        }
    }
    
}
