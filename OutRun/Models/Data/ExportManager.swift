//
//  ExportManager.swift
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

public class ExportManager {
    
    /// An enumeration of types workouts can be exported as.
    public enum ExportTypes: CaseIterable {
        
        /// OutRun-Backup file
        case orbup
        /// GPX-File
        case gpx
        
        /// A string representation of the export type.
        public var title: String {
            switch self {
            case .orbup:
                return LS["WorkoutShareAlert.OutRunBackup"]
            case .gpx:
                return LS["WorkoutShareAlert.GPXExport"]
            }
        }
        
        /**
         A function performing the action needed for the export.
         - parameter completion: indicating the success and pointing to an optional URL where the file to share will be located
         */
        fileprivate func performExport(for workouts: [ORWorkoutInterface], completion: @escaping (Bool, [URL]) -> Void, progress: ((Float) -> Void)? = nil) {
            switch self {
            case .orbup:
                
                BackupManager.createBackup(
                    for: workouts,
                    completion: { success, url in
                        completion(success, [url].filterNil())
                    },
                    progress: progress ?? { _ in }
                )
                
            case .gpx:
                break
            }
        }
        
    }
    
    public static func displayShareAlert(for workouts: [ORWorkoutInterface], on controller: UIViewController) {
        
        var exportOptions: [UIAlertActionTuple]
        
        for type in ExportTypes.allCases {
            
            exportOptions.append((
                title: type.title,
                style: .default,
                action: { action in
                    ExportManager.exportBackupAlertAction(forWorkouts: [workout], controller: controller)
                }
            ))
            
        }
        
        let orBackupOption: (title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?) =
        
        let gpxOption: (title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?) = (
            title: LS["Cancle"],
            style: .default,
            action: { action in
                ExportManager.exportGPXAlertAction(for: workout, on: controller)
            }
        )
        
        let cancel: (title: String, style: UIAlertAction.Style, action: ((UIAlertAction) -> Void)?) = (
            title: LS["Cancel"],
            style: .cancel,
            action: nil
        )
        
        self.init(
            title: LS["WorkoutShareAlert.Title"],
            message: LS["WorkoutShareAlert.Message"],
            preferredStyle: .actionSheet,
            options: [
                orBackupOption,
                gpxOption,
                cancel
            ]
        )
    }
    
    /// A funtion displaying the iOS share menu on top of the given controller for a file at the given directory (provided it exists); if `shouldDeleteFileAfter` is set to true, the file at the given path will get deleted once the menu is dismissed, this might be useful if the file is saved at the temporary directory
    static func displayShareMenu(forFilesAt urls: [URL], on controller: UIViewController, shouldDeleteFileAfter shouldDelete: Bool = true) {
        
        guard !urls.isEmpty else { return }
        
        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { (type, completed, returnedItems, activityError) in
            if shouldDelete {
                do {
                    for url in urls {
                        try FileManager.default.removeItem(at: url)
                    }
                } catch {
                    print("[ExportManager] Deletion of file failed:", error.localizedDescription)
                }
            }
        }
        
        controller.present(activityVC, animated: true)
    }
    
    private static func createGPXFile(for workouts: [ORWorkoutInterface], completion: @escaping (Bool, [URL]) -> Void) {
        
        for workout in workouts {
            
            
            
        }
        
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
                print("[ExportManager] Failed to save GPX file")
                completion(false, nil)
            }
        }
    }
    
    static func exportGPXAlertAction(for workout: Workout, on controller: UIViewController) {
        ExportManager.createGPXFile(for: workout) { (success, url) in
            if let url = url {
                ExportManager.displayShareMenu(forFileAt: url, on: controller)
            } else {
                controller.displayError(withMessage: LS["ExportManager.GPX.Error"])
            }
        }
    }
    
    static func exportBackupAlertAction(forWorkouts workouts: [Workout]? = nil, controller: UIViewController) {
        let alertProgressClosure = controller.startLoading(asProgress: true, title: LS["Loading"], message: LS["Settings.ExportBackupData.Message"])
        
        BackupManager.createBackup(
            for: workouts,
            completion: { (success, url) in
                controller.endLoading {
                    if url != nil {
                        ExportManager.displayShareMenu(forFileAt: url, on: controller)
                    } else {
                        controller.displayError(withMessage: LS["ExportManager.Backup.Error"])
                    }
                }
            },
            progress: { progressValue in
                DispatchQueue.main.async {
                    alertProgressClosure?(Double(progressValue), nil)
                }
            }
        )
    }
    
}
