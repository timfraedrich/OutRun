//
//  UserPreference.swift
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

import Foundation

enum UserPreference {

    class Required<Object> {
        
        let key: String
        let defaultValue: Object
        
        init(key: String, defaultValue: Object) {
            self.key = key
            self.defaultValue = defaultValue
        }
        
        var value: Object {
            get {
                let value = UserDefaults.standard.object(forKey: self.key) as? Object
                return value ?? defaultValue
            } set {
                UserDefaults.standard.set(newValue, forKey: self.key)
            }
        }
        
        func delete() {
            UserDefaults.standard.removeObject(forKey: self.key)
        }
        
    }
    
    class Optional<Object> {
        
        let key: String
        let defaultValue: Object?
        
        init(key: String, defaultValue: Object? = nil, initialValue: Object? = nil) {
            self.key = key
            self.defaultValue = defaultValue
            let initialValueKey = key + ".initialValueSet"
            if initialValue != nil && !UserDefaults.standard.bool(forKey: initialValueKey) {
                self.value = initialValue!
                UserDefaults.standard.set(true, forKey: initialValueKey)
            }
        }
        
        var value: Object? {
            get {
                let value = UserDefaults.standard.object(forKey: self.key) as? Object
                return value ?? defaultValue
            } set {
                guard let newValue = newValue else {
                    UserDefaults.standard.removeObject(forKey: self.key)
                    return
                }
                UserDefaults.standard.set(newValue, forKey: self.key)
            }
        }
        
        func delete() {
            UserDefaults.standard.removeObject(forKey: self.key)
        }
        
    }

}
