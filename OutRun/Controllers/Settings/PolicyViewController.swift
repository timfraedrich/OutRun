//
//  PolicyViewController.swift
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

class PolicyViewController: DetailViewController {
    
    var type: PolicyManager.PolicyType?
    
    let policyTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .backgroundColor
        textView.textColor = .primaryColor
        textView.allowsEditingTextAttributes = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()
    
    let loadingView = LoadingView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let type = type else {
            self.headline = "Error"
            return
        }

        self.headline = type.title
        
        self.view.addSubview(policyTextView)
        self.view.addSubview(loadingView)
        
        policyTextView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            make.top.equalTo(headlineContainerView.snp.bottom).offset(10)
        }
        loadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        PolicyManager.query(for: type) { (success, error, string) in
            
            self.loadingView.isHidden = true
            
            if let error = error {
                self.policyTextView.text = "Error - " + error.localizedDescription
            } else {
                self.policyTextView.text = string ?? "Error"
            }
        }

    }
    
    override func close() {
        self.dismiss(animated: true)
    }

}
