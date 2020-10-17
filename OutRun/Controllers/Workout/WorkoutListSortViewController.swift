//
//  WorkoutListSortViewController.swift
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

class WorkoutListSortViewController: ClearSettingsViewController, UIPopoverPresentationControllerDelegate {
    
    var listController: WorkoutListViewController?
    
    var filterTypes: [WorkoutListViewController.WorkoutListFilterType] {
        return listController?.filterTypes ?? []
    }
    var sortType: WorkoutListViewController.WorkoutListSortType? {
        return listController?.sortType
    }
    var isDescending: Bool {
        return sortType?.descending ?? true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        let possibleTypeFilterTypes: [WorkoutListViewController.WorkoutListFilterType] = [.type(.running), .type(.walking), .type(.hiking), .type(.cycling), .type(.skating)]
        
        func removeAnyTypeFiltersFromFilterList() {
            self.listController?.filterTypes.removeAll(where: { (type) -> Bool in
                possibleTypeFilterTypes.contains(type)
            })
        }
        
        func typeFilterSelectionSetting(for workoutType: Workout.WorkoutType?) -> Setting {
            SelectionSetting(
                title: { workoutType?.description ?? LS["All"] },
                isSelected: {
                    guard let workoutType = workoutType else {
                        return !(self.listController?.filterTypes.contains(where: { (filterType) -> Bool in
                            possibleTypeFilterTypes.contains(filterType)
                        }) ?? false)
                    }
                    return self.listController?.filterTypes.contains(.type(workoutType)) ?? false
                },
                selectAction: { (setting, controller, cell) in
                    removeAnyTypeFiltersFromFilterList()
                    if let workoutType = workoutType {
                        self.listController?.filterTypes.append(.type(workoutType))
                    }
                    setting.refresh()
                }
            )
        }
        
        func filterSwitchSetting(for type: WorkoutListViewController.WorkoutListFilterType) -> Setting {
            SwitchSetting(
                title: { type.string },
                isSwitchOn: { self.filterTypes.contains(type) },
                switchToggleAction: { (newValue, setting) in
                    if newValue {
                        self.listController?.filterTypes.append(type)
                    } else {
                        self.listController?.filterTypes.removeAll { (existingType) -> Bool in
                            existingType == type
                        }
                    }
                }
            )
        }
        
        func orderSelectionSetting(for descendingType: WorkoutListViewController.WorkoutListSortType, _ ascendingType:  WorkoutListViewController.WorkoutListSortType) -> SelectionSetting {
            SelectionSetting(
                title: descendingType.string,
                isSelected: { self.sortType == descendingType || self.sortType == ascendingType },
                selectAction: { (setting, controller, cell) in
                    self.listController?.sortType = self.isDescending ? descendingType : ascendingType
                }
            )
        }
        
        self.settingsModel = SettingsModel(
            title: "",
            sections: [
                SettingSection(
                    title: LS["WorkoutList.Filter"],
                    settings: [
                        TitleSubTitleSetting(
                            title: WorkoutListViewController.WorkoutListFilterType.type(.unknown).string,
                            subTitle: { (listController?.filterTypes.first { (type) -> Bool in
                                possibleTypeFilterTypes.contains(type)
                                })?.workoutType?.description ?? LS["All"]
                            }(),
                            doesRedirect: true,
                            selectAction: { (setting, controller, cell) in
                                
                                let clearController = ClearSettingsViewController()
                                clearController.settingsModel = SettingsModel(
                                    title: "",
                                    sections: [
                                        SettingSection(
                                            title: LS["Workout.Type"],
                                            settings: [
                                                typeFilterSelectionSetting(for: nil),
                                                typeFilterSelectionSetting(for: .running),
                                                typeFilterSelectionSetting(for: .walking),
                                                typeFilterSelectionSetting(for: .hiking),
                                                typeFilterSelectionSetting(for: .cycling),
                                                typeFilterSelectionSetting(for: .skating)
                                            ]
                                        )
                                    ]
                                )
                                controller.notifyOfPresentation(clearController)
                                controller.show(clearController, sender: controller)
                            }
                        ),
                        filterSwitchSetting(for: .isRace)
                    ]
                ),
                SettingSection(
                    title: LS["WorkoutList.SortBy"],
                    settings: [
                        orderSelectionSetting(for: .day(true), .day(false)),
                        orderSelectionSetting(for: .distance(true), .distance(false))/*,
                        orderSelectionSetting(for: .duration(true), .duration(false))*/
                    ]
                ),
                SettingSection(
                    title: LS["WorkoutList.Order"],
                    settings: [
                        SwitchSetting(
                            title: { LS["WorkoutList.Order.Descending"] },
                            isSwitchOn: { self.isDescending },
                            isEnabled: { true },
                            switchToggleAction: { (newValue, setting) in
                                self.listController?.sortType = self.sortType?.oppositeOrderedType ?? .day(newValue)
                            }
                        )
                    ]
                )
            ]
        )
        
        let dismissButton = UIButton()
        dismissButton.setTitle(LS["Done"], for: .normal)
        dismissButton.setTitleColor(.accentColor, for: .normal)
        dismissButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        dismissButton.titleLabel?.adjustsFontForContentSizeCategory = true
        dismissButton.backgroundColor = .foregroundColor
        dismissButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(close), for: .touchUpOutside)
        
        self.navigationController?.view.addSubview(dismissButton)
        
        dismissButton.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(50)
        }
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func notifyOfPresentation(_ settingsViewController: SettingsViewController) {
        UIView.animate(withDuration: 0.1) {
            self.view.alpha = 0
        }
        settingsViewController.tableView.contentInset = self.tableView.contentInset
        settingsViewController.tableView.backgroundColor = .clear
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
}
