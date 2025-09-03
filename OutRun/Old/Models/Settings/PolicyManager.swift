//
//  PolicyManager.swift
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

class PolicyManager {
    
    static let baseURL = "https://outrun.tadris.de/policies/"
    
    static func query(for type: PolicyType, completion: @escaping (Bool, Error?, String?) -> Void) {
        
        let completion: (Bool, Error?, String?) -> Void = { (success, error, result) in
            DispatchQueue.main.async {
                completion(success, error, result)
            }
        }
        
        if let url = URL(string: baseURL + type.urlExtension) {
            
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            let task = session.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let err = error {
                    
                    print(err)
                    print(response as Any)
                    completion(false, err, nil)
                    
                } else {
                    if let unwrappedData = data, let content = String(data: unwrappedData, encoding: .utf8) {
                        
                        completion(true, nil, content)
                        
                    } else {
                        completion(false, nil, nil)
                    }
                }
                
            }
            task.resume()
            session.finishTasksAndInvalidate()
        }
        
    }
    
    enum PolicyType {
        case termsOfService, privacyPolicy
        
        var title: String {
            switch self {
            case .termsOfService:
                return LS["Settings.TermsOfService"]
            case .privacyPolicy:
                return LS["Settings.PrivacyPolicy"]
            }
        }
        
        var urlExtension: String {
            switch self {
            case .termsOfService:
                return "terms-of-service.txt"
            case .privacyPolicy:
                return "privacy-policy.txt"
            }
        }
    }
    
}
