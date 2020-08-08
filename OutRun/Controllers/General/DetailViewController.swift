//
//  DetailViewController.swift
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

class DetailViewController: UIViewController {
    
    var headline = "" {
        didSet {
            self.headlineLabel.text = headline
        }
    }
    
    let headlineLabel: UILabel = {
        let label = UILabel(font: UIFont.systemFont(ofSize: 32, weight: .heavy).withLowerCaseSmallCaps)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(.close, for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        return button
    }()
    
    let headlineContainerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .backgroundColor
        
        self.view.addSubview(headlineContainerView)
        
        headlineContainerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        
        headlineContainerView.addSubview(headlineLabel)
        headlineContainerView.addSubview(closeButton)
        
        let safeArea = self.headlineContainerView.safeAreaLayoutGuide
        
        headlineLabel.snp.makeConstraints { (make) in
            make.top.equalTo(safeArea).offset(40)
            make.left.equalTo(safeArea).offset(20)
            make.right.equalTo(safeArea).offset(-60)
            make.bottom.equalToSuperview().offset(-10)
        }
        closeButton.snp.makeConstraints { (make) in
            make.top.equalTo(safeArea).offset(8)
            make.right.equalTo(safeArea).offset(-10)
            make.height.width.equalTo(36)
        }
    }
    
    // MARK: needs to be overridden in subclass for advanced functionality
    @objc func close() {
        self.dismiss(animated: true)
    }

}
