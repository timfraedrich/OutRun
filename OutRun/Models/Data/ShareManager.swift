//
//  ShareManager.swift
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
import CoreGPX

enum ShareManager {
    
    /// A funtion displaying the iOS share menu on top of the given controller for a file at the given directory (provided it exists); if `shouldDeleteFileAfter` is set to true, the file at the given path will get deleted once the menu is dismissed, this might be useful if the file is saved at the temporary directory
    static func displayShareMenu(forFileAt url: URL?, on controller: UIViewController, shouldDeleteFileAfter shouldDelete: Bool = true) {
        
        guard let url = url else {
            return
        }
        let objectsToShare = [url]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { (type, completed, returnedItems, activityError) in
            if shouldDelete {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print("[ShareManager] Deletion of (\(url)) failed")
                }
            }
        }
        
        controller.present(activityVC, animated: true)
    }
    
    private static func createGPXFile(for workout: Workout, completion: @escaping (Bool, URL?) -> Void) {
        DataQueryManager.querySectionedSampleSeries(for: workout, sampleType: WorkoutRouteDataSample.self) { (success, sections) in
            
            guard success, !sections.isEmpty, let sections = sections as? [(type: WorkoutStatsSeriesSection.SectionType, samples: [TempWorkoutRouteDataSample])] else {
                completion(false, nil)
                return
            }
            
            let root = GPXRoot(creator: "OutRun")
            
            let metadata = GPXMetadata()
            metadata.desc = "This GPX-File was created by OutRun"
            metadata.time = Date()
            
            root.metadata = metadata
            
            let track = GPXTrack()
            
            for section in sections where section.type == .active {
                
                let trackPoints = section.samples.map { (sample) -> GPXTrackPoint in
                    let trackPoint = GPXTrackPoint()
                    trackPoint.latitude = sample.latitude
                    trackPoint.longitude = sample.longitude
                    trackPoint.elevation = sample.altitude
                    trackPoint.time = sample.timestamp
                    return trackPoint
                }
                
                let trackSegement = GPXTrackSegment()
                trackSegement.trackpoints = trackPoints
                track.add(trackSegment: trackSegement)
                
            }
            
            root.add(track: track)
            
            let fileName = CustomTimeFormatting.backupTimeCode(forDate: workout.startDate.value)
            let directoryUrl = FileManager.default.temporaryDirectory
            let fullURL = directoryUrl.appendingPathComponent(fileName + ".gpx")
            
            do {
                try root.outputToFile(saveAt: directoryUrl, fileName: fileName)
                completion(true, fullURL)
            } catch {
                print("[ShareManager] Failed to save GPX file")
                completion(false, nil)
            }
        }
    }
    
    static func exportGPXAlertAction(for workout: Workout, on controller: UIViewController) {
        ShareManager.createGPXFile(for: workout) { (success, url) in
            if let url = url {
                ShareManager.displayShareMenu(forFileAt: url, on: controller)
            } else {
                controller.displayError(withMessage: LS["ShareManager.GPX.Error"])
            }
        }
    }
    
    static func exportBackupAlertAction(forWorkouts workouts: [Workout]? = nil, controller: UIViewController) {
        let alertProgressClosure = controller.startLoading(asProgress: true, title: LS["Loading"], message: LS["Settings.ExportBackupData.Message"])
        
        BackupManager.createBackup(
            forWorkouts: workouts,
            completion: { (success, url) in
                controller.endLoading {
                    if url != nil {
                        ShareManager.displayShareMenu(forFileAt: url, on: controller)
                    } else {
                        controller.displayError(withMessage: LS["ShareManager.Backup.Error"])
                    }
                }
            },
            progressClosure: { progressValue in
                DispatchQueue.main.async {
                    alertProgressClosure?(progressValue, nil)
                }
            }
        )
    }
    
}
