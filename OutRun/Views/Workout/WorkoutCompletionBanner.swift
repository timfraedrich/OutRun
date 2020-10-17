//
//  WorkoutCompletionBanner.swift
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

import Foundation
import UIKit

class WorkoutCompletionBanner: ORBaseBanner {
    
    private var handler: WorkoutCompletionActionHandler
    
    private let titleLabel: UILabel = UILabel(
        text: LS["NewWorkoutCompletion.Title"],
        textColor: .primaryColor,
        font: .systemFont(ofSize: 24, weight: .bold),
        numberOfLines: 1
    )
    
    private let saveButton: UIButton = {
        
        let button = UIButton()
        
        button.setTitle(LS["Save"], for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .accentColor
        button.layer.cornerRadius = 10
        
        return button
        
    }()
    
    private let continueButton: UIButton = {
        
        let button = UIButton()
        
        button.setTitle(LS["Continue"], for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .foregroundColor
        button.layer.cornerRadius = 10
        
        return button
        
    }()
    
    private let discardButton: UIButton = {
        
        let button = UIButton()
        
        button.setTitle(LS["Discard"], for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .foregroundColor
        button.layer.cornerRadius = 10
        
        return button
        
    }()
    
    @objc private func saveWorkout() {
        
        handler.saveWorkout()
        self.dismiss()
        
    }
    
    @objc private func continueWorkout() {
        
        handler.continueWorkout()
        self.dismiss()
        
    }
    
    @objc private func discardWorkout() {
        
        handler.discardWorkout()
        self.dismiss()
        
    }
    
    init(handler: WorkoutCompletionActionHandler) {
        
        self.handler = handler
        
        super.init(isDismissable: false)
        
        let spacing = 10
        let buttonHeight = 40
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(saveButton)
        contentView.addSubview(continueButton)
        contentView.addSubview(discardButton)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(buttonHeight)
        }
        
        continueButton.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(spacing)
            make.left.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-spacing)
            make.height.equalTo(buttonHeight)
        }
        
        discardButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalTo(continueButton)
            make.left.equalTo(continueButton.snp.right).offset(spacing)
            make.height.equalTo(buttonHeight)
            make.width.equalTo(continueButton)
        }
        
        self.saveButton.addTarget(self, action: #selector(saveWorkout), for: .touchUpInside)
        self.continueButton.addTarget(self, action: #selector(continueWorkout), for: .touchUpInside)
        self.discardButton.addTarget(self, action: #selector(discardWorkout), for: .touchUpInside)
        
        onDismiss = { banner in
            
            self.saveWorkout()
            
        }
        
    }
    
    required init?(coder: NSCoder) {
        
        return nil
        
    }
    
}
