import Foundation

public struct Day: Codable, CustomDebugStringConvertible, CustomStringConvertible, Hashable, Sendable {
    
    public let dayIdentifier: String
    
    public var description: String { dayIdentifier.description }
    public var debugDescription: String { dayIdentifier.debugDescription }
    
    public func date() throws -> Date {
        guard let date = Self.dateFormatter().date(from: dayIdentifier) else { throw ConversionError() }
        return date
    }
    
    // MARK: Init
    
    public init(dayIdentifier: String) throws {
        guard Self.dateFormatter().date(from: dayIdentifier) != nil else { throw ConversionError() }
        self.dayIdentifier = dayIdentifier
    }
    
    public init(from date: Date) {
        self.dayIdentifier = Self.dateFormatter().string(from: date)
    }
    
    public init(from dateComponents: DateComponents) throws {
        guard let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day else { throw ConversionError() }
        let dayComponents = DateComponents(year: year, month: month, day: day)
        guard dayComponents.isValidDate, let date = Calendar(identifier: .iso8601).date(from: dayComponents) else { throw ConversionError() }
        self.init(from: date)
    }
    
    // MARK: Codable
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dayIdentifier)
    }
    
    public init(from decoder: any Decoder) throws {
        self.dayIdentifier = try decoder.singleValueContainer().decode(String.self)
    }
    
    // MARK: ConversionError
    
    public struct ConversionError: LocalizedError {
        
        public var errorDescription: String? { .init(localized: "day_conversion_error_description", bundle: .module) }
        
        fileprivate init() {}
    }
    
    // MARK: Static
    
    public static let dayIdentifierFormat: String = "yyyy-MM-dd"
    private static func dateFormatter(calendar: Calendar = Calendar(identifier: .iso8601)) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = Self.dayIdentifierFormat
        return formatter
    }
}
