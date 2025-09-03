//
//  WorkoutMapImageQueue.swift
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

class WorkoutMapImageQueue {
    
    public var pendingRequests: [WorkoutMapImageRequest] {
        return highPriorityRequests + ordinaryRequests
    }
    
    private var highPriorityRequests = [WorkoutMapImageRequest]()
    private var ordinaryRequests = [WorkoutMapImageRequest]()
    
    func add(_ request: WorkoutMapImageRequest) {
        
        // removing already existing identical requests
        if let index = (request.highPriority ? highPriorityRequests : ordinaryRequests).firstIndex(of: request) {
            switch request.highPriority {
            case true:
                highPriorityRequests.remove(at: index)
            default:
                ordinaryRequests.remove(at: index)
            }
            return
        }
        
        switch request.highPriority {
        case true:
            highPriorityRequests.append(request)
        default:
            ordinaryRequests.append(request)
        }
        
    }
    
    func remove(_ request: WorkoutMapImageRequest) {
        
        switch request.highPriority {
        case true:
            highPriorityRequests.removeAll { (pendingRequest) -> Bool in
                pendingRequest == request
            }
        default:
            ordinaryRequests.removeAll { (pendingRequest) -> Bool in
                pendingRequest == request
            }
        }
        
    }
    
}
