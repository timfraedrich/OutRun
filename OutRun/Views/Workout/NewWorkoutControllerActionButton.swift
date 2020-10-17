//
//  NewWorkoutControllerActionButton.swift
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

class NewWorkoutControllerActionButton: UIView {
    
    let actionClosure: (NewWorkoutControllerActionButton, ActionType) -> Void
    private var lastStatus = WorkoutBuilder.Status.waiting
    var isAnimating = false
    
    lazy var startButton = baseButton(withTitle: LS["Start"], selector: #selector(startWorkout))
    lazy var stopButton = baseButton(withTitle: LS["Stop"], backgroundColor: .accentColor, selector: #selector(stopWorkout))
    lazy var pauseOrContinueButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .gray
        button.setImage(.pause, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 20
        button.imageView?.tintColor = .white
        button.addTarget(self, action: #selector(pauseOrContinueWorkout), for: .touchUpInside)
        return button
    }()
        
    init(actionClosure: @escaping (NewWorkoutControllerActionButton, ActionType) -> Void) {
        self.actionClosure = actionClosure
        super.init(frame: .zero)
        
        self.addSubview(stopButton)
        self.addSubview(pauseOrContinueButton)
        self.addSubview(startButton)
        
        self.startButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.stopButton.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
        }
        self.pauseOrContinueButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(stopButton.snp.left).offset(-10)
            make.width.equalTo(pauseOrContinueButton.snp.height)
        }
        
        self.startButton.isEnabled = false
        self.startButton.isUserInteractionEnabled = false
        self.stopButton.isHidden = true
        self.pauseOrContinueButton.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc func startWorkout() {
        actionClosure(self, .start)
    }
    
    @objc func stopWorkout() {
        actionClosure(self, .stop)
    }
    
    @objc func pauseOrContinueWorkout() {
        actionClosure(self, .pauseOrContinue)
    }
    
    func transition(to status: WorkoutBuilder.Status) {
        
        guard self.lastStatus != status else {
            return
        }
        
        switch (lastStatus, status) {
        case (.waiting, .ready), (.ready, .waiting):
            self.startButton.backgroundColor = status == .waiting ? .gray : .accentColor
            self.startButton.isEnabled = status == .ready
            self.startButton.isUserInteractionEnabled = status == .ready
        case (.recording, .paused), (.paused, .recording), (.autoPaused, .paused):
            self.pauseOrContinueButton.setImage(status == .paused ? .play : .pause, for: .normal)
        case (.recording, .ready), (.paused, .ready), (.autoPaused, .ready), (.ready, .recording):
            self.stopButton.isHidden = status == .ready
            self.pauseOrContinueButton.isHidden = status == .ready
            self.startButton.isHidden = status != .ready
        case (.recording, .autoPaused), (.autoPaused, .recording):
            break
        case (.ready, .autoPaused), (.ready, .paused):
            self.stopButton.isHidden = false
            self.pauseOrContinueButton.isHidden = false
            self.startButton.isHidden = true
            self.pauseOrContinueButton.setImage(status == .paused ? .play : .pause, for: .normal)
        default:
            print("[NewWorkoutControllerActionButton] invalid transition: (oldStatus: \(self.lastStatus), newStatus: \(status)")
            return
        }
        
        self.lastStatus = status
        
    }
    
    private func baseButton(withTitle title: String, backgroundColor: UIColor = .gray, selector: Selector) -> UIButton {
        let button = UIButton()
        button.backgroundColor = backgroundColor
        button.setTitle(title, for: .normal)
        button.setTitle("...", for: .disabled)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }
    
    enum ActionType {
        case start, stop, pauseOrContinue
    }
}
