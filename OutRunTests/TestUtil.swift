import Foundation

class TestUtil {
    
    @available(*, unavailable)
    private init() {}
    
    static func readJSON<C: Codable>(filename: String) throws -> C {
        let testBundle = Bundle(for: self)
        guard let url = testBundle.url(forResource: filename, withExtension: "json") else {
            throw "Invalid URL for json file."
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(C.self, from: data)
    }
}
