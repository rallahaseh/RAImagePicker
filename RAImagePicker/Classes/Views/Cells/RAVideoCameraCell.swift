//
//  RAVideoCameraCell.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import UIKit
import Foundation


// TODO: add a recording indicator (red dot with timer)
class RAVideoCameraCell: RACameraCollectionViewCell {
    
    @IBOutlet weak var recordLabel: RARecordDurationLabel!
    @IBOutlet weak var recordButton: RARecordButton!
    @IBOutlet weak var flipButton: UIButton!
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if sender.isSelected {
            stopVideoRecording()
        }
        else {
            startVideoRecording()
        }
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        recordButton.isEnabled = false
        recordButton.alpha = 0.5
    }
    
    override func updateRecordingVideoStatus(isRecording: Bool, shouldAnimate: Bool) {
        
        // Update button state
        recordButton.isSelected = isRecording
        
        // Update duration label
        isRecording ? recordLabel.start() : recordLabel.stop()
        
        // Update other buttons
        let updates: () -> Void = {
            self.flipButton.alpha = isRecording ? 0 : 1
        }
        
        shouldAnimate ? UIView.animate(withDuration: 0.25, animations: updates) : updates()
    }
    
    override func videoRecodingDidBecomeReady() {
        recordButton.isEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.recordButton.alpha = 1.0
        }
    }
    
}
