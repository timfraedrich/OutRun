//
//  WorkoutActionView.swift
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

class WorkoutActionView: UIView {

    let workout: Workout
    let controller: UIViewController
    let action: ((Workout, WorkoutActionView) -> Void)?
    let titleClosure: (() -> String)
    
    let button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .foregroundColor
        button.layer.cornerRadius = 15
        return button
    }()

    convenience init(title: String, color: UIColor = .accentColor, controller: UIViewController, workout: Workout, action: ((Workout, WorkoutActionView) -> Void)? = nil) {
        
        self.init(
            title: {
                return title
            },
            color: color,
            controller: controller,
            workout: workout,
            action: action
        )
    }
    
    init(title: @escaping (() -> String), color: UIColor = .accentColor, controller: UIViewController, workout: Workout, action: ((Workout, WorkoutActionView) -> Void)? = nil) {
        
        self.workout = workout
        self.controller = controller
        self.action = action
        self.titleClosure = title
        
        button.setTitle(title(), for: .normal)
        button.setTitleColor(color, for: .normal)
        
        super.init(frame: .zero)
        self.backgroundColor = .backgroundColor
        
        self.button.addTarget(self, action: #selector(action(button:)), for: .touchUpInside)
        
        self.addSubview(button)
        
        button.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.height.equalToSuperview()
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func action(button: UIButton) {
        DispatchQueue.main.async {
            guard let buttonAction = self.action else {
                print("Error: action for WorkoutActionView not implemented")
                return
            }
            buttonAction(self.workout, self)
        }
    }
    
    func updateTitle() {
        DispatchQueue.main.async {
            self.button.setTitle(self.titleClosure(), for: .normal)
        }
    }
    
}
