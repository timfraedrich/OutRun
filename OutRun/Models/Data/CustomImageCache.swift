//
//  CustomImageCache.swift
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
import Cache

class CustomImageCache {
    
    /// standard static instance of `CustomCache`
    static let mapImageCache = CustomImageCache()
    
    /// the total disk size allocated for the disk storage of the cache
    public var diskSize: Int? {
        return diskStorage?.totalSize
    }
    
    /// the disk storage as basis of the caching system
    private let diskStorage: DiskStorage<String, UIImage>?
    /// the memory storage for faster access
    private let memoryStorage: MemoryStorage<String, UIImage>?
    /// the hybrid storage comining the disk and memory storage
    private let hybridStorage: HybridStorage<String, UIImage>?
    
    /// Initiates the `CustomCache` object and tries to initiate the contained storage(s)
    init() {
        
        let diskConfig = DiskConfig(
            name: "MapImageCache",
            expiry: .never,
            maxSize: 5000000
        )
        
        let memoryConfig = MemoryConfig(
            expiry: .date(Date().addingTimeInterval(15 * 60)),
            countLimit: 50,
            totalCostLimit: 0
        )
        
        do {
            
            let disk = try DiskStorage<String, UIImage>(config: diskConfig, transformer: TransformerFactory.forImage())
            let memory = MemoryStorage<String, UIImage>(config: memoryConfig)
            let hybrid = HybridStorage(memoryStorage: memory, diskStorage: disk)
            
            self.diskStorage = disk
            self.memoryStorage = memory
            self.hybridStorage = hybrid
            
        } catch {
            
            print("[CustomImageCache] failed to initiate map image cache")
            self.diskStorage = nil
            self.memoryStorage = nil
            self.hybridStorage = nil
            
        }
    }
    
    /**
     Caches the provided image for the provided key
     - parameter mapImage: the image that needs to be cached
     - parameter key: the string the image will be cached under
     */
    func set(mapImage: UIImage, for key: String) {
        
        guard let storage = self.hybridStorage else {
            return
        }
        
        do {
            
            try storage.setObject(mapImage, forKey: key)
            
        } catch {
            
            print("[CustomImageCache] failed to set image:", error.localizedDescription)
            
        }
        
    }
    
    /**
     Tries to query an image for the provided key
     - parameter key: the string the image is supposedly cached under
     - returns: an optional `UIImage` being `nil` if there was no image cached under the provided key
     */
    func getMapImage(for key: String) -> UIImage? {
        
        guard let storage = self.hybridStorage else {
            return nil
        }
        
        do {
            
            if try storage.existsObject(forKey: key) {
                return try storage.object(forKey: key)
            }
            
            return nil
            
        } catch {
            
            print("[CustomImageCache] failed to get image:", error.localizedDescription)
            return nil
            
        }
        
    }
    
    func clear(completion: (Bool) -> Void) {
        
        do {
            
            try self.hybridStorage?.removeAll()
            completion(true)
            
        } catch {
            
            print("[CustomImageCache] failed to clear cache", error.localizedDescription)
            completion(false)
            
        }
        
    }
    
}
