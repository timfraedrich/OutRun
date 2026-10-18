//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

@testable import OutRun
@testable import OutRunCore
import Foundation

class TestUtil {
    
    @available(*, unavailable)
    private init() {}
    
    static func fileURL(forResource filename: String, withExtension fileExtension: String) throws -> URL {
        let testBundle = Bundle(for: self)
        guard let url = testBundle.url(forResource: filename, withExtension: fileExtension) else { throw "Resource does not exist." }
        return url
    }
    
    static func jsonFileURL(forResource filename: String) throws -> URL {
        try fileURL(forResource: filename, withExtension: "json")
    }

    static func orbupFileURL(forResource filename: String) throws -> URL {
        try fileURL(forResource: filename, withExtension: "orbup")
    }

    static func readJSON<C: Codable>(at url: URL) throws -> C {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(C.self, from: data)
    }
    
    static func readJSON<C: Codable>(with filename: String) throws -> C {
        let url = try jsonFileURL(forResource: filename)
        return try readJSON(at: url)
    }

    static func readORBUP<C: Codable>(with filename: String) throws -> C {
        let url = try orbupFileURL(forResource: filename)
        return try readJSON(at: url)
    }
}
