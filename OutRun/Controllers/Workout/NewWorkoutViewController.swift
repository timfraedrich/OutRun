//
//  NewWorkoutViewController.swift
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
import RxSwift
import RxCocoa

class NewWorkoutViewController: MapViewControllerWithContainerView, UIGestureRecognizerDelegate {
    
    private let builder: WorkoutBuilder
    private let autoPauseDetection: AutoPauseDetection
    private let locationManagement: LocationManagement
    private let stepCounter: StepCounter
    private let altitudeManagement: AltitudeManagement
    private let liveStats: LiveStats
    
    var initialWorkoutType = Workout.WorkoutType(rawValue: UserPreferences.standardWorkoutType.value)
    
    var userMovedMap: Bool = false {
        didSet {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.recenterButton.isHidden = !self.userMovedMap
                }
            }
        }
    }
    
    let readinessIndicatorView = WorkoutBuilderReadinessIndicationView()
    lazy var typeView = FloatingButton(title: workoutTypeRelay.value.description) { (button) in
        let alert = WorkoutTypeAlert(
            action: { (type) in
                self.workoutTypeRelay.accept(type)
                button.setTitle(type.description.uppercased(), for: .normal)
            }
        )
        alert.present(on: self)
    }
    
    let distanceView = LabelledDataView(title: LS["Workout.Distance"])
    let durationView = LabelledDataView(title: LS["Workout.Duration"])
    let speedView = LabelledDataView(title: UserPreferences.displayRollingSpeed.value ? LS["Workout.AverageSpeed"] : LS["Workout.CurrentSpeed"])
    let paceView = LabelledDataView(title: UserPreferences.displayRollingSpeed.value ? LS["Workout.RollingPace"] : LS["Workout.TotalPace"])
    let caloriesView: LabelledDataView = LabelledDataView(title: LS["Workout.BurnedCalories"])
    
    lazy var actionButton = NewWorkoutControllerActionButton { (button, actionType) in
        
        switch actionType {
        case .start:
            self.suggestNewStatusRelay.accept(.recording)
        case .stop:
            self.suggestNewStatusRelay.accept(.ready)
        case .pauseOrContinue:
            self.suggestNewStatusRelay.accept(.paused)
        }
    }
    
    var lastLocationWhileNotCentered: CLLocation?
    lazy var recenterButton = FloatingButton(title: LS["NewWorkoutViewController.Recenter"]) { (button) in
        self.userMovedMap = false
        
        guard let location = self.lastLocationWhileNotCentered else { return }
        let camera = MKMapCamera(lookingAtCenter: location.coordinate, fromDistance: 200, pitch: 0, heading: location.course)
        self.mapView?.setCamera(camera, animated: true)
    }
    
    var routeOverlay: MKOverlay?
    
    var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    
    override func viewDidLoad() {
        
        if !UserPreferences.shouldShowMap.value {
            
            self.mapView = nil
            
        }
        
        self.headline = LS["Workout.NewWorkout"]
        mapView?.delegate = WorkoutMapViewDelegate.standard
        self.readinessIndicatorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayIndicationAlert)))
        self.recenterButton.isHidden = true
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(userInteractedWithMap(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(userInteractedWithMap(_:)))
        pan.delegate = self
        pinch.delegate = self
        self.mapView?.addGestureRecognizer(pan)
        self.mapView?.addGestureRecognizer(pinch)
        
        self.view.addSubview(blurView)
        blurView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        super.viewDidLoad()
        
        prepareLayout()
        prepareBindings()
    }
    
    @objc func displayIndicationAlert() {
        if self.readinessIndicatorView.status == .waiting {
            let alert = UIAlertController(
                title: LS["NewWorkoutViewController.WaitingAlert.Title"],
                message: LS["NewWorkoutViewController.WaitingAlert.Message"],
                preferredStyle: .alert,
                options: [
                    (
                        title: LS["Okay"],
                        style: .default,
                        action: nil
                    )
                ]
            )
            self.present(alert, animated: true)
        }
    }
    
    private var closeDisposeBag = DisposeBag()
    @objc override func close() {
        
        if builder.status.isActiveStatus {
            
            var alert: UIAlertController?
            alert = UIAlertController(
                title: LS["NewWorkoutViewController.Cancel.Error.Recording.Title"],
                message: LS["NewWorkoutViewController.Cancel.Error.Recording.Message"],
                preferredStyle: .alert,
                options: [
                    (
                        title: LS["NewWorkoutViewController.Cancel.Error.Recording.Action.StopRecording"],
                        style: .destructive,
                        action: { _ in
                            self.suggestNewStatusRelay.accept(.ready)
                            self.statusRelay.subscribe(onNext: { [weak self] status in
                                guard let self = self else { return }
                                if status == .ready {
                                    alert?.dismiss(animated: true) {
                                        self.dismiss(animated: true) {
                                            print("[NewWorkout] dismissed after saving")
                                        }
                                    }
                                } else {
                                    self.displayBuilderFailureError()
                                    print("[NewWorkout] stop tracking failed")
                                }
                                self.closeDisposeBag = DisposeBag()
                            }).disposed(by: self.closeDisposeBag)
                        }
                    ),
                    (
                        title: LS["Continue"],
                        style: .cancel,
                        action: nil
                    )
                ]
            )
            self.present(alert!, animated: true)
            
        } else {
            self.dismiss(animated: true) {
                print("[NewWorkout] dismissed")
            }
        }
    }
    
    override func addMapViewWithConstraints() {
        super.addMapViewWithConstraints()
        self.view.sendSubviewToBack(blurView)
    }
    
    func displayBuilderFailureError() {
        DispatchQueue.main.async {
            self.displayError(withMessage: LS["NewWorkoutViewController.WorkoutBuilder.Error"]
            )
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func userInteractedWithMap(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == .ended {
            self.userMovedMap = true
        }
    }
    
    // MARK: - Init
    
    public init() {
        let builder = WorkoutBuilder()
        self.builder = builder
        self.autoPauseDetection = AutoPauseDetection(builder: builder)
        self.locationManagement = LocationManagement(builder: builder)
        self.stepCounter = StepCounter(builder: builder)
        self.altitudeManagement = AltitudeManagement(builder: builder)
        self.liveStats = LiveStats(builder: builder)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let builder = WorkoutBuilder()
        self.builder = builder
        self.autoPauseDetection = AutoPauseDetection(builder: builder)
        self.locationManagement = LocationManagement(builder: builder)
        self.stepCounter = StepCounter(builder: builder)
        self.altitudeManagement = AltitudeManagement(builder: builder)
        self.liveStats = LiveStats(builder: builder)
        super.init(coder: coder)
    }
    
    // MARK: - Layout
    
    private func prepareLayout() {
        self.view.backgroundColor = .clear
        
        // MARK: adding views to superview
        self.view.addSubview(readinessIndicatorView)
        self.view.addSubview(typeView)
        self.view.addSubview(recenterButton)
        
        let speedIndication = UserPreferences.speedMeasurementType.safeValue.isPaceUnit ? paceView : speedView
        
        // MARK: adding views to statsView
        self.containerView.addSubview(distanceView)
        self.containerView.addSubview(durationView)
        self.containerView.addSubview(speedIndication)
        self.containerView.addSubview(caloriesView)
        self.containerView.addSubview(actionButton)
        
        // MARK: setting constraints
        let safeLayout = self.view.safeAreaLayoutGuide
        readinessIndicatorView.snp.makeConstraints { (make) in
            make.bottom.equalTo(containerView.snp.top).offset(-10)
            make.right.equalTo(safeLayout).offset(-10)
        }
        typeView.snp.makeConstraints { (make) in
            make.bottom.equalTo(containerView.snp.top).offset(-10)
            make.left.equalTo(safeLayout).offset(10)
        }
        recenterButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(readinessIndicatorView.snp.top).offset(-10)
            make.right.equalTo(safeLayout).offset(-10)
        }
        
        let spacing: CGFloat = 20
        
        distanceView.snp.makeConstraints { (make) in
            make.top.equalTo(containerView.snp.top).offset(spacing)
            make.left.equalTo(containerView.snp.left).offset(spacing)
        }
        durationView.snp.makeConstraints { (make) in
            make.top.equalTo(containerView.snp.top).offset(spacing)
            make.left.equalTo(distanceView.snp.right).offset(spacing)
            make.right.equalTo(containerView.snp.right).offset(-spacing)
            make.width.equalTo(distanceView)
        }
        speedIndication.snp.makeConstraints { (make) in
            make.top.equalTo(distanceView.snp.bottom).offset(spacing)
            make.left.equalTo(containerView.snp.left).offset(spacing)
        }
        caloriesView.snp.makeConstraints { (make) in
            make.top.equalTo(durationView.snp.bottom).offset(spacing)
            make.left.equalTo(speedIndication.snp.right).offset(spacing)
            make.right.equalTo(containerView.snp.right).offset(-spacing)
            make.width.equalTo(speedIndication)
        }
        actionButton.snp.makeConstraints { (make) in
            make.top.equalTo(speedIndication.snp.bottom).offset(spacing)
            make.left.equalTo(containerView.snp.left).offset(spacing)
            make.right.equalTo(containerView.snp.right).offset(-spacing)
            make.bottom.equalTo(safeLayout).offset(-spacing)
            make.height.equalTo(50)
        }
    }
    
    // MARK: - Bindings
    
    private let disposeBag = DisposeBag()
    
    private let suggestNewStatusRelay = PublishRelay<WorkoutBuilder.Status>()
    private lazy var workoutTypeRelay = BehaviorRelay<Workout.WorkoutType>(value: self.initialWorkoutType)
    
    private func prepareBindings() {
        
        liveStats.distance.drive(distanceView.rx.valueString).disposed(by: disposeBag)
        liveStats.duration.drive(durationView.rx.valueString).disposed(by: disposeBag)
        liveStats.speed.drive(speedView.rx.valueString).disposed(by: disposeBag)
        liveStats.burnedEnergy.drive(caloriesView.rx.valueString).disposed(by: disposeBag)
        liveStats.status.drive(statusBinder).disposed(by: disposeBag)
        liveStats.status.drive(statusRelay).disposed(by: disposeBag)
        liveStats.currentLocation.drive(locationBinder).disposed(by: disposeBag)
        liveStats.locations.drive(routeBinder).disposed(by: disposeBag)
        liveStats.insufficientPermission.drive(insufficientPermissionBinder).disposed(by: disposeBag)
        
        let input = WorkoutBuilder.Input(
            workoutType: workoutTypeRelay.asObservable(),
            statusSuggestion: suggestNewStatusRelay.asObservable()
        )
        _ = builder.tranform(input)
        
    }
    
    private let statusRelay = BehaviorRelay(value: WorkoutBuilder.Status.waiting)
    
    private var statusBinder: Binder<WorkoutBuilder.Status> {
        Binder(self) { `self`, status in
            self.readinessIndicatorView.status = status
            self.actionButton.transition(to: status)
            
            if status.isActiveStatus {
                self.isModalInPresentation = true
            } else {
                self.isModalInPresentation = false
            }
        }
    }
    
    private var locationBinder: Binder<TempWorkoutRouteDataSample?> {
        Binder(self) { `self`, sample in
            guard let location = sample?.clLocation else { return }
            if !self.userMovedMap {
                let camera = MKMapCamera(lookingAtCenter: location.coordinate, fromDistance: 200, pitch: 0, heading: location.course)
                self.mapView?.setCamera(camera, animated: true)
            } else {
                self.lastLocationWhileNotCentered = location
            }
        }
    }
    
    private var routeBinder: Binder<[TempWorkoutRouteDataSample]> {
        Binder(self) { `self`, routeSamples in
            let coordinates = routeSamples.map { $0.clLocationCoordinate2D }
            let newOverlay = MKPolyline(coordinates: coordinates, count: coordinates.count)
            self.mapView?.addOverlay(newOverlay, level: .aboveRoads)
            if let oldOverlay = self.routeOverlay {
                self.mapView?.removeOverlay(oldOverlay)
            }
            self.routeOverlay = newOverlay
        }
    }
    
    private var insufficientPermissionBinder: Binder<String> {
        Binder(self) { `self`, message in
            self.displayOpenSettingsAlert(
                withTitle: LS["Error"],
                message: message
            )
        }
    }
}
