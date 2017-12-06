//
//  RALivePhotoCameraCell.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import UIKit
import Foundation

class RALivePhotoCameraCell : RACameraCollectionViewCell {
    
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var enableLivePhotosButton: RAStationaryButton!
    @IBOutlet weak var liveIndicator: RACarvedLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        liveIndicator.alpha = 0
        liveIndicator.tintColor = UIColor(red: 245/255, green: 203/255, blue: 47/255, alpha: 1)
        
        enableLivePhotosButton.unselectedTintColor = UIColor.white
        enableLivePhotosButton.selectedTintColor = UIColor(red: 245/255, green: 203/255, blue: 47/255, alpha: 1)
    }
    
    @IBAction func snapButtonTapped(_ sender: UIButton) {
        if enableLivePhotosButton.isSelected {
            takeLivePhoto()
        }
        else {
            takePicture()
        }
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }
    
    func updateWithCameraMode(_ mode: RACaptureSettings.CameraMode) {
        switch mode {
        case .photo:
            liveIndicator.isHidden = true
            enableLivePhotosButton.isHidden = true
        case .photoAndLivePhoto:
            liveIndicator.isHidden = false
            enableLivePhotosButton.isHidden = false
        default:
            fatalError("Image Picker - unsupported camera mode for \(type(of: self))")
        }
    }
    
    override func updateLivePhotoStatus(isProcessing: Bool, shouldAnimate: Bool) {
        
        let updates: () -> Void = {
            self.liveIndicator.alpha = isProcessing ? 1 : 0
        }
        
        shouldAnimate ? UIView.animate(withDuration: 0.25, animations: updates) : updates()
    }
    
}

