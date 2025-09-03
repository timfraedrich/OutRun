//
//  Publisher.swift
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
import Combine

public extension Publisher {
    
    /// Creates a `Publisher` which will always be observed and susbcribed to on a background queue.
    func asBackgroundPublisher() -> AnyPublisher<Output, Failure> {
        let backgroundQueue = DispatchQueue(label: "background", qos: .background)
        return self.receive(on: backgroundQueue).subscribe(on: backgroundQueue).eraseToAnyPublisher()
    }
    
    /**
     Publishes the current element together with its predecessor.
     
         let range = (1...3)
         cancellable = range.publisher
            .withPrevious()
            .sink {
                print ("(\($0.previous), \($0.current))", terminator: " ")
            }
         // Prints: "(nil, 1) (Optional(1), 2) (Optional(2), 3) ".
     
     - note: The first element will be accompanied by `nil` as the previous value.
     - returns: A publisher of a touple of the optional previous and the current element from the upstream publisher.
     */
    func withPrevious() -> AnyPublisher<(previous: Output?, current: Output), Failure> {
        scan(Optional<(Output?, Output)>.none) { ($0?.1, $1) }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
