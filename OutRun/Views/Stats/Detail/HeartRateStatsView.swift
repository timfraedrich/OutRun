//
//  HeartRateStatsView.swift
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
import HealthKit

class HeartRateStatsView: StatsView {
    
    
    var heartRateChart: LabelledDiagramView?
    let startDate: Date
    let endDate: Date

    init(stats: WorkoutStats) {
        self.startDate = stats.startDate
        self.endDate = stats.endDate

        var statViews = [StatView]()
        self.heartRateChart = LabelledDiagramView(title: LS("WorkoutStats.HeartRateOverTime"))
        statViews.append(contentsOf: [self.heartRateChart!])

        super.init(title: LS("WorkoutStats.HeartRate"), statViews: statViews)

        // View is hidden to start, so heart rate data is fetched async
        self.isHidden = true
        self.loadHeartRateData(stats:stats)
    }

    private func loadHeartRateData(stats: WorkoutStats) {
        HealthQueryManager.getHeartRateSamples(startDate: self.startDate, endDate: self.endDate) { samples in
            DispatchQueue.main.async {
                let hasHeartRateData = !samples.isEmpty
                self.heartRateChart?.disableSelection()

                if hasHeartRateData {
                    guard let series = HeartRateStatsView.generateWorkoutStatsSeries(heartRateSamples:samples, stats:stats)
                    else {
                        return
                    }

                    let convertedSections = series.convertedForChartView(includeSamples: false, yUnit: UnitCount.count)
                    self.heartRateChart?.setData(for: convertedSections)
                    self.isHidden = false
                }
            }

        }
    }

    private static func generateWorkoutStatsSeries(heartRateSamples: [TempWorkoutHeartRateDataSample], stats: WorkoutStats) -> WorkoutStatsSeries? {
        var finishedSeriesSections: [WorkoutStatsSeriesSection] = []
        var currentSamples: [TempWorkoutHeartRateDataSample] = []
        var currentSectionData: [(x: NSMeasurement, y: NSMeasurement)] = []

        func createAndAddSectionFromData() {
            if !currentSectionData.isEmpty {

                let section = WorkoutStatsSeriesSection(
                    type:  .paused,
                    data: currentSectionData,
                    associatedDataSamples: currentSamples.compactMap({ (sample) -> TempWorkoutSeriesDataSampleType? in
                        return sample

                    })
                )
                finishedSeriesSections.append(section)

                if let lastSample = currentSamples.last, let lastDataPoint = currentSectionData.last {
                    currentSamples = []
                    currentSectionData = []
                    currentSamples.append(lastSample)
                    currentSectionData.append(lastDataPoint)
                } else {
                    currentSamples = []
                    currentSectionData = []
                }

            }
        }

        for (index, sample) in heartRateSamples.enumerated() {
            let x = NSMeasurement(doubleValue: stats.startDate.distance(to: sample.timestamp), unit: UnitDuration.seconds)
            let y = NSMeasurement(doubleValue: sample.heartRate, unit: UnitCount.count)
            let dataObject = (x: x, y: y)

            currentSectionData.append(dataObject)
            currentSamples.append(sample)

            if index == heartRateSamples.count - 1 {
                createAndAddSectionFromData()
            }
        }

        return WorkoutStatsSeries(sectioningType: .activeAndPaused, sections: finishedSeriesSections)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
