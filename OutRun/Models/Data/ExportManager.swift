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
        
        /// A string describing what might have gone wrong while exporting to the specific type.
        fileprivate var errorMessage: String {
            switch self {
            case .orbup:
                return LS["ExportManager.Backup.Error"]
            case .gpx:
                return LS["ExportManager.GPX.Error"]
            }
        }
        
        static func exportTypes(for inclusionType: DataInclusionType) -> [ExportTypes] {
            switch inclusionType {
            case .all, .someEvents(_):
                return [.orbup]
            case .someWorkouts(_):
                return ExportTypes.allCases
            }
        }
        
        /**
         A function performing the action needed for the export.
         - parameter completion: a closure to be performed when the export is finished
         - parameter success: indicating the success of the export
         - parameter urls: a list pointing to the files to be exported
         */
        fileprivate func performExport(for inclusionType: DataInclusionType, completion: @escaping (_ success: Bool, _ urls: [URL]) -> Void) {
            switch self {
            case .orbup:
                
                BackupManager.createBackup(
                    for: inclusionType,
                    completion: { success, url in
                        completion(success, [url].filterNil())
                    }
                )
                
            case .gpx:
                
                ExportManager.createGPXFiles(
                    for: inclusionType,
                    completion: { (success, urls) in
                        completion(success, urls)
                    }
                )
            }
        }
    }
    
    /**
     A function displaying a custom share alert to export workout data to different formats.
     - parameter workouts: the workouts that are supposed to be shared
     - parameter controller: the `UIViewController` the alert is supposed to be shown on
     */
    static func displayShareAlert(for inclusionType: DataInclusionType, on controller: UIViewController) {
        
        var alertOptions: [UIAlertActionTuple] = []
        
        for type in ExportTypes.exportTypes(for: inclusionType) {
            
            alertOptions.append((
                title: type.title,
                style: .default,
                action: { _ in
                    _ = controller.startLoading {
                        type.performExport(for: inclusionType) { (success, files) in
                            controller.endLoading {
                                displayShareMenu(for: files, on: controller)
                            }
                        }
                    }
                }
            ))
        }
        
        alertOptions.append((
            title: LS["Cancel"],
            style: .cancel,
            action: nil
        ))
        
        let alert = UIAlertController(
            title: LS["WorkoutShareAlert.Title"],
            message: LS["WorkoutShareAlert.Message"],
            preferredStyle: .actionSheet,
            options: alertOptions
        )
        
        controller.present(alert, animated: true)
    }
    
    /** A funtion displaying the iOS share menu on top of the given controller for files at the given directory.
     - parameter urls: the urls pointing to the files to be shared
     - parameter shoudlDeleteAfter: a boolean indicating if the files are supposed to be deleted once the menu is dismissed, this might be useful if the files are saved at a temporary directory
     */
    private static func displayShareMenu(for urls: [URL], on controller: UIViewController, shouldDeleteAfter shouldDelete: Bool = true) {
        
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
    
    /**
     A function transforming workout route data to GPX files.
     - parameter workouts: the workouts that are supposed to be converted
     - parameter completion: a closure being performed upon completion
     - parameter success: a boolean indicating the success of the operation
     - parameter urls: a list of urls pointing to the created files
     */
    private static func createGPXFiles(for inclusionType: DataInclusionType, completion: @escaping (_ success: Bool, _ urls: [URL]) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        switch inclusionType {
        case .someWorkouts(let workouts):
            
            var urls = [URL]()
            
            for workout in workouts {
                
                let metadata = GPXMetadata()
                metadata.desc = "This GPX-File was created by OutRun"
                metadata.time = Date()
                
                let trackPoints = workout.routeData.map { (sample) -> GPXTrackPoint in
                    let trackPoint = GPXTrackPoint()
                    trackPoint.latitude = sample.latitude
                    trackPoint.longitude = sample.longitude
                    trackPoint.elevation = sample.altitude
                    trackPoint.time = sample.timestamp
                    return trackPoint
                }
                
                let trackSegement = GPXTrackSegment()
                trackSegement.add(trackpoints: trackPoints)
                
                let track = GPXTrack()
                track.add(trackSegment: trackSegement)
                
                let root = GPXRoot(creator: "OutRun")
                root.metadata = metadata
                root.add(track: track)
                
                let fileName = CustomDateFormatting.backupTimeCode(forDate: workout.startDate)
                let directoryUrl = FileManager.default.temporaryDirectory
                let fullURL = directoryUrl.appendingPathComponent(fileName + ".gpx")
                
                do {
                    try root.outputToFile(saveAt: directoryUrl, fileName: fileName)
                    urls.append(fullURL)
                } catch {
                    print("[ExportManager] Failed to save GPX file")
                }
            }
            
            completion(true, urls)
            
        default:
            fatalError("[ExportManager] Trying to create GPX files from incompatiple DataInclusionType: \(inclusionType)")
        }
    }
    
    /// An enumeration describing the possible cases of including database objects in an export.
    enum DataInclusionType {
        /// Every object in the database will be included.
        case all
        /// Only the provided workouts (if represented through a valid ORWorkoutInterface) will be included, their attached events will be disgarded.
        case someWorkouts([ORWorkoutInterface])
        /// The provided events and their corresponding workouts will be included.
        case someEvents([OREventInterface])
    }
    
}
