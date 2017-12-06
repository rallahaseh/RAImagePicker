//
//  RACameraCollectionViewCell.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import UIKit
import Foundation
import AVFoundation

protocol RACameraCollectionViewCellDelegate : class {
    func takePicture()
    func takeLivePhoto()
    func startVideoRecording()
    func stopVideoRecording()
    func flipCamera(_ completion: (() -> Void)?)
}

/*
    Base class for cutom camera cells. [Custom Cell --inherit--> RACameraCollectionViewCell]
 */
open class RACameraCollectionViewCell: UICollectionViewCell {
    
    // Video Preview Layer
    var previewView: AVPreviewView = {
        let view = AVPreviewView(frame: .zero)
        view.backgroundColor = UIColor.black
        return view
    }()
    // Adding an image above the blur view so the image can hide the black background
    var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    var blurView: UIVisualEffectView?
    var isVisualEffectViewUsedForBlurring = false
    weak var delegate: RACameraCollectionViewCellDelegate?
    
    // MARK: - Initialization
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundView = previewView
        previewView.addSubview(imageView)
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundView = previewView
        previewView.addSubview(imageView)
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = previewView.bounds
        blurView?.frame = previewView.bounds
    }

    // MARK: - Public Methods
    
    // Camera authorization status delegate. [Update UI based on the value of `authorizationStatus` property]
    open func updateCameraAuthorizationStatus() {}
    
    // Cell can have multiple visual states based on autorization status.
    public internal(set) var authorizationStatus: AVAuthorizationStatus? {
        didSet {
            updateCameraAuthorizationStatus()
        }
    }
    
    // Live Photos delegate.
    // - isProcessing:    check if there is at least one live photo being processed/captured.
    // - shouldAnimate:   check if the UI change should be animated or not.
    open func updateLivePhotoStatus(isProcessing: Bool, shouldAnimate: Bool) {}
    
    // Video recording delegate. [Override this method to update UI based on recording status]
    // - isRecording:   check if the video is recording or not.
    // - shouldAnimate: check if the UI change should be animated or not.
    open func updateRecordingVideoStatus(isRecording: Bool, shouldAnimate: Bool) {}
    // Video became ready
    open func videoRecodingDidBecomeReady() {}
    
    /*
        Camera Functionalities
    */
    // Camera Flipping
    @objc public func flipCamera(_ completion: (() -> Void)? = nil) {
        delegate?.flipCamera(completion)
    }
    // Capture Photos
    @objc public func takePicture() {
        delegate?.takePicture()
    }
    // Capture Live Photos
    @objc public func takeLivePhoto() {
        delegate?.takeLivePhoto()
    }
    // Record Video
    @objc public func startVideoRecording() {
        delegate?.startVideoRecording()
    }
    @objc public func stopVideoRecording() {
        delegate?.stopVideoRecording()
    }
    
    /*
        Blur Effect
     */
    func blurEffect(blurImage: UIImage?, animated: Bool, completion: ((Bool) -> Void)?) {
        var view: UIView
        if isVisualEffectViewUsedForBlurring == false {
            guard imageView.image == nil else {
                return
            }
            imageView.image = blurImage
            view = imageView
        }
        else {
            if blurView == nil {
                blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                previewView.addSubview(blurView!)
            }
            view = blurView!
            view.frame = previewView.bounds
        }
        view.alpha = 0
        if animated == false {
            view.alpha = 1
            completion?(true)
        }
        else {
            UIView.animate(withDuration: 0.1, delay: 0, options: .allowAnimatedContent, animations: {
                view.alpha = 1
            }, completion: completion)
        }
    }
    func unblurEffect(unblurImage: UIImage?, animated: Bool, completion: ((Bool) -> Void)?) {
        var animationBlock: () -> ()
        var animationCompletionBlock: (Bool) -> ()
        if isVisualEffectViewUsedForBlurring == false {
            guard imageView.image != nil else {
                return
            }
            if let image = unblurImage {
                imageView.image = image
            }
            animationBlock = {
                self.imageView.alpha = 0
            }
            animationCompletionBlock = { finished in
                self.imageView.image = nil
                completion?(finished)
            }
        }
        else {
            animationBlock = {
                self.blurView?.alpha = 0
            }
            animationCompletionBlock = { finished in
                completion?(finished)
            }
        }
        if animated == false {
            animationBlock()
            animationCompletionBlock(true)
        }
        else {
            UIView.animate(withDuration: 0.1, delay: 0, options: .allowAnimatedContent, animations: animationBlock, completion: animationCompletionBlock)
        }
    }
    
    // Tap press determining wether is should take a photo or not.
    func touchIsCaptureEffective(point: CGPoint) -> Bool {
        // Finding topmost view that detected the touch at a point and check if its not any anything other than contentView.
        if bounds.contains(point), let testedView = hitTest(point, with: nil), testedView === contentView {
            return true
        }
        return false
    }
}
