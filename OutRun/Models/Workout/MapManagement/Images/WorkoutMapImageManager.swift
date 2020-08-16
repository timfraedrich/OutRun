//
//  WorkoutMapImageManager.swift
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

import MapKit
import UIKit

/// An enum containing static functions and properties, dedicated to rendering workout map images.
enum WorkoutMapImageManager {
    
    private static var internalStatus = Status.idle {
        didSet {
            if oldValue == .suspended {
                executeNextInQueue()
            }
        }
    }
    private static var requestQueue = WorkoutMapImageQueue()
    private static let processQueue = DispatchQueue(label: "processQueue", qos: .userInitiated)
    private static let snapshotQueue = DispatchQueue(label: "snapshotQueue")
    
    /// A funtion for the execution of a WorkoutMapImageRequest, adding it to the running WorkoutMapImageQueue. If cached this method directly executes the closure, not rendering the image again.
    ///
    /// - Parameter request: An instance of WorkoutMapImageRequest indicating the type of image being requested
    public static func execute(_ request: WorkoutMapImageRequest) {
        
        if let id = request.cacheIdentifier(), let image = CustomImageCache.mapImageCache.getMapImage(for: id) {
            request.completion(true, image)
            return
        }
        
        requestQueue.add(request)
        if internalStatus == .idle {
            executeNextInQueue()
        }
    }
    
    /// A function suspending the rendering process of new map images to limit cpu cost. This function should only be used when the app enters the background, to ensure that it does not get terminated by the system.
    public static func suspendRenderProcess() {
        processQueue.suspend()
        snapshotQueue.suspend()
        internalStatus = .suspended
    }
    
    /// A Funtion resuming the rendering process of new map images after it was suspended by `suspendRenderProcess()`.
    public static func resumeRenderProcess() {
        processQueue.resume()
        snapshotQueue.resume()
        internalStatus = .idle
    }
    
    private static func executeNextInQueue() {
        
        if internalStatus == .suspended {
            return
        }
        
        guard let request = requestQueue.pendingRequests.first else {
            internalStatus = .idle
            return
        }
        
        internalStatus = .running
        
        let imageUsesDarkMode = Config.isDarkModeEnabled
        let completion: (Bool, UIImage?) -> Void = { (success, image) in
            requestQueue.remove(request)
            DispatchQueue.main.async {
                request.completion(success, image)
                executeNextInQueue()
            }
        }
        
        guard let uuid = request.workoutUUID else {
            completion(false, nil)
            return
        }
        
        DataQueryManager.fetchLocationDegreesOfRoute(fromWorkoutID: uuid) { (success, degrees) in
            if success {
                
                processQueue.async {
                    
                    guard let degrees = degrees, degrees.count > 0 else {
                        completion(false, nil)
                        return
                    }
                    
                    let route = MKPolyline(coordinates: degrees, count: degrees.count)
                    
                    let mapSnapshotOptions = MKMapSnapshotter.Options()
                    mapSnapshotOptions.region = MKCoordinateRegion(route.boundingMapRect.insetBy(dx: route.boundingMapRect.width * -0.1, dy: route.boundingMapRect.height * -0.1))
                    mapSnapshotOptions.scale = UIScreen.main.scale
                    mapSnapshotOptions.size = request.size.rawSize
                    mapSnapshotOptions.showsBuildings = true
                    mapSnapshotOptions.showsPointsOfInterest = false
                    mapSnapshotOptions.mapType = .standard
                    if #available(iOS 13.0, *) {
                        mapSnapshotOptions.traitCollection = UITraitCollection(userInterfaceStyle: imageUsesDarkMode ? .dark : .light)
                    }
                    
                    let snapshotter = MKMapSnapshotter(options: mapSnapshotOptions)
                    
                    snapshotter.start(with: snapshotQueue, completionHandler: { snapshot, error in
                        if error == nil, let snapshot = snapshot {
                            let image = snapshot.image
                            
                            UIGraphicsBeginImageContextWithOptions(request.size.rawSize, true, 0)
                            image.draw(at: CGPoint.zero)
                            
                            let context = UIGraphicsGetCurrentContext()
                            context!.setLineWidth(3.0)
                            context!.setLineCap(.round)
                            context!.setStrokeColor(UIColor.accentColor.cgColor)
                            context!.move(to: snapshot.point(for: degrees[0]))
                            for i in 0...(degrees.count - 1) {
                                context!.addLine(to: snapshot.point(for: degrees[i]))
                                context!.move(to: snapshot.point(for: degrees[i]))
                            }
                            context!.strokePath()
                            let resultImage = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                            
                            if let image = resultImage, let id = request.cacheIdentifier(forDarkAppearance: imageUsesDarkMode) {
                                CustomImageCache.mapImageCache.set(mapImage: image, for: id)
                            }
                            
                            DispatchQueue.main.async {
                                
                                completion(true, resultImage)
                                
                                if Config.isDarkModeEnabled != imageUsesDarkMode {
                                    self.requestQueue.add(request)
                                }
                                
                            }
                            
                        } else {
                            completion(false, nil)
                        }
                    })
                }
            } else {
                completion(false, nil)
            }
        }
        
    }
    
    private enum Status {
        case idle, running, suspended
    }
    
}
