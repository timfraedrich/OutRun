//
//  LabelledDiagramView.swift
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
import Charts

class LabelledDiagramView: UIView, ChartViewDelegate, BigStatView {
    
    private let headlineLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .bold)
    )
    
    let diagram: LineChartView = {
        let chart = LineChartView()
        
        chart.backgroundColor = .backgroundColor
        chart.noDataTextColor = .secondaryColor
        chart.gridBackgroundColor = UIColor.foregroundColor.withAlphaComponent(0.5)
        chart.rightAxis.labelTextColor = .secondaryColor
        chart.xAxis.labelTextColor = .secondaryColor
        
        chart.chartDescription?.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.leftAxis.enabled = false
        chart.legend.enabled = false
        chart.viewPortHandler.setMaximumScaleX(100)
        chart.viewPortHandler.setMaximumScaleY(100)
        chart.minOffset = 0
        
        return chart
    }()
    
    var delegate: LabelledDiagramViewDelegate?
    var title: String
    
    init(title: String, sections: [(color: UIColor, data: [(Measurement<Unit>, Measurement<Unit>)], samples: [TempWorkoutSeriesDataSampleType])]? = nil, delegate: LabelledDiagramViewDelegate? = nil) {
        self.title = title
        
        super.init(frame: .zero)
        
        self.delegate = delegate
        self.diagram.delegate = self
        
        self.setTitle()
        if let sections = sections {
            self.setData(for: sections)
        }
        
        self.addSubview(headlineLabel)
        self.addSubview(diagram)
        
        headlineLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        diagram.snp.makeConstraints { (make) in
            make.top.equalTo(headlineLabel.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(125)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.title = ""
        super.init(coder: aDecoder)
    }
    
    func setData(for sections: [(color: UIColor, data: [(Measurement<Unit>, Measurement<Unit>)], samples: [TempWorkoutSeriesDataSampleType])]) {
        
        var dataSets = [LineChartDataSet]()
        
        for section in sections {
            var values = [ChartDataEntry]()
            
            for (index, dataEntry) in section.data.enumerated() {
                
                let sample: TempWorkoutSeriesDataSampleType? = section.samples.indices.contains(index) ? section.samples[index] : nil
                let entry = ChartDataEntry(x: dataEntry.0.value, y: dataEntry.1.value, data: sample)
                
                values.append(entry)
            }
            
            let set = LineChartDataSet(entries: values, label: nil)
            set.setColor(section.color as NSUIColor)
            set.lineWidth = 3
            set.drawCirclesEnabled = false
            set.drawValuesEnabled = false
            set.lineCapType = .round
            
            dataSets.append(set)
        }
        
        diagram.data = LineChartData(dataSets: dataSets)
        
        let dataPoint = sections.first?.data.first
        setTitle(units: dataPoint != nil ? (dataPoint!.0.unit, dataPoint!.1.unit) : nil)
    }
    
    func setTitle(units: (Unit, Unit)? = nil) {
        
        guard let units = units else {
            self.headlineLabel.text = self.title
            return
        }
        
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        let unitString = formatter.string(from: units.1) + "-" + formatter.string(from: units.0)
        
        self.headlineLabel.text = (self.title + "  -  " + unitString).uppercased()
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        DispatchQueue.main.async {
            if let delegate = self.delegate {
                guard let sample = entry.data as? TempWorkoutSeriesDataSampleType else {
                    return
                }
                delegate.didSelect(sample: sample)
            }
        }
    }
    
    func disableSelection() {
        self.diagram.highlightPerTapEnabled = false
        self.diagram.highlightPerDragEnabled = false
    }
}
