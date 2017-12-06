//
//  RAVideoCaptureDelegate.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import AVFoundation
import Photos

final class RAVideoCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    // MARK: - Public Methods
    
    // Save videos to library by default true
    var savesVideoToLibrary = true
    
    // Flag to detect when canceling recording(stope without saving)
    var isBeingCancelled = false
    
    // Flag to detect when system inturrupts recording due to various reasons (phone call, background, empty space, ...)
    var recordingWasInterrupted = false
    
    // Recording errors (nil if cancelled and none if failed or interrupted)
    private(set) var recordingError: Error?
    
    init(didStart: @escaping ()->(), didFinish: @escaping (RAVideoCaptureDelegate)->(), didFail: @escaping (RAVideoCaptureDelegate, Error)->()) {
        self.didStart = didStart
        self.didFinish = didFinish
        self.didFail = didFail
        
        if UIDevice.current.isMultitaskingSupported {
            /*
                Setup background task.
                    - This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
                      callback is not received until AVCam returns to the foreground unless you request background
                      execution time.
                    - This also ensures that there will be time to write the file to the photo library when
                      AVCam is backgrounded.
                    - To conclude this background execution, endBackgroundTask(_:) is called in
                      `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
                      after the recorded file has been saved.
             */
            self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
    }
    
    // MARK: - Private Methods
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier? = nil
    private var didStart: ()->()
    private var didFinish: (RAVideoCaptureDelegate)->()
    private var didFail: (RAVideoCaptureDelegate, Error)->()
    
    private func cleanUp(deleteFile: Bool, saveToAssets: Bool, outputFileURL: URL) {
        
        func deleteFileIfNeeded() {
            guard deleteFile == true else { return }
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                }
                catch let error {
                    print("capture session: could not remove recording at url: \(outputFileURL)")
                    print("capture session: error: \(error)")
                }
            }
        }
        
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskInvalid
            if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }
        
        if saveToAssets {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        let videoResourceOptions = PHAssetResourceCreationOptions()
                        videoResourceOptions.shouldMoveFile = true
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: videoResourceOptions)
                    }, completionHandler: { success, error in
                        if let error = error {
                            print("capture session: Error occurered while saving video to photo library: \(error)")
                            deleteFileIfNeeded()
                        }
                    })
                }
                else {
                    deleteFileIfNeeded()
                }
            }
        }
        else {
            deleteFileIfNeeded()
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate Methods
    
    func fileOutput(_ captureOutput: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        didStart()
    }
    
    func fileOutput(_ captureOutput: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            
            recordingError = error
            
            print("capture session: movie recording failed error: \(error)")
            
            // Flag to check the video can be delivered even if the recording stopped due to a reason (no space, ..)
            let successfullyFinished = (((error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue) ?? false
            
            if successfullyFinished {
                recordingWasInterrupted = true
                cleanUp(deleteFile: true, saveToAssets: savesVideoToLibrary, outputFileURL: outputFileURL)
                didFail(self, error)
            }
            else {
                cleanUp(deleteFile: true, saveToAssets: false, outputFileURL: outputFileURL)
                didFail(self, error)
            }
        }
        else if isBeingCancelled == true {
            cleanUp(deleteFile: true, saveToAssets: false, outputFileURL: outputFileURL)
            didFinish(self)
        }
        else {
            cleanUp(deleteFile: true, saveToAssets: savesVideoToLibrary, outputFileURL: outputFileURL)
            didFinish(self)
        }
    }
}

