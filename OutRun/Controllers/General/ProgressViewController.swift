//
//  ProgressViewController.swift
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

class ProgressViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    func setProgress(_ value: Double) {
        self.progressView.setProgress(Float(value), animated: true)
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = .backgroundColor
        
        let infoLabel = UILabel(text: LS["Loading-DoNotClose"], textColor: .primaryColor, font: .systemFont(ofSize: 16, weight: .bold), textAlignment: .center)
        progressView.progressTintColor = .accentColor
        
        self.view.addSubview(infoLabel)
        self.view.addSubview(progressView)
        
        infoLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(progressView.snp.top).offset(-10)
            make.left.right.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40))
        }
        progressView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40))
            make.center.equalToSuperview()
        }
    }
    
}

