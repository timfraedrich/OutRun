//
//  LS.swift
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

/// A struct containg only static subscripts and needed enumerations to enable easier localisation.
struct LS {
    
    /**
     Returns a localised string for the provided key and specified source.
     - parameter key: the key pointing to the localised string
     - parameter sourceType: the `LSSourceType` defining which file to get the string from
     - returns: the localised `String`
     */
    public static subscript(_ key: String, sourceType: LSSourceType = .appStrings) -> String {
        
        let errorValue = "NIL"
        var localizedString = Bundle.main.localizedString(forKey: key, value: errorValue, table: sourceType.tableName)
        
        // falling back on base language if string for key is not availabe
        if localizedString == "NIL" {
            localizedString = sourceType.fallbackBundle.localizedString(forKey: key, value: errorValue, table: sourceType.tableName)
        }
        
        // checking if trademark applies and app name needs to be changed
        if Locale.current.regionCode?.lowercased() == "gb" {
            return localizedString.replacingOccurrences(of: "OutRun", with: "Out-Run")
        }
        
        return localizedString
    }
    
    /// Enumeration of possible localised string source types referring to different string tables in the project.
    public enum LSSourceType {
        
        /// Referring to strings used inside the app.
        case appStrings
        /// Referring to strings contained by the info.plist and needed for things like permission descriptions.
        case infoPlist
        /// Referring to strings used in changelogs
        case changelog
        
        /// A `String` pointing to the file in which the localised strings of the given `LSSourceType` are located.
        fileprivate var tableName: String {
            switch self {
            case .appStrings:
                return "Localizable"
            case .infoPlist:
                return "InfoPlist"
            case .changelog:
                return "Changelog"
            }
        }
        
        /// The `Bundle` that is to be used in case a string is not localised for the current language
        fileprivate var fallbackBundle: Bundle {
            switch self {
            case .appStrings:
                return Bundle(path: Bundle.main.path(forResource: "Base", ofType: "lproj")!)!
            case .infoPlist, .changelog:
                return Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)!
            }
        }
        
    }
    
}
