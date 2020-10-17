//
//  StartScreenViewController.swift
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

class StartScreenViewController: UIViewController {
    
    let headlineLabel = UILabel(
        text: LS["Setup.Headline"],
        font: UIFont.systemFont(ofSize: 32, weight: .bold),
        textAlignment: .center
    )
    
    let titleLabel = UILabel(
        text: LS["OutRun"],
        textColor: .accentColor,
        font: UIFont.systemFont(ofSize: 42, weight: .heavy).withLowerCaseSmallCaps,
        textAlignment: .center
    )
    
    let featureScrollView = UIScrollView()
    
    let startButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.accentColor
        button.setTitle(LS["Setup.StartButton"].uppercased(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .focused)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(startSetup), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .backgroundColor
        
        self.view.addSubview(headlineLabel)
        self.view.addSubview(titleLabel)
        self.view.addSubview(featureScrollView)
        self.view.addSubview(startButton)
        
        let safeLayout = self.view.safeAreaLayoutGuide
        
        headlineLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(safeLayout).inset(UIEdgeInsets(top: 40, left: 20, bottom: 0, right: 20))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(safeLayout).inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            make.top.equalTo(headlineLabel.snp.bottom)
        }
        featureScrollView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.bottom.equalTo(startButton.snp.top).offset(-20)
            make.left.right.equalTo(safeLayout).inset(UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30))
        }
        startButton.snp.makeConstraints { (make) in
            make.bottom.right.left.equalTo(safeLayout).inset(UIEdgeInsets(top: 0, left: 40, bottom: 20, right: 40))
            make.height.equalTo(50)
        }
        
        let feature1 = StartScreenFeatureView(
            title: LS["Setup.Feature.Route.Title"],
            description: LS["Setup.Feature.Route.Message"],
            image:.setupRoute
        )
        let feature2 = StartScreenFeatureView(
            title: LS["Setup.Feature.Chart.Title"],
            description: LS["Setup.Feature.Chart.Message"],
            image: .setupChart
        )
        let feature3 = StartScreenFeatureView(
            title: LS["Setup.Feature.Lock.Title"],
            description: LS["Setup.Feature.Lock.Message"],
            image: .setupLock
        )
        
        self.featureScrollView.addSubview(feature1)
        self.featureScrollView.addSubview(feature2)
        self.featureScrollView.addSubview(feature3)
        
        feature1.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.width.equalTo(featureScrollView)
        }
        feature2.snp.makeConstraints { (make) in
            make.top.equalTo(feature1.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.width.equalTo(feature1)
        }
        feature3.snp.makeConstraints { (make) in
            make.top.equalTo(feature2.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.width.equalTo(feature1)
            make.bottom.equalToSuperview()
        }
        
    }
    
    @objc func startSetup() {
        let setupController = SetupViewController()
        setupController.modalTransitionStyle = .crossDissolve
        setupController.modalPresentationStyle = .fullScreen
        self.present(setupController, animated: true, completion: nil)
    }
    
}
