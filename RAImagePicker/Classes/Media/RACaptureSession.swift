//
//  RACaptureSession.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import UIKit
import Foundation
import AVFoundation
import Photos

/*
    Progress and States of Capturing Photo Process Delegation
*/
protocol RACaptureSessionPhotoCapturingDelegate : class {
    
    // Called as soon as the photo taken [used for UI update]
    func captureSession(_ session: RACaptureSession, willCapturePhotoWith settings: AVCapturePhotoSettings)
    
    // Captured photo and ready to use it
    func captureSession(_ session: RACaptureSession, didCapturePhotoData: Data, with settings: AVCapturePhotoSettings)
    
    // Failed to capture photo
    func captureSession(_ session: RACaptureSession, didFailCapturingPhotoWith error: Error)
    
    // Control number of live photos [inProgressLivePhotoCapturesCount: current count]
    func captureSessionDidChangeNumberOfProcessingLivePhotos(_ session: RACaptureSession)
}

/*
    Progress and States of Recording Video Process Delegation
 */
protocol RACaptureSessionVideoRecordingDelegate : class {
    
    // Video file recording output has been added to the session
    func captureSessionDidBecomeReadyForVideoRecording(_ session: RACaptureSession)
    
    // Started recording
    func captureSessionDidStartVideoRecording(_ session: RACaptureSession)
    
    // Cancel recording
    func captureSessionDidCancelVideoRecording(_ session: RACaptureSession)
    
    // Failed recording
    func captureSessionDid(_ session: RACaptureSession, didFailVideoRecording error: Error)
    
    // Successfully finshed recording
    func captureSessionDid(_ session: RACaptureSession, didFinishVideoRecording videoURL: URL)
    
    // Get interruption due to a system thing, so it finshed premturely
    func captureSessionDid(_ session: RACaptureSession, didInterruptVideoRecording videoURL: URL, reason: Error)
}

protocol RACaptureSessionDelegate : class {
    
    // Successfully configured and started running
    func captureSessionDidResume(_ session: RACaptureSession)
    
    // Session was created and configured but failed [eg: I/O could not be added, etc ...]
    func captureSessionDidFailConfiguringSession(_ session: RACaptureSession)
    
    // Manually suspended
    func captureSessionDidSuspend(_ session: RACaptureSession)
    
    // Session was running but did fail due to any AVError reason.
    func captureSession(_ session: RACaptureSession, didFail error: AVError)

    // Session was interrupted [eg: phone call, starts an audio using control center, etc ...]
    func captureSession(_ session: RACaptureSession, wasInterrupted reason: AVCaptureSession.InterruptionReason)
    
    // Interruption is ended and the session was automatically resumed
    func captureSessionInterruptionDidEnd(_ session: RACaptureSession)

    // Failed get authorization status [eg: user denied access to video device]
    func captureSession(_ session: RACaptureSession, authorizationStatusFailed status: AVAuthorizationStatus)
    
    // Granted authorization status [eg: user grants access to video device]
    func captureSession(_ session: RACaptureSession, authorizationStatusGranted status: AVAuthorizationStatus)
}

/*
    Manages AVCaptureSession
 */
final class RACaptureSession : NSObject {
    
    // MARK: - Private Methods
    
    // Queue which communicate with methods and other sessions through it
    fileprivate let sessionQueue = DispatchQueue(label: "session_queue", attributes: [], target: nil)
    fileprivate var setupResult: SessionSetupResult = .success
    fileprivate var videoDeviceInput: AVCaptureDeviceInput!
    fileprivate lazy var videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInDuoCamera], mediaType: AVMediaType.video, position: .unspecified)
    fileprivate var videoDataOutput: AVCaptureVideoDataOutput?
    fileprivate let videoOutpuSampleBufferDelegate = RAVideoOutputSampleBufferDelegate()

    fileprivate enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    enum SessionPresetConfiguration {
        case photos, livePhotos
        case videos
    }
    
    weak var delegate: RACaptureSessionDelegate?

    let session = AVCaptureSession()
    var isSessionRunning = false
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    
    var presetConfiguration: SessionPresetConfiguration = .photos

    // Set video orientation that matches app UI.
    // Note: using this method perofre running the session, otherwise use "updateVideoOrientation()" method.
    var videoOrientation: AVCaptureVideoOrientation = .portrait

    // Updates on video output
    func updateVideoOrientation(new: AVCaptureVideoOrientation) {
        
        videoOrientation = new
        // Change orientation on all outputs
        self.previewLayer?.connection?.videoOrientation = new
        
        // TODO: Missing
        // Note: - Update orientation of video data output is blinking a bit [which is uggly]
        //       - Adding updates into a configuration block make the lag worse
        sessionQueue.async {
            // Disconnected device let the video data-ouput connection orientation reset
            // So get a new proper value
            self.videoDataOutput?.connection(with: AVMediaType.video)?.videoOrientation = new
        }
    }
    
    // MARK: - Video Recoding
    
    weak var videoRecordingDelegate: RACaptureSessionVideoRecordingDelegate?
    fileprivate var videoFileOutput: AVCaptureMovieFileOutput?
    fileprivate var videoCaptureDelegate: RAVideoCaptureDelegate?
    
    var isReadyForVideoRecording: Bool {
        return videoFileOutput != nil
    }
    var isRecordingVideo: Bool {
        return videoFileOutput?.isRecording ?? false
    }
    // Latest captured image
    var latestVideoBufferImage: UIImage? {
        return videoOutpuSampleBufferDelegate.latestImage
    }
    
    // MARK: - Photo Capturing
    
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate var inProgressPhotoCaptureDelegates = [Int64 : RAPhotoCaptureDelegate]()
    fileprivate(set) var inProgressLivePhotoCapturesCount = 0 // Number of currently processing live photos
    weak var photoCapturingDelegate: RACaptureSessionPhotoCapturingDelegate?
    
    enum LivePhotoMode {
        case on
        case off
    }

    // MARK: - Public Methods
    
    func prepare() {
        
        // Video Authorization Status, video access is required and audio is optional
        let mediaType = AVMediaType.video
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            // Granted access to the camera
            break
            
        case .notDetermined:
            // Has not been presented with the option to grant video access
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [capturedSelf = self] granted in
                if granted {
                    DispatchQueue.main.async {
                        capturedSelf.delegate?.captureSession(capturedSelf, authorizationStatusGranted: .authorized)
                    }
                }
                else {
                    capturedSelf.setupResult = .notAuthorized
                }
                capturedSelf.sessionQueue.resume()
            })
            
        default:
            // Denied access to the camera
            setupResult = .notAuthorized
        }
        
        /*
            Setup capture session
                - In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
         
            Why not do all of this on the main queue?
                - Because AVCaptureSession.startRunning() is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async { [capturedSelf = self] in
            capturedSelf.configureSession()
        }
    }

    func resume() {
        sessionQueue.async {
            
            guard self.isSessionRunning == false
                else {
                return print("Capture Session: -WARNING- trying to resume already running session")
            }
            
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                /*
                    We are not calling the delegate here explicitly, because we are observing "running" KVO on session itself.
                 */
                
            case .notAuthorized:
                print("Capture Session: not authorized")
                DispatchQueue.main.async { [weak self] in
                    let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                    self?.delegate?.captureSession(self!, authorizationStatusFailed: status)
                }
                
            case .configurationFailed:
                print("Capture Session: configuration failed")
                
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.captureSessionDidFailConfiguringSession(self!)
                }
            }
        }
    }

    func suspend() {
        
        guard setupResult == .success
            else {
            return
        }
        
        /*
            We need to capture self in order to postpone deallocation while session is properly stopped and cleaned up
         */
        sessionQueue.async { [capturedSelf = self] in
            
            guard self.isSessionRunning == true else {
                return print("Capture Session: -WARNING- trying to suspend non running session")
            }
            
            /*
                We are not calling delegate from here because, we are KVOing "isRunning" on session itself so it's called from there
             */
            capturedSelf.session.stopRunning()
            capturedSelf.isSessionRunning = self.session.isRunning
            capturedSelf.removeObservers()
        }
    }
    
    // MARK: - Private Methods

    /*
        Configuring Session:
            1. Adds Video Input
            2. Adds Video Output [Recording Videos]
            3. Adds Audio Input  [Video Recording with Audio]
            4. Adds Photo Ouput  [Capturing Photos]
     */
    private func configureSession() {
        
        guard setupResult == .success else {
            return
        }
        print("Capture Session: configuring - adding video input")
        session.beginConfiguration()
        switch presetConfiguration {
        case .livePhotos, .photos:
            session.sessionPreset = AVCaptureSession.Preset.photo
        case .videos:
            session.sessionPreset = AVCaptureSession.Preset.high
        }
        
        // 1. Adds Video Input
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDuoCamera, for: AVMediaType.video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            }
            else if let backCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            else if let frontCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            else {
                print("Capture Session: could not create capture device")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                        Why are we dispatching this to the main queue?
                            - Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                                can only be manipulated on the main thread.
                     
                        Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     */
                    self.previewLayer?.connection?.videoOrientation = self.videoOrientation
                }
            }
            else {
                print("Capture Session: could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        }
        catch {
            print("Capture Session: could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // 2. Adds Video Output [Recording Videos]
        if presetConfiguration == .videos {
            
            /*
                Caputre Session cannot support [Live Photo/Movie File Output/Video Data Output] at the same time if your capture session includes an AVCaptureMovieFileOutput, then isLivePhotoCaptureSupported property becomes false
             */
            print("Capture Session: configuring - adding movie file input")
            let movieFileOutput = AVCaptureMovieFileOutput()
            if self.session.canAddOutput(movieFileOutput) {
                self.session.addOutput(movieFileOutput)
                self.videoFileOutput = movieFileOutput
                
                DispatchQueue.main.async { [weak self] in
                    self?.videoRecordingDelegate?.captureSessionDidBecomeReadyForVideoRecording(self!)
                }
            }
            else {
                print("capture session: could not add video output to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        }
        if presetConfiguration == .livePhotos || presetConfiguration == .videos {
            
            print("Capture Session: configuring - adding audio input")
            // Add audio input, if fails no need to fail whole configuration
            do {
                let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
                
                if session.canAddInput(audioDeviceInput) {
                    session.addInput(audioDeviceInput)
                }
                else {
                    print("Capture Session: could not add audio device input to the session")
                }
            }
            catch {
                print("Capture Session: could not create audio device input: \(error)")
            }
        }
        
        if presetConfiguration == .livePhotos || presetConfiguration == .photos || presetConfiguration == .videos
        {
            // Add photo output.
            print("Capture Session: configuring - adding photo output")
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
                
                //enable live photos only if we intend to use it explicitly
                if presetConfiguration == .livePhotos {
                    photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
                    if photoOutput.isLivePhotoCaptureSupported == false {
                        print("Capture Session: configuring - requested live photo mode is not supported by the device")
                    }
                }
                print("Capture Session: configuring - live photo mode is \(photoOutput.isLivePhotoCaptureEnabled ? "enabled" : "disabled")")
            }
            else {
                print("Capture Session: could not add photo output to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        }
        
        if presetConfiguration != .videos {
            /*
                Adds Video Output, use this to capture last video sample that is used when blurring video layer.
                    Ex: When capture session is suspended, Changing configuration, etc...
             
                Note: Video Data Output, can not be connected at the same time as video file output!
             */
            videoDataOutput = AVCaptureVideoDataOutput()
            if session.canAddOutput(videoDataOutput!) {
                session.addOutput(videoDataOutput!)
                videoDataOutput!.alwaysDiscardsLateVideoFrames = true
                videoDataOutput!.setSampleBufferDelegate(videoOutpuSampleBufferDelegate, queue: videoOutpuSampleBufferDelegate.processQueue)
                
                if let connection = videoDataOutput!.connection(with: AVMediaType.video) {
                    connection.videoOrientation = self.videoOrientation
                    connection.automaticallyAdjustsVideoMirroring = false
                }
            }
            else {
                print("Capture Session: -WARNING- could not add video data output to the session")
            }
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - KVO and Notifications
    
    private var sessionRunningObserveContext = 0
    private var addedObservers = false
    
    private func addObservers() {
        
        guard addedObservers == false else { return }
        
        session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification"), object: videoDeviceInput.device)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)
        
        /*
            A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9, see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
        
        addedObservers = true
    }
    private func removeObservers() {
        
        guard addedObservers == true else { return }
        
        NotificationCenter.default.removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningObserveContext)
        
        addedObservers = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &sessionRunningObserveContext {
            let newValue = change?[.newKey] as AnyObject?
            guard let isSessionRunning = newValue?.boolValue else { return }
            
            DispatchQueue.main.async { [capturedSelf = self] in
                print("Capture Session: is running - \(isSessionRunning)")
                if isSessionRunning {
                    self.delegate?.captureSessionDidResume(capturedSelf)
                }
                else {
                    self.delegate?.captureSessionDidSuspend(capturedSelf)
                }
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture Session: runtime error: \(error)")
        
        /*
            Automatically try to restart the session running if media services were reset and the last start running succeeded. Otherwise, enable the user to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [capturedSelf = self] in
                if capturedSelf.isSessionRunning {
                    capturedSelf.session.startRunning()
                    capturedSelf.isSessionRunning = capturedSelf.session.isRunning
                }
                else {
                    DispatchQueue.main.async {
                        capturedSelf.delegate?.captureSession(capturedSelf, didFail: error)
                    }
                }
            }
        }
        else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.captureSession(self!, didFail: error)
            }
        }
    }
    @objc func sessionWasInterrupted(notification: NSNotification) {
        /*
            In some scenarios we want to enable the user to resume the session running. For example, if music playback is initiated via control center while using AVCam, then the user can let AVCam resume the session running, which will stop music playback. Note that stopping music playback in control center will not automatically resume the session running. Also note that it is not always possible to resume, see "resumeInterruptedSession(_:)".
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture Session: session was interrupted with reason \(reason)")
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.captureSession(self!, wasInterrupted: reason)
            }
        }
        else {
            print("Capture Session: session was interrupted due to unknown reason")
        }
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        
        print("Capture Session: interruption ended")
        /*
            Automatically called when interruption is done and session is automatically resumed. Delegate should know that this happened so the UI can be updated
         */
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.captureSessionInterruptionDidEnd(self!)
        }
    }
}

// MARK: - Change Camera Extension
extension RACaptureSession {
    
    @objc func subjectAreaDidChange(notification: NSNotification) {
    }
    
    func changeCamera(completion: (() -> Void)?) {
        
        guard setupResult == .success else {
            return print("Capture Session: -WARNING- trying to change camera but capture session setup failed")
        }
        
        sessionQueue.async { [unowned self] in
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = AVCaptureDevice.DeviceType.builtInDuoCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = AVCaptureDevice.DeviceType.builtInWideAngleCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
            if let device = devices.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
                newVideoDevice = device
            }
            else if let device = devices.filter({ $0.position == preferredPosition }).first {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification"), object: currentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification"), object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    }
                    else {
                        self.session.addInput(self.videoDeviceInput);
                    }
                    
                    if let connection = self.videoFileOutput?.connection(with: AVMediaType.video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    /*
                        Set Live Photo capture enabled if it is supported. When changing cameras, the "isLivePhotoCaptureEnabled" property of the AVCapturePhotoOutput gets set to NO when a video device is disconnected from the session. After the new video device is added to the session, re-enable Live Photo capture on the AVCapturePhotoOutput if it is supported.
                     */
                    self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported && self.presetConfiguration == .livePhotos;
                    
                    /*
                        When Device is Disconnected:
                            - Video Data Output connection orientation is reset, so we need to set to new proper value
                            - Video Mirroring is set to true if camera is front, make sure we use no mirroring
                     */
                    if let videoDataOutputConnection = self.videoDataOutput?.connection(with: AVMediaType.video) {
                        videoDataOutputConnection.videoOrientation = self.videoOrientation
                        if videoDataOutputConnection.isVideoMirroringSupported {
                            videoDataOutputConnection.isVideoMirrored = true
                        }
                        else {
                            print("Capture Session: -WARNING- video mirroring on video data output is not supported")
                        }
                        
                    }
                    self.session.commitConfiguration()
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
                catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
        }
    }
}

// MARK: - Capture Photos Extension
extension RACaptureSession {
    
    func capturePhoto(livePhotoMode: LivePhotoMode, saveToPhotoLibrary: Bool) {
        /*
            Retrieve the video preview layer's video orientation on the main queue before entering the session queue. We do this to ensure UI elements are accessed on the main thread and session configuration is done on the session queue.
         */
        guard let videoPreviewLayerOrientation = previewLayer?.connection?.videoOrientation else {
            return print("Capture Session: -WARNING- trying to capture a photo but no preview layer is set")
        }
        
        sessionQueue.async {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput.connection(with: AVMediaType.video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
            }
            
            // Capture a JPEG photo with flash set to auto and high resolution photo enabled.
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            photoSettings.isHighResolutionPhotoEnabled = true
            
            // TODO: Missing - "previewPhotoFormat" Preview Photo/Thumbnail
            if #available(iOS 11.0, *) {
                if photoSettings.availableEmbeddedThumbnailPhotoCodecTypes.count > 0 {
                    let previewPixelType = photoSettings.availablePreviewPhotoPixelFormatTypes.first!
                    let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                         kCVPixelBufferWidthKey as String: 200,
                                         kCVPixelBufferHeightKey as String: 200,
                                         ]
                    photoSettings.previewPhotoFormat = previewFormat
                }
            }
            
            if livePhotoMode == .on {
                if self.presetConfiguration == .livePhotos && self.photoOutput.isLivePhotoCaptureSupported {
                    let livePhotoMovieFileName = NSUUID().uuidString
                    let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
                    photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
                }
                else {
                    print("Capture Session: -WARNING- trying to capture live photo but it's not supported by current configuration, capturing regular photo instead")
                }
            }
            
            // Useing separate object for the photo capture delegate to isolate each capture life cycle.
            let photoCaptureDelegate = RAPhotoCaptureDelegate(with: photoSettings, willCapturePhotoAnimation: {
                DispatchQueue.main.async { [unowned self] in
                    self.photoCapturingDelegate?.captureSession(self, willCapturePhotoWith: photoSettings)
                }
            }, capturingLivePhoto: { capturing in
                /* Because Live Photo captures can overlap, we need to keep track of the number of in progress Live Photo captures to ensure that the Live Photo label stays visible during these captures.
                 */
                self.sessionQueue.async { [unowned self] in
                    if capturing {
                        self.inProgressLivePhotoCapturesCount += 1
                    }
                    else {
                        self.inProgressLivePhotoCapturesCount -= 1
                    }
                    
                    let inProgressLivePhotoCapturesCount = self.inProgressLivePhotoCapturesCount
                    DispatchQueue.main.async { [unowned self] in
                        if inProgressLivePhotoCapturesCount >= 0 {
                            self.photoCapturingDelegate?.captureSessionDidChangeNumberOfProcessingLivePhotos(self)
                        }
                        else {
                            print("Capture Session: -Error- in progress live photo capture count is less than 0");
                        }
                    }
                }
            }, completed: { [unowned self] delegate in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async { [unowned self] in
                    self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = nil
                }
                
                DispatchQueue.main.async {
                    if let data = delegate.photoData {
                        self.photoCapturingDelegate?.captureSession(self, didCapturePhotoData: data, with: delegate.requestedPhotoSettings)
                    }
                    else if let error = delegate.processError {
                        self.photoCapturingDelegate?.captureSession(self, didFailCapturingPhotoWith: error)
                    }
                }
            })
            
            photoCaptureDelegate.savesPhotoToLibrary = saveToPhotoLibrary
            
            /*
                The Photo Output keeps a weak reference to the photo capture delegate so we store it in an array to maintain a strong reference to this object until the capture is completed.
             */
            self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = photoCaptureDelegate
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
        }
    }
}

// MARK: - Recording Videos Extension
extension RACaptureSession {
    
    func startVideoRecording(saveToPhotoLibrary: Bool) {
        
        guard let movieFileOutput = self.videoFileOutput else {
            return print("Capture Session: trying to record a video but no movie file output is set")
        }
        
        guard let previewLayer = self.previewLayer else {
            return print("Capture Session: trying to record a video but no preview layer is set")
        }
        
        /*
            Retrieve the video preview layer's video orientation on the main queue before entering the session queue. We do this to ensure UI elements are accessed on the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewLayer.connection?.videoOrientation
        sessionQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            // If already recording do nothing
            guard movieFileOutput.isRecording == false else {
                return print("Capture Session: trying to record a video but there is one already being recorded")
            }
            // Update the orientation on the movie file output video connection before starting recording.
            let movieFileOutputConnection = strongSelf.videoFileOutput?.connection(with: AVMediaType.video)
            movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
            // Start recording to a temporary file.
            let outputFileName = NSUUID().uuidString
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")
            // Create a recording delegate
            let recordingDelegate = RAVideoCaptureDelegate(didStart: {
                DispatchQueue.main.async { [weak self] in
                    self?.videoRecordingDelegate?.captureSessionDidStartVideoRecording(self!)
                }
            }, didFinish: { (delegate) in
                // We need to remove reference to the delegate so it can be deallocated
                self?.sessionQueue.async {
                    self?.videoCaptureDelegate = nil
                }
                DispatchQueue.main.async { [weak self] in
                    if delegate.isBeingCancelled {
                        self?.videoRecordingDelegate?.captureSessionDidCancelVideoRecording(self!)
                    }
                    else {
                        self?.videoRecordingDelegate?.captureSessionDid(self!, didFinishVideoRecording: outputURL)
                    }
                }
                
            }, didFail: { (delegate, error) in
                // We need to remove reference to the delegate so it can be deallocated
                self?.sessionQueue.async {
                    self?.videoCaptureDelegate = nil
                }
                DispatchQueue.main.async { [weak self] in
                    if delegate.recordingWasInterrupted {
                        self?.videoRecordingDelegate?.captureSessionDid(self!, didInterruptVideoRecording: outputURL, reason: error)
                    }
                    else {
                        self?.videoRecordingDelegate?.captureSessionDid(self!, didFailVideoRecording: error)
                    }
                }
            })
            recordingDelegate.savesVideoToLibrary = saveToPhotoLibrary
            // Start recording
            movieFileOutput.startRecording(to: outputURL, recordingDelegate: recordingDelegate)
            strongSelf.videoCaptureDelegate = recordingDelegate
        }
    }

    /*
        If there is any recording in progress it will be stopped
            - cancel: Bool,  if true, recorded file will be deleted and corresponding delegate method will be called.
     */
    func stopVideoRecording(cancel: Bool = false) {
        
        guard let movieFileOutput = self.videoFileOutput else {
            return print("Capture Session: trying to stop a video recording but no movie file output is set")
        }
        
        sessionQueue.async { [capturedSelf = self] in
            
            guard movieFileOutput.isRecording else {
                return print("Capture Session: trying to stop a video recording but no recording is in progress")
            }
            
            guard let recordingDelegate = capturedSelf.videoCaptureDelegate else {
                fatalError("Capture Session: trying to stop a video recording but video capture delegate is nil")
            }
            
            recordingDelegate.isBeingCancelled = cancel
            movieFileOutput.stopRecording()
        }
    }
}
