//
//  ObservableType.swift
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

import RxSwift

extension ObservableType {
    
    /**
     Creates an `Observable` which will always be observed on a background queue.
     - returns: an `Observable` being observed on a background queue
     */
    func asBackgroundObservable() -> Observable<Element> {
        let scheduler = SerialDispatchQueueScheduler(qos: .background)
        return self.observe(on: scheduler)
    }
    
    /**
     Merges two observable sequences into one observable sequence by combining each element from self with the latest element from the second source, if any.

     - note: Elements emitted by self before the second source has emitted any values will be omitted.
 
     - parameter second: Second observable source.
     - returns: An observable sequence containing the result of combining each element of the self with the latest element  from the second source, if any.
     */
    func combineWithLatestFrom<Source: ObservableConvertibleType>(_ second: Source) -> Observable<(Element, Source.Element)> {
        return self.withLatestFrom(second, resultSelector: { ($0, $1) })
    }
}
