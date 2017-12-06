//
//  RAAVPreviewView.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import UIKit
import Foundation
import AVFoundation

enum VideoDisplayMode {

    // Preserve aspect ration, fit within layer bounds
    case aspectFit
    // Preserve aspect ratio, fill view bounds
    case aspectFill
    // Stretch to fill layer bounds
    case resize
}

// View whose layer is AVCaptureVideoPreviewLayer to preview the output of a captured session
final class AVPreviewView: UIView {
    
    // MARK: - Public Methods
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return previewLayer.session
        }
        set {
            if previewLayer.session === newValue {
                return
            }
            previewLayer.session = newValue
        }
    }
    
    var displayMode: VideoDisplayMode = .aspectFill {
        didSet {
            applyVideoDisplayMode()
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        applyVideoDisplayMode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        applyVideoDisplayMode()
    }
    
    // MARK: - Private Methods
    
    private func applyVideoDisplayMode() {
        switch displayMode {
        case .aspectFill: previewLayer.videoGravity     = AVLayerVideoGravity.resizeAspectFill
        case .aspectFit: previewLayer.videoGravity      = AVLayerVideoGravity.resizeAspect
        case .resize: previewLayer.videoGravity         = AVLayerVideoGravity.resize
        }
    }
}
