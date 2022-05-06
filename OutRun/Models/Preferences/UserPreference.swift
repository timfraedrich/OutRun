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
    
    fileprivate class _Base<Object> {
        
        let key: String
        let publisher: BehaviorRelay<Object?>
        
        init(key: String) {
            self.key = key
            self.publisher = BehaviorRelay(value: _Base.typeSafeGet(for: key))
        }
        
        func get() -> Object? {
            return _Base.typeSafeGet(for: key)
        }
        
        func set(_ value: Object?) {
            guard let value = value else { remove(); return }
            UserDefaults.standard.set(value, forKey: key)
        }
        
        func setInitial(_ value: Object?) {
            guard let value = value else { return }
            let initialSet = _Base<Bool>(key: key + ".initialValueSet")
            guard !(initialSet.get() ?? false) else { return }
            set(value)
            initialSet.set(true)
        }
        
        func remove() {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        private static func typeSafeGet<Object>(for key: String) -> Object? {
            return UserDefaults.standard.object(forKey: key) as? Object
        }
        
    }
    
    public class Required<Object> {
        
        fileprivate let _base: _Base<Object>
        public var key: String { _base.key }
        public let defaultValue: Object
        
        init(key: String, defaultValue: Object, initialValue: Object? = nil) {
            self._base = _Base(key: key)
            self.defaultValue = defaultValue
            self._base.setInitial(initialValue)
        }
        
        var value: Object {
            get { _base.get() ?? defaultValue }
            set { _base.set(newValue) }
        }
        
        func delete() {
            _base.remove()
        }
        
    }
    
    public class Optional<Object> {
        
        fileprivate let _base: _Base<Object>
        public var key: String { _base.key }
        public let defaultValue: Object?
        
        public init(key: String, defaultValue: Object? = nil, initialValue: Object? = nil) {
            self._base = _Base(key: key)
            self.defaultValue = defaultValue
            self._base.setInitial(initialValue)
        }
        
        public var value: Object? {
            get { _base.get() ?? defaultValue }
            set { _base.set(newValue) }
        }
        
        public func delete() {
            _base.remove()
        }
    }
}

public extension Reactive {
    
    func value<Object>() -> Observable<Object> where Base: UserPreference.Required<Object> {
        base._base.publisher.map { $0 ?? base.defaultValue }.asObservable()
    }
    
    func value<Object>() -> Observable<Object?> where Base: UserPreference.Optional<Object> {
        base._base.publisher.map { $0 ?? base.defaultValue }.asObservable()
    }
}
