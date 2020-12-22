//
//  Contribution.swift
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

class Contribution {
    
    static let maintainers: [Contributor] = readContributors(for: \.maintainers)
    static let contributors: [Contributor] = readContributors(for: \.contributors)
    static let translators: [Contributor] = readContributors(for: \.translators)
    
    private static func readContributors(for keypath: KeyPath<ContributionsObject, [Contributor]>) -> [Contributor] {
        
        do {
            if let url = Bundle.main.url(forResource: "contribution", withExtension: "json") {
               
                let data = try Data(contentsOf: url)
                let contributions = try JSONDecoder().decode(ContributionsObject.self, from: data)
                
                return contributions[keyPath: keypath]
                
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return []
    }
    
    private struct ContributionsObject: Codable {
        let maintainers: [Contributor]
        let contributors: [Contributor]
        let translators: [Contributor]
    }
    
    public struct Contributor: Codable {
        let name: String
        let url: String
    }
}
