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
import RxSwift
import RxCocoa

class LabelledDiagramView: UIView, ChartViewDelegate, BigStatView {
    
    // MARK: - Layout
    
    fileprivate let titleLabel = UILabel(
        text: "",
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .bold)
    )
    
    fileprivate let diagram: LineChartView = {
        let chart = LineChartView()
        
        chart.backgroundColor = .backgroundColor
        chart.noDataTextColor = .secondaryColor
        chart.gridBackgroundColor = UIColor.foregroundColor.withAlphaComponent(0.5)
        chart.rightAxis.labelTextColor = .secondaryColor
        chart.xAxis.labelTextColor = .secondaryColor
        
        chart.chartDescription.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.leftAxis.enabled = false
        chart.legend.enabled = false
        chart.viewPortHandler.setMaximumScaleX(100)
        chart.viewPortHandler.setMaximumScaleY(100)
        chart.minOffset = 0
        
        return chart
    }()
    
    private func prepareLayout() {
        
        diagram.delegate = self
        
        addSubview(titleLabel)
        addSubview(diagram)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        
        diagram.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(125)
        }
    }
    
    // MARK: - Logic
    
    init(title: String = "") {
        super.init(frame: .zero)
        prepareLayout()
        self.titleLabel.text = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - ChartViewDelegate
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let sample = entry.data as? ORSampleInterface else { return }
        sampleSelectedRelay.accept(sample)
    }
    
    // MARK: - Bindings
    
    fileprivate var sampleSelectedRelay = PublishRelay<ORSampleInterface>()
    
}

extension Reactive where Base: LabelledDiagramView {
    
    var title: Binder<String> {
        Binder(base) { base, title in
            base.titleLabel.text = title
        }
    }
    
    func data<SampleType: ORSampleInterface>() -> Binder<WorkoutStatsSeries<Bool, Double, SampleType>> {
        Binder(base) { base, data in
            let dataSets: [LineChartDataSet] = data.sections.map { (highlighted, sectionData) in
                let values = sectionData.map { ChartDataEntry(x: $0, y: $1, data: $2) }
                let set = LineChartDataSet(entries: values, label: "")
                set.setColor((highlighted ? UIColor.accentColor : .gray) as NSUIColor)
                set.lineWidth = 3
                set.drawCirclesEnabled = false
                set.drawValuesEnabled = false
                set.lineCapType = .round
                return set
            }
            base.diagram.data = LineChartData(dataSets: dataSets)
        }
    }
    
    var sampleSelected: Driver<ORSampleInterface> {
        base.sampleSelectedRelay
            .throttle(.milliseconds(50), latest: true, scheduler: MainScheduler.asyncInstance)
            .asDriver(onErrorDriveWith: .never())
    }
    
    var isDisabled: Binder<Bool> {
        Binder(base) { base, isDisabled in
            base.diagram.highlightPerTapEnabled = !isDisabled
            base.diagram.highlightPerDragEnabled = !isDisabled
        }
    }
    
}
