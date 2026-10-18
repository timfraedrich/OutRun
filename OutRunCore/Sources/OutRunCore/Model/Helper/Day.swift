//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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

import Foundation

public struct Day: RawRepresentable, Codable, CustomDebugStringConvertible, CustomStringConvertible, Hashable, Sendable {
    
    public let dayIdentifier: String
    
    public var rawValue: String { dayIdentifier }
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
    
    public init?(rawValue: String) {
        try? self.init(dayIdentifier: rawValue)
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
