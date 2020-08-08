//
//  StatsView.swift
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
import Foundation

class StatsView: UIView {
    
    let headerView: WorkoutHeaderView
    let contentView = UIView()
    
    init(title: String, statViews: [StatView]) {
        
        self.headerView = WorkoutHeaderView(title: title, color: .accentColor)
        
        super.init(frame: .zero)
        
        self.addSubview(headerView)
        self.addSubview(contentView)
        self.backgroundColor = .backgroundColor
        
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(5)
            make.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
        }
        
        var unfinishedStackView: UIStackView?
        var lastView: UIView?
        for (index, statView) in statViews.enumerated() {
            
            func constraint(for view: UIView) {
                view.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    if let last = lastView {
                        make.top.equalTo(last.snp.bottom).offset(7)
                    } else {
                        make.top.equalToSuperview()
                    }
                }
            }
            
            if statView is SmallStatView {
                
                if let stackView = unfinishedStackView {
                    
                    stackView.addArrangedSubview(statView)
                    unfinishedStackView = nil
                    
                } else {
                    
                    let stackView = newStackView()
                    stackView.addArrangedSubview(statView)
                    unfinishedStackView = stackView
                    contentView.addSubview(stackView)
                    constraint(for: stackView)
                    lastView = stackView
                    
                }
                
            } else if statView is BigStatView {
                
                unfinishedStackView = nil
                contentView.addSubview(statView)
                constraint(for: statView)
                lastView = statView
                
            }
            
            if (index + 1 == statViews.count), let last = lastView {
                last.snp.makeConstraints { (make) in
                    make.bottom.equalToSuperview()
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        self.headerView = WorkoutHeaderView(title: "nil")
        super.init(coder: coder)
    }
    
    private func newStackView() -> UIStackView {
        
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
        
    }
    
}
