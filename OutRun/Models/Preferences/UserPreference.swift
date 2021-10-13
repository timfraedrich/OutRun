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
import RxSwift
import RxCocoa

public enum UserPreference {
    
    public class _Base<Object>: ReactiveCompatible {
        
        public let key: String
        public let defaultValue: Object
        
        fileprivate let publisher: BehaviorRelay<Object>
        
        fileprivate init(key: String, defaultValue: Object, initialValue: Object?) {
            self.key = key
            self.defaultValue = defaultValue
            
            let initialSetKey = key + ".initialValueSet"
            if let initialValue = initialValue, !(_Base.typeSafeGet(for: initialSetKey) ?? false) {
                _Base.set(true, for: initialSetKey)
                _Base.set(initialValue, for: key)
            }
            
            self.publisher = BehaviorRelay(value: _Base.typeSafeGet(for: key) ?? defaultValue)
        }
        
        public var value: Object {
            get {
                _Base.typeSafeGet(for: key) ?? defaultValue
            } set {
                _Base.set(newValue, for: key)
                publisher.accept(newValue)
            }
        }
        
        public func delete() {
            _Base.remove(for: key)
        }
        
        private static func typeSafeGet<Object>(for key: String) -> Object? {
            return UserDefaults.standard.object(forKey: key) as? Object
        }
        
        private static func set<Object>(_ value: Object, for key: String) {
            UserDefaults.standard.set(value, forKey: key)
        }
        
        private static func remove(for key: String) {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
    }
    
    public class Required<Object>: _Base<Object> {
        public init(key: String, defaultValue: Object) {
            super.init(key: key, defaultValue: defaultValue, initialValue: nil)
        }
    }
    
    public class Optional<Object>: _Base<Object?> {
        public init(key: String, defaultValue: Object? = nil, initialValue: Object? = nil) {
            super.init(key: key, defaultValue: defaultValue, initialValue: initialValue)
        }
    }

}

public extension Reactive {
    
    func value<Object>() -> Observable<Object> where Base: UserPreference._Base<Object> {
        base.publisher.asObservable()
    }
    
}
