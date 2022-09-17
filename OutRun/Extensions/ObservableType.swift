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
    
    /**
     Creates an `Observable` sequence returning the previous value with a new one.
     
     - note: if the first element gets emitted the previous value will be `nil`
     
     - returns: An observable sequence returning previous elements together with current ones.
     */
    func withPrevious() -> Observable<(Element?, Element)> {
        return scan([], accumulator: { Array($0 + [$1]).suffix(2) })
            .map{ ($0.count > 1 ? $0.first : nil, $0.last!) }
    }
        
    /**
     Pauses the elements of the source observable sequence based on the latest element from the second observable sequence.
     While paused, elements from the source are buffered, limited to a maximum number of element.
     When resumed, all buffered elements are flushed as single events in a contiguous stream.
     - seealso: [pausable operator on reactivex.io](http://reactivex.io/documentation/operators/backpressure.html)
     - parameter pauser: The observable sequence used to pause the source observable sequence.
     - parameter limit: The maximum number of element buffered. Pass `nil` to buffer all elements without limit. Default 1.
     - parameter flushOnCompleted: If `true` buffered elements will be flushed when the source completes. Default `true`.
     - parameter flushOnError: If `true` buffered elements will be flushed when the source errors. Default `true`.
     - returns: The observable sequence which is paused and resumed based upon the pauser observable sequence.
     */
    public func pausableBuffered<Pauser: ObservableType> (_ pauser: Pauser, limit: Int? = 1, flushOnCompleted: Bool = true, flushOnError: Bool = true) -> Observable<Element> where Pauser.Element == Bool {

        return Observable<Element>.create { observer in
            var buffer: [Element] = []
            if let limit = limit {
                buffer.reserveCapacity(limit)
            }

            var paused = false
            var flushIndex = 0
            let lock = NSRecursiveLock()

            let flush = {
                while flushIndex < buffer.count {
                    flushIndex += 1
                    observer.onNext(buffer[flushIndex - 1])
                }
                if buffer.count > 0 {
                    flushIndex = 0
                    buffer.removeAll(keepingCapacity: limit != nil)
                }
            }

            let boundaryDisposable = pauser.distinctUntilChanged(==).subscribe { event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next(let pause):
                    if !pause && buffer.count > 0 {
                        flush()
                    }
                    paused = pause

                case .completed:
                    observer.onCompleted()
                case .error(let error):
                    observer.onError(error)
                }
            }

            let disposable = self.subscribe { event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next(let element):
                    if paused {
                        buffer.append(element)
                        if let limit = limit, buffer.count > limit {
                            buffer.remove(at: 0)
                        }
                    } else {
                        observer.onNext(element)
                    }

                case .completed:
                    if flushOnCompleted { flush() }
                    observer.onCompleted()

                case .error(let error):
                    if flushOnError { flush() }
                    observer.onError(error)
                }
            }

            return Disposables.create([disposable, boundaryDisposable])
        }
    }
}
