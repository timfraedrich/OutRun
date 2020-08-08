//
//  FileManager.swift
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

extension FileManager {
    
    /**
     Calculates the size of the directory at the provided `URL`
     - parameter url: the directory url
     - returns: the size of the provided directory in bytes
     */
    public func sizeOfDirectory(at url: URL) -> Int? {
        
        guard let enumerator = self.enumerator(at: url, includingPropertiesForKeys: [], options: [], errorHandler: { (_, error) -> Bool in
            print(error)
            return false
        }) else {
            return nil
        }
        
        var size = 0
        
        for case let url as URL in enumerator {
            size += url.fileSize ?? 0
        }
        
        return size
        
    }
    
}
