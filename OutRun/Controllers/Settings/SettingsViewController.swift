//
//  SettingsViewController.swift
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

class SettingsViewController: UITableViewController {
    
    var settingsModel: SettingsModel? {
        didSet {
            self.refreshTableView()
        }
    }
    var settingsModelClosure: (() -> SettingsModel)? {
        didSet {
            self.updateSettingsModel()
            self.refreshTableView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.view.backgroundColor = .backgroundColor
        
        self.navigationItem.title = settingsModel?.title ?? LS["Settings"]
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .backgroundColor
        tableView.separatorColor = .tableViewSeparator
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateSettingsModel()
        self.refreshTableView()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return settingsModel?.sections.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsModel?.safeSection(sectionIndex: section)?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let setting = settingsModel?.safeSetting(indexPath: indexPath) else {
            return UITableViewCell()
        }
        
        if var keyboardAvoidingSetting = setting as? KeyboardAvoidanceSetting {
            keyboardAvoidingSetting.registerForKeyboardAvoidanceClosure = { cell in
                self.cellShouldBeVisisble = cell
            }
        }
        
        let cell = setting.tableViewCell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let setting = settingsModel?.safeSetting(indexPath: indexPath) else {
            return
        }
        setting.runSelectAction(controller: self)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsModel?.safeSection(sectionIndex: section)?.title
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let str = settingsModel?.safeSection(sectionIndex: section)?.message
        return str != nil ? str! + "\n" : nil
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func updateSettingsModel() {
        if let closure = self.settingsModelClosure {
            self.settingsModel = closure()
        }
    }
    
    public var cellShouldBeVisisble: UITableViewCell?
    private var formerContentOffset: CGPoint?
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        self.formerContentOffset = self.tableView.contentOffset

        if let cell = self.cellShouldBeVisisble, let indexPath = self.tableView.indexPath(for: cell), let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            let offsetHeight = keyboardHeight - self.view.safeAreaInsets.bottom
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: offsetHeight, right: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        if let offset = self.formerContentOffset {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.tableView.scrollRectToVisible(CGRect(origin: offset, size: CGSize(width: self.tableView.frame.width, height: 44)), animated: true)
            self.formerContentOffset = nil
        }
    }
    
    func refreshTableView() {
        self.navigationItem.title = self.settingsModel?.title ?? LS["Settings"]
        self.tableView.reloadData()
    }
    
    /// NOTE: This function is supposed to be overridded
    func notifyOfPresentation(_ settingsViewController: SettingsViewController) {}
    
}
