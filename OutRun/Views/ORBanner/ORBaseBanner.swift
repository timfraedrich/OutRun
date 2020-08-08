//
//  ORBaseBanner.swift
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

public class ORBaseBanner: UIView {
    
    /// The closure being run on display or resume of the banner
    public var onDisplay: ((ORBaseBanner) -> Void)?
    
    /// The closure being run on dismiss of the banner
    public var onDismiss: ((ORBaseBanner) -> Void)?
    
    /// The corner radius used for rounding off the subviews of the banner
    private let cornerRadius: CGFloat = 15
    
    /// The spacing around the banner; meaning the distance it will have to the edge of the screen
    private let spacing: CGFloat = 15
    
    /// The height and width of the dismiss button
    private let dismissButtonSize: CGFloat = 36
    
    /// The effect view used to display a blur effect as the background of the banner
    private lazy var effectView: UIVisualEffectView = {
        
        let effectView = UIVisualEffectView()
        
        effectView.effect = UIBlurEffect(style: .regular)
        effectView.clipsToBounds = true
        effectView.layer.cornerRadius = self.cornerRadius
        
        return effectView
        
    }()
    
    /// The button used to manually dismiss the banner
    private let dismissButton: UIButton = {
        
        let button = UIButton()
        
        button.setImage(.close, for: .normal)
        button.tintColor = .secondaryColor
        
        return button
        
    }()
    
    /// The queue the banner will be placed on
    private var queue: ORBannerQueue = .default
    
    /// The duration the banner will be displayed; set to `nil` if the banner should not dismiss after a certain time
    public var duration: TimeInterval? = 10
    
    /// If `true` the banner can be dismissed by the user, otherwise it can only be dismissed after the duration delay or manually
    public let isDismissable: Bool
    
    /// If `true` the banner is currently being displayed
    public private(set) var isBeingDisplayed: Bool = false
    
    /// If `true` the banner was suspended by the queue to immediately display another banner; the banner is invisible
    public private(set) var isSuspended: Bool = false
    
    /// The content view of the banner; to customise you should use the customise block when initialising
    public private(set) var contentView: UIView = UIView()
    
    /**
     Initialises the `ORBaseBanner` with a modified content view
     - parameter customise: a block being called with reference to this `ORBaseBanner` and the content view of it; this should be used to customise the content view
     - note: Views added to the content view inside the customise block should have propper constraints set up or the content view should be assigned a frame
     */
    public init(customise: ((ORBaseBanner, UIView) -> Void)? = nil, isDismissable: Bool = true) {
        
        self.isDismissable = isDismissable
        
        super.init(frame: .zero)
        
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 10
        
        self.layer.cornerRadius = self.cornerRadius
        
        self.backgroundColor = UIColor.backgroundColor.withAlphaComponent(0.5)
        
        self.addSubview(effectView)
        self.addSubview(contentView)
        
        effectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: self.spacing, left: self.spacing, bottom: self.spacing, right: 0))
        }
        
        if self.isDismissable {
            
            self.addSubview(dismissButton)
            
            dismissButton.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-self.spacing)
                make.width.height.equalTo(self.dismissButtonSize)
                make.left.equalTo(contentView.snp.right).offset(self.spacing)
            }
            
            dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
            
        } else {
            
            contentView.snp.makeConstraints { (make) in
                make.right.equalToSuperview().offset(-self.spacing)
            }
            
        }
        
        customise?(self, contentView)
        
        // somehow setting the size leads to the auto layout constraints not conflicting
        self.frame.size = self.calculatedSize
        
    }
    
    required init?(coder: NSCoder) {
        self.isDismissable = true
        super.init(coder: coder)
    }
    
    /**
     Shows the banner on a queue as specified
     - parameter queue: the queue the banner will be placed on
     - parameter queuePosition: the `ORBannerQueue.Position` the banner will be placed at in the queue
     */
    public func show(queue: ORBannerQueue = .default, queuePosition: ORBannerQueue.Position = .back) {
        
        if !self.isBeingDisplayed {
            
            self.queue = queue
            self.queue.add(self, position: queuePosition)
            
        }
        
    }
    
    /**
     Displays the banner 
     */
    internal func display() {
        
        guard !self.isBeingDisplayed else {
            return
        }
        
        if let window = UIApplication.shared.keyWindow {
            
            window.windowLevel = .statusBar + 1
            
            window.addSubview(self)
            
            self.isBeingDisplayed = true
            self.scheduleAutoDismiss()
            
            self.onDisplay?(self)
            
            self.frame = self.calculatedStartFrame
            
            self.animate(animations: {
                
                self.frame = self.calculatedEndFrame
                
            })
            
        }
        
    }
    
    /**
     Suspends the display and auto dismissal of the banner to make room for another on the condition that it is being displayed and it is not suspended already
     */
    internal func suspend() {
        
        guard self.isBeingDisplayed, !self.isSuspended else {
            return
        }
        
        self.isSuspended = true
        self.cancleAutoDismiss()
        
        self.animate(animations: {
            
            self.alpha = 0
            
        }, completion: { finished in
            
            self.isHidden = true
            
        })
        
    }
    
    /**
     Resumes the display and restarts the auto dismissal of the banner after the banner responsible for the suspension was dismissed on the condition that it is being displayed and currently suspended
     */
    internal func resume() {
        
        guard self.isBeingDisplayed, self.isSuspended else {
            return
        }
        
        self.isSuspended = false
        self.scheduleAutoDismiss()
        
        self.onDisplay?(self)
        
        self.isHidden = false
        
        self.animate(animations: {
            
            self.alpha = 1
            
        })
        
    }
    
    /**
     Dismisses the banner on the condition that it is being displayed
     */
    @objc public func dismiss() {
        
        guard self.isBeingDisplayed else {
            return
        }
        
        self.isBeingDisplayed = false
        self.isSuspended = false
        
        self.onDismiss?(self)
        
        self.animate(animations: {
            
            self.frame = self.calculatedStartFrame
            
        }, completion: { finished in
            
            self.removeFromSuperview()
            self.queue.displayNext()
            
        })
        
        
    }
    
    /// The calculated `CGSize` of the banner based on auto layout constraints
    private var calculatedSize: CGSize {
        let referenceSize = CGSize(
            width: UIScreen.main.bounds.width - ( 2 * self.spacing ),
            height: (UIApplication.shared.keyWindow?.safeAreaLayoutGuide.layoutFrame.height ?? UIScreen.main.bounds.height) - ( 2 * self.spacing )
        )
        let size = self.systemLayoutSizeFitting(
            referenceSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return size
    }
    
    /// The calculated `CGPoint` for the start frame of the banner for it to be out of screen
    private var calculatedStartOrigin: CGPoint {
        return CGPoint(x: self.spacing, y: -self.calculatedSize.height)
    }
    
    /// The calculated `CGPoint` for the end frame of the banner for it to be on the screen
    private var calculatedEndOrigin: CGPoint {
        return CGPoint(x: self.spacing, y: self.spacing + (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0))
    }
    
    /// The start frame of the banner, being the first and last postion of the banner in the display process
    private var calculatedStartFrame: CGRect {
        return CGRect(origin: self.calculatedStartOrigin, size: self.calculatedSize)
    }
    
    /// The end frame of the banner, being the final position when displaying
    private var calculatedEndFrame: CGRect {
        return CGRect(origin: self.calculatedEndOrigin, size: self.calculatedSize)
    }
    
    /**
     Animates the animation block with `UIView.animate` and constant properties
     - parameter animations: the animations being performed
     - parameter completion: the completion block being handed to `UIView.animate`
     */
    private func animate(animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
        
    }
    
    /**
     Automatically dismisses the banner after the specified duration
     */
    private func scheduleAutoDismiss() {
        
        if let duration = self.duration {
            
            self.perform(#selector(dismiss), with: nil, afterDelay: duration)
            
        }
        
    }
    
    /**
     Cancles perviously scheduled auto dismisses
     */
    private func cancleAutoDismiss() {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismiss), object: nil)
        
    }
    
}
