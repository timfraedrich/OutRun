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
    
    static func readJSON<C: Codable>(at url: URL) throws -> C {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(C.self, from: data)
    }
    
    static func readJSON<C: Codable>(with filename: String) throws -> C {
        let url = try jsonFileURL(forResource: filename)
        return try readJSON(at: url)
    }
}
