//
//  MapViewControllerWithContainerView.swift
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

class MapViewControllerWithContainerView: DetailViewController {
    
    var mapView: MKMapView? = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.mapType = .standard
        return mapView
    }()
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.layer.cornerRadius = 25
        return view
    }()
    
    override func viewDidLoad() {
        
        self.view.addSubview(containerView)
        self.addMapViewWithConstraints()
        
        super.viewDidLoad()
        
        let safeLayout = self.view.safeAreaLayoutGuide
        
        containerView.snp.makeConstraints { (make) in
            if let mapView = self.mapView {
                make.top.equalTo(mapView.snp.bottom).offset(-25)
            }
            make.bottom.equalToSuperview()
            make.left.equalTo(safeLayout.snp.left)
            make.right.equalTo(safeLayout.snp.right)
        }
    }
    
    func addMapViewWithConstraints() {
        if let mapView = self.mapView {
            self.view.addSubview(mapView)
            self.view.sendSubviewToBack(mapView)
            mapView.snp.makeConstraints { (make) in
                make.top.equalTo(self.view.snp.top)
                make.left.equalTo(self.view.snp.left)
                make.right.equalTo(self.view.snp.right)
                make.bottom.equalTo(self.containerView.snp.top).offset(25)
            }
        }
    }
    
    override func close() {
        self.dismiss(animated: true)
    }
    
}

