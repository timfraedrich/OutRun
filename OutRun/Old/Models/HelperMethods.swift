//
//  HelperMethods.swift
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

/**
 This function can be used to query a value through a closure which will be performed on a specific thread to ensure thread safety without needing to perform a the whole operation a said thread.
 
 Usage Example:
 ```
 var property: PropertyType? {
     threadSafeSyncReturn { () -> PropertyType? in
         // Note: this would be a property which can only be accessed on a specfic thread
         return self._property.value
     }
 }
 ```
 Note that you can return an object of any data type with this method, for using Optionals just extend the type you want to return with a question mark.
 
 - warning: Since this method is synchronous, running it can lead to performance issues.
 - parameter thread: the DispatchQueue the closure is supposed to be performed on, by standard the main queue
 - parameter closure: the closure being performed to return the value
 - returns: an object of the data type clarified by the return of the closure
 */
public func threadSafeSyncReturn<ReturnType>(thread: DispatchQueue = .main, _ closure: @escaping () -> ReturnType) -> ReturnType {
    
    guard Thread.current != Thread.main else {
        return closure()
    }
    
    var returnValue: ReturnType?
    
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    
    thread.async {
        returnValue = closure()
        dispatchGroup.leave()
    }
    
    dispatchGroup.wait()
    
    return returnValue!
    
}

/**
 This function can be used to intentionally throw a fatal error when a specific property is accessed.
 
 Usage Example:
 ```
 var property: PropertyType? {
     throwOnAccess()
 }
 ```
 
 - warning: Make sure to only adopt this method if necessary; the function will do exactly as told and crash the app upon access which can lead to unexpected behaviour in production
 */
public func throwOnAccess<ReturnType>() -> ReturnType {
    fatalError("\nThrowing because of illegal access: check for proper implementation of all protocols")
}

/**
 This function can be used to create a closure being performed on the main thread from another one.
 
 Usage Example:
 ```
 let safeCompletion = safeClosure(from: completion)
 ```
 
 - parameter closure: the closure that is supposed to be performed on the main thread
 */
public func safeClosure<Parameter>(from closure: @escaping (Parameter) -> Void) -> ((Parameter) -> Void) {
    return { parameter in
        DispatchQueue.main.async {
            closure(parameter)
        }
    }
}
/**
 This function can be used to create a closure being performed on the main thread from another one.
 
 Usage Example:
 ```
 let safeCompletion = safeClosure(from: completion)
 ```
 
 - parameter closure: the closure that is supposed to be performed on the main thread
 */
public func safeClosure<Parameter1, Parameter2>(from closure: @escaping (Parameter1, Parameter2) -> Void) -> ((Parameter1, Parameter2) -> Void) {
    return { parameter1, parameter2 in
        DispatchQueue.main.async {
            closure(parameter1, parameter2)
        }
    }
}

/**
 This function can be used to create a closure being performed on the main thread from another one.
 
 Usage Example:
 ```
 let safeCompletion = safeClosure(from: completion)
 ```
 
 - parameter closure: the closure that is supposed to be performed on the main thread
 */
public func safeClosure<Parameter1, Parameter2, Parameter3>(from closure: @escaping (Parameter1, Parameter2, Parameter3) -> Void) -> ((Parameter1, Parameter2, Parameter3) -> Void) {
    return { parameter1, parameter2, parameter3 in
        DispatchQueue.main.async {
            closure(parameter1, parameter2, parameter3)
        }
    }
}
