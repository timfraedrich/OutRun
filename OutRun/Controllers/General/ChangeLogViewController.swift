//
//  ChangeLogViewController.swift
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

class ChangeLogViewController: UIViewController {
    
    var changeLog: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let changeLog = changeLog else {
            close()
            return
        }
        
        let effectView = UIVisualEffectView()
        let tapRec = UITapGestureRecognizer(target: self, action: #selector(close))
        effectView.addGestureRecognizer(tapRec)
        if #available(iOS 13.0, *) {
            effectView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        } else {
            effectView.effect = UIBlurEffect(style: .dark)
        }
        
        self.view.addSubview(effectView)
        self.view.backgroundColor = .none
        
        effectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let contentView = UIView()
        contentView.backgroundColor = .backgroundColor
        contentView.layer.cornerRadius = 25
        
        self.view.addSubview(contentView)
        
        let safeArea = self.view.safeAreaLayoutGuide
        
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalTo(safeArea).inset(UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25))
            make.height.equalTo(safeArea).dividedBy(1.25)
            make.centerY.equalTo(safeArea)
        }
        
        let titleLabel = UILabel(
            text: LS["ChangeLog"] + " - " + (Config.version),
            textColor: .accentColor,
            font: UIFont.systemFont(ofSize: 24, weight: .heavy).withLowerCaseSmallCaps,
            numberOfLines: 1,
            textAlignment: .left
        )
        
        let closeButton = UIButton()
        closeButton.setImage(.close, for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        let textView = UITextView()
        textView.text = changeLog
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .primaryColor
        textView.backgroundColor = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(textView)
        
        let insets = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(insets)
            make.top.equalTo(closeButton.snp.bottom).offset(10)
        }
        
        closeButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.width.equalTo(36)
        }
        
        textView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview().inset(insets)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
}
