//
//  DebugController.swift
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
import CoreStore

class DebugController: SettingsViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(image: .close, style: .plain, target: self, action: #selector(close))
        self.navigationItem.rightBarButtonItem = closeButton
        
        self.settingsModel = SettingsModel(
            title: "Debug",
            sections: [
                SettingSection(
                    title: "Database",
                    settings: [
                        TitleSubTitleSetting(
                            title: "Database Storage Size",
                            subTitle: CustomByteFormatting.string(for: DataManager.diskSize ?? -1)
                        ),
                        TitleSubTitleSetting(
                            title: "Workouts",
                            subTitle: String(DataQueryManager.fetchCount(of: Workout.self))
                        ),
                        TitleSubTitleSetting(
                            title: "RouteDataSamples",
                            subTitle: String(DataQueryManager.fetchCount(of: WorkoutRouteDataSample.self))
                        ),
                        TitleSubTitleSetting(
                            title: "WorkoutEvents",
                            subTitle: String(DataQueryManager.fetchCount(of: WorkoutEvent.self))
                        ),
                        TitleSubTitleSetting(
                            title: "HeartRateDataSamples",
                            subTitle: String(DataQueryManager.fetchCount(of: WorkoutHeartRateDataSample.self))
                        ),
                        TitleSubTitleSetting(
                            title: "Events",
                            subTitle: String(DataQueryManager.fetchCount(of: Event.self))
                        )
                    ]
                ),
                SettingSection(
                    title: "Cache",
                    settings: [
                        TitleSubTitleSetting(
                            title: { "Cache Storage Size" },
                            subTitle: { CustomByteFormatting.string(for: CustomImageCache.mapImageCache.diskSize ?? -1) }
                        ),
                        ButtonSetting(
                            title: { "Clear Cache" },
                            selectAction: { (setting, controller, cell) in
                                CustomImageCache.mapImageCache.clear { (success) in
                                    setting.refresh()
                                    self.displayInfoAlert(
                                        withMessage: success ? "Successfully cleared cache." : "Failed to clear cache."
                                    )
                                }
                            },
                            isEnabled: { ![0, -1, nil].contains(CustomImageCache.mapImageCache.diskSize) }
                        )
                    ]
                ),
                SettingSection(
                    title: "Config",
                    settings: [
                        TitleSubTitleSetting(
                            title: "isDebug",
                            subTitle: String(Config.isDebug)
                        ),
                        TitleSubTitleSetting(
                            title: "isRunOnSimulator",
                            subTitle: String(Config.isRunOnSimulator)
                        ),
                        TitleSubTitleSetting(
                            title: "hasMobileProvision",
                            subTitle: String(Config.hasMobileProvision)
                        ),
                        TitleSubTitleSetting(
                            title: "hasSanboxReceipt",
                            subTitle: String(Config.hasSanboxReceipt)
                        )
                    ]
                )
            ]
        )
        
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
}
