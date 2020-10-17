//
//  Config.swift
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

import UIKit
import Foundation

enum Config {
    
    static var releaseStatus: ReleaseStatus {
        if Config.isDebug || Config.isRunOnSimulator {
            return ReleaseStatus.debug
        } else if /*Config.hasMobileProvision &&*/ Config.hasSanboxReceipt {
            return ReleaseStatus.beta
        } else {
            return ReleaseStatus.release
        }
    }
    
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "error"
    }
    
    static let versions: [String] = ["1.0", "1.1", "1.1.1", "1.1.2", "1.2", "1.2.1", "1.2.2"]
    
    static var changeLogs: [String:String] = [
        "1.2.2" : LS["Changelog_1.2.2", .changelog]
    ]
    
    static var isDarkModeEnabled: Bool {
        get {
            if #available(iOS 13.0, *) {
                return UITraitCollection.current.userInterfaceStyle == .dark
            } else {
                return false
            }
        }
    }
    
    enum ReleaseStatus: String {
        case debug, beta, release
    }
    
    /// A boolean indicating whether the app is run in debug mode
    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    /// A boolean indicating whether the app is run on a simulator
    static var isRunOnSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
    
    /// A boolean indicating wheather the app bundle contains a certain file generated when building and packaging an App for App Store Connect
    static var hasMobileProvision: Bool {
        return (Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil)
    }
    
    /// A boolean indicating whether or not the receipt provided through by the App Store was generated for a sandbox / non-release environment; in other words: it indicates if the app was downloaded through another way than the App Store
    static var hasSanboxReceipt: Bool {
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }
    
}
