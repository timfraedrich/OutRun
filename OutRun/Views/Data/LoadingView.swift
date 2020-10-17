//
//  LoadingView.swift
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

class LoadingView: UIView {
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        let loadingIndicator = UIActivityIndicatorView(style: {
            if #available(iOS 13.0, *) {
                return .large
            } else {
                return .gray
            }
        }())
        loadingIndicator.startAnimating()
        self.addSubview(loadingIndicator)
        
        let label = UILabel(text: LS["Loading"], textColor: .secondaryColor, font: .systemFont(ofSize: 14, weight: .medium), textAlignment: .center)
        self.addSubview(label)
        
        loadingIndicator.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        label.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(loadingIndicator.snp.bottom).offset(10)
            make.width.equalTo(100)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
