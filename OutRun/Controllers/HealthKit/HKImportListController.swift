//
//  HKImportListController.swift
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

class HKImportListController: UITableViewController {
    
    var queriedObjects: [HKWorkoutQueryObject] = [] {
        didSet {
            self.noDataLabel.isHidden = !(self.queriedObjects.count == 0)
        }
    }
    
    let noDataLabel = UILabel(
        text: LS["NoData.Message"],
        textColor: .secondaryColor,
        font: .systemFont(ofSize: 16, weight: .bold),
        textAlignment: .center
    )
    
    lazy var importButton = UIBarButtonItem(title: LS["ImportList.ImportAll"], style: .plain, target: self, action: #selector(importAll))
    
    override func viewDidLoad() {
        
        self.navigationItem.title = LS["ImportList.Title"]
        self.view.backgroundColor = .backgroundColor
        
        self.navigationItem.rightBarButtonItem = importButton
        self.importButton.isEnabled = false
        
        self.tableView.addSubview(noDataLabel)
        noDataLabel.snp.makeConstraints { (make) in
            make.center.equalTo(self.tableView.safeAreaLayoutGuide)
        }
        self.noDataLabel.isHidden = true
        
        self.tableView.separatorStyle = .none
        
        self.startQuery()
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queriedObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object = queriedObjects[indexPath.row]
        return HKImportObjectCell(queryObject: object)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let alert = UIAlertController(
            title: LS["HKImport.Alert.Title"],
            message: LS["HKImport.Alert.Title"],
            preferredStyle: .alert,
            options: [
                (
                    title: LS["No"],
                    style: .cancel,
                    action: nil
                ),
                (
                    title: LS["Yes"],
                    style: .default,
                    action: { _ in
                        
                        let object = self.queriedObjects[indexPath.row]
                        _ = self.startLoading {
                            DataManager.saveWorkout(for: object) { (success, error, workout) in
                                self.endLoading {
                                    if success {
                                        self.queriedObjects.remove(at: indexPath.row)
                                        tableView.deleteRows(at: [indexPath], with: .automatic)
                                    } else {
                                        self.displayError(withMessage: LS["HKImport.Error"])
                                    }
                                }
                            }
                        }
                    }
                )
        ])
        self.present(alert, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func importAll() {
        let alert = UIAlertController(
            title: LS["HKImport.ImportAll.Alert.Title"],
            message: LS["HKImport.ImportAll.Alert.Title"],
            preferredStyle: .alert,
            options: [
                (
                    title: LS["No"],
                    style: .cancel,
                    action: nil
                ),
                (
                    title: LS["Yes"],
                    style: .default,
                    action: { _ in
                        
                        _ = self.startLoading {
                            DataManager.saveWorkouts(for: self.queriedObjects) { (success, error, workouts) in
                                self.endLoading {
                                    if !success {
                                        self.displayError(withMessage: LS["HKImport.ImportAll.Error"], dismissAction: { _ in
                                            self.startQuery()
                                        })
                                    } else {
                                        self.startQuery()
                                    }
                                }
                            }
                        }
                    }
                )
        ])
        
        self.present(alert, animated: true)
    }
    
    private func startQuery() {
        _ = self.startLoading {
            
            HealthQueryManager.queryExternalWorkouts { (success, objects) in
                DispatchQueue.main.async {
                    
                    self.endLoading {
                        if success {
                            self.queriedObjects = objects
                            self.tableView.reloadData()
                            self.importButton.isEnabled = !objects.isEmpty
                        } else {
                            self.displayError(withMessage: LS["ImportList.Error.FetchFailed.Message"]) { (_) in
                                self.dismiss(animated: true)
                            }
                            self.importButton.isEnabled = false
                        }
                    }
                }
            }
        }
    }
    
}
