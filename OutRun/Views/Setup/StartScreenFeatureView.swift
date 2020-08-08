//
//  StartScreenFeatureView.swift
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

class StartScreenFeatureView: UIView {
    
    let imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    let titleLabel = UILabel(
        textColor: .primaryColor,
        font: .systemFont(ofSize: 14, weight: .bold),
        numberOfLines: 0
    )
    
    let textLabel = UILabel(
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 14, weight: .medium),
        numberOfLines: 0
    )
    
    init(title: String, description: String, image: UIImage?) {
        super.init(frame: .zero)
        
        self.titleLabel.text = title
        self.textLabel.text = description
        self.imageView.image = image?.withRenderingMode(.alwaysTemplate)
        
        self.addSubview(titleLabel)
        self.addSubview(textLabel)
        self.addSubview(imageView)
        
        imageView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0))
            make.width.equalTo(60)
            make.width.equalTo(imageView.snp.height)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(imageView.snp.right).offset(15)
            make.top.right.equalToSuperview()
        }
        textLabel.snp.makeConstraints { (make) in
            make.left.equalTo(imageView.snp.right).offset(15)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
