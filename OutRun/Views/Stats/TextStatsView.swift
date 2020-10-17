//
//  TextStatsView.swift
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

class TextStatsView: UIView {
    
    let workout: Workout
    
    let commentLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14),
        numberOfLines: 0,
        textAlignment: .left
    )
    
    init(workout: Workout) {
        self.workout = workout
        super.init(frame: .zero)
        
        DispatchQueue.main.async {
            let comment = workout.comment.value
            let modified = LS["Workout.IsUserModified.Text"]
            
            if workout.isUserModified.value && comment != nil {
                self.commentLabel.text = comment! + "\n\n" + modified
            } else if workout.isUserModified.value {
                self.commentLabel.text = modified
            } else {
                self.commentLabel.text = comment
            }
        }
        
        let headerView = WorkoutHeaderView(title: LS["Workout.Comment"])
        
        self.addSubview(headerView)
        self.addSubview(commentLabel)
        
        headerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(5)
            make.left.right.equalToSuperview()
        }
        commentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(5)
            make.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20))
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
