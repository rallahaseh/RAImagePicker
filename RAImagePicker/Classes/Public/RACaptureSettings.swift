//
//  RACaptureSettings.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import UIKit

/*
    Capture Structure Configuration
 */
public struct RACaptureSettings {
    
    public enum CameraMode {
        
        // Support Photos Only [Default]
        case photo
        
        // Support Videos Only
        case video
        
        // Support Photos & Live Photos
        case photoAndLivePhoto
        
        // Support Videos & Photos
        case photoAndVideo
    }
    
    
    // Preset of media types needed to support [Can not be changed at the runtime]
    public var cameraMode: CameraMode
    
    // Check if saving photos flag is turned on [(Photos Only), Videos and Live Photos is always true]
    // save photo in library => true, do not save => false
    public var savesCapturedPhotosToPhotoLibrary: Bool
    
    let savesCapturedLivePhotosToPhotoLibrary: Bool     = true
    let savesCapturedVideosToPhotoLibrary: Bool         = true
    
    // Default Configuration
    public static var `default`: RACaptureSettings {
        return RACaptureSettings(
            cameraMode: .photo,
            savesCapturedPhotosToPhotoLibrary: false
        )
    }
}

extension RACaptureSettings.CameraMode {
    /// transforms user related enum to specific internal capture session enum
    
    var captureSessionPresetConfiguration: RACaptureSession.SessionPresetConfiguration {
        switch self {
        case .photo: return .photos
        case .video: return .videos
        case .photoAndLivePhoto: return .livePhotos
        case .photoAndVideo: return .videos
        }
    }
}
