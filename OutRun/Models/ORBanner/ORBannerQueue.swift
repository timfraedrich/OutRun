//
//  ORBannerQueue.swift
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

public class ORBannerQueue {
    
    /// The default instance of `ORBannerQueue`
    public static let `default` = ORBannerQueue()
    
    /// The `ORBaseBanners` currently in the queue
    public private(set) var banners: [ORBaseBanner] = []
    
    /// The number of banners in the queue
    public var count: Int {
        return self.banners.count
    }
    
    /**
     Adds an `ORBaseBanner` to the queue
     - parameter banner: The banner being added to the queue
     - parameter position: The `Position` where a banner will be added to the queue
     */
    public func add(_ banner: ORBaseBanner, position: ORBannerQueue.Position = .back) {
        
        switch position {
            
        case .back:
            
            self.banners.append(banner)
            
            if self.banners.firstIndex(of: banner) == 0 {
                
                banner.display()
                
            }
            
        case .front:
            
            if let firstBanner = self.banners.first {
                
                firstBanner.suspend()
                
            }
            
            self.banners.insert(banner, at: 0)
            
            banner.display()
            
        }
        
    }
    
    /**
     Removes an `ORBaseBanner` from the queu
     - parameter banner: The banner being removed from the queue
     */
    public func remove(_ banner: ORBaseBanner) {
        
        if let bannerIndex = self.banners.firstIndex(of: banner) {
            
            self.banners.remove(at: bannerIndex)
            
        }
        
    }
    
    /**
     Displayes (or resumes) the next banner after removing the current banner from the queue
     */
    public func displayNext() {
        
        if !self.banners.isEmpty {
            
            let banner = self.banners.removeFirst()
            
            if banner.isBeingDisplayed {
                
                banner.dismiss()
                
            }
            
        }
        
        if let nextBanner = self.banners.first {
            
            if nextBanner.isSuspended {
                
                nextBanner.resume()
                
            } else {
                
                nextBanner.display()
                
            }
            
        }
        
    }
    
    /**
     Clears the queue by removing all banners
     */
    public func clear() {
        
        self.banners.removeAll()
        
    }
    
    /**
     An Enumeration describing where an element of `ORBannerQueue` should be added; `front` meaning it will be displayed immediately and `back` meaning it will be added as the last element to be displayed
     */
    public enum Position {
        
        /// The banner will be placed at the front of the queue and displayed immediately
        case front
        /// The banner will be placed at the back of the queue and displayed after all other banners in front of it were
        case back
        
    }
    
}
