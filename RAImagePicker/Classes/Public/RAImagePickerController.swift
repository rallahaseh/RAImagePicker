//
//  RAImagePickerController.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import UIKit
import Foundation
import Photos

/*
    Methods to delegate with image picker processing
 */
public protocol RAImagePickerControllerDelegate : class {
    
    // Called when taps on action item [0 or 1]
    func imagePicker(controller: RAImagePickerController, didSelectActionItemAt index: Int)
    
    // Called when select an asset.
    func imagePicker(controller: RAImagePickerController, didSelect asset: PHAsset)
    
    // Called when unselect a previously selected asset.
    func imagePicker(controller: RAImagePickerController, didDeselect asset: PHAsset)
    
    // Called when user takes new photo.
    func imagePicker(controller: RAImagePickerController, didTake image: UIImage)
    
    // Called before displaying CollectionViewCell to configure the cell.
    func imagePicker(controller: RAImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int)
    
    // Called before displaying CollectionViewCell to configure the cell based on asset media type, subtype, ..etc.
    func imagePicker(controller: RAImagePickerController, willDisplayAssetItem cell: RAImagePickerAssetCell, asset: PHAsset)
}

// Optional Delegate Methods
extension RAImagePickerControllerDelegate {
    public func imagePicker(controller: RAImagePickerController, didSelectActionItemAt index: Int) {}
    public func imagePicker(controller: RAImagePickerController, didSelect asset: PHAsset) {}
    public func imagePicker(controller: RAImagePickerController, didUnselect asset: PHAsset) {}
    public func imagePicker(controller: RAImagePickerController, didTake image: UIImage) {}
    public func imagePicker(controller: RAImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {}
    public func imagePicker(controller: RAImagePickerController, willDisplayAssetItem cell: RAImagePickerAssetCell, asset: PHAsset) {}
}

// ImagePicker Data Source Methods
public protocol RAImagePickerControllerDataSource : class {
    
    // Check view thats placed as overlay view with permissions.
    // if the user did not grant or has restricted access to photo library.
    func imagePicker(controller: RAImagePickerController,  viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView
}

open class RAImagePickerController : UIViewController {
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        captureSession?.suspend()
    }
    
    // MARK: - Public APIs
    
    // Configure layout of action, camera and asset items
    public var layoutConfiguration = RALayoutConfiguration.default
    
    // Register a cell classes or nibs for each item types
    public lazy var cellRegistrator = RACellRegistrator()
    
    // Settings to configure how the capturing should behave
    public var captureSettings = RACaptureSettings.default
    
    // Get informed about user interaction and changes
    public weak var delegate: RAImagePickerControllerDelegate?
    
    // Provide additional data when requested by Image Picker
    public weak var dataSource: RAImagePickerControllerDataSource?
    
    // Selecting asset. programatically
    public func selectAsset(at index: Int, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
        let path = IndexPath(item: index, section: layoutConfiguration.sectionIndexForAssets)
        collectionView.selectItem(at: path, animated: animated, scrollPosition: scrollPosition)
    }
    
    // Deselecting asset. programatically
    public func deselectAsset(at index: Int, animated: Bool) {
        let path = IndexPath(item: index, section: layoutConfiguration.sectionIndexForAssets)
        collectionView.deselectItem(at: path, animated: animated)
    }
    
    // Deselect all selected asstes programatically
    public func deselectAllAssets(animated: Bool) {
        for selectedPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: selectedPath, animated: animated)
        }
    }
    
    // Access all selected images
    public var selectedAssets: [PHAsset] {
        get {
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
            let selectedAssets = selectedIndexPaths.flatMap { indexPath in
                return asset(at: indexPath.row)
            }
            return selectedAssets
        }
    }
    
    // Returns asstes at indices (IndexSet)
    public func assets(at indexes: IndexSet) -> [PHAsset] {
        guard let fetchResult = collectionViewDataSource.assetsModel.fetchResult else {
            fatalError("Accessing assets at indexes \(indexes) failed")
        }
        return fetchResult.objects(at: indexes)
    }
    // Return asset. at index
    public func asset(at index: Int) -> PHAsset {
        guard let fetchResult = collectionViewDataSource.assetsModel.fetchResult else {
            fatalError("Accessing asset at index \(index) failed")
        }
        return fetchResult.object(at: index)
    }
    
    // Fetch asstes to be used for picking. [default if leaved nil will be taken from smart album]
    public var assetsFetchResultBlock: (() -> PHFetchResult<PHAsset>?)?
    
    
    // Global appearance proxy object. [set appearance for all instances of ImagePicker]
    public static func appearance() -> RAAppearance {
        return classAppearanceProxy
    }
    
    // Instance appearance proxy object. [set appearance for particular instance of ImagePicker]
    public func appearance() -> RAAppearance {
        if instanceAppearanceProxy == nil {
            instanceAppearanceProxy = RAAppearance()
        }
        return instanceAppearanceProxy!
    }
    
    // UICollectionView object that displays the content.
    public var collectionView: UICollectionView! {
        return imagePickerView.collectionView
    }
    
    // MARK: - Private Methods
    
    fileprivate var imagePickerView: RAImagePickerView! {
        return view as! RAImagePickerView
    }
    fileprivate var collectionViewDataSource    = RAImagePickerDataSource(assetsModel: RAImagePickerAssetModel())
    fileprivate var collectionViewDelegate      = RAImagePickerDelegate()
    fileprivate var captureSession: RACaptureSession?
    
    private func updateItemSize() {
        
        guard let layout = self.collectionViewDelegate.layout else {
            return
        }
        let itemsInRow = layoutConfiguration.numberOfAssetItemsInRow
        let scrollDirection = layoutConfiguration.scrollDirection
        let cellSize = layout.sizeForItem(numberOfItemsInRow: itemsInRow, preferredWidthOrHeight: nil, collectionView: collectionView, scrollDirection: scrollDirection)
        let scale = UIScreen.main.scale
        let thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        self.collectionViewDataSource.assetsModel.thumbnailSize = thumbnailSize
    }
    
    private func updateContentInset() {
        if #available(iOS 11.0, *) {
            collectionView.contentInset.left = view.safeAreaInsets.left
            collectionView.contentInset.right = view.safeAreaInsets.right
        }
    }
    
    // OverlayView used only when need to hide picker, for example there is no permissions to the gallery.
    private var overlayView: UIView?
    
    // Based on authorization status of photo library, reload collectionView layout/data
    private func reloadData(basedOnAuthorizationStatus status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            collectionViewDataSource.assetsModel.fetchResult = assetsFetchResultBlock?()
            collectionViewDataSource.layoutModel = RALayoutModel(configuration: layoutConfiguration, assets: collectionViewDataSource.assetsModel.fetchResult.count)
            
        case .restricted, .denied:
            if let view = overlayView ?? dataSource?.imagePicker(controller: self, viewForAuthorizationStatus: status), view.superview != collectionView {
                collectionView.backgroundView = view
                overlayView = view
            }
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async {
                    self.reloadData(basedOnAuthorizationStatus: status)
                }
            })
        }
    }
    
    // Based on authorization status of camera input(video), reload collectionView layout/data
    fileprivate func reloadCameraCell(basedOnAuthorizationStatus status: AVAuthorizationStatus) {
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        cameraCell.authorizationStatus = status
    }
    
    // Appearance object for global instances
    static let classAppearanceProxy = RAAppearance()
    
    // Appearance object for an instance
    var instanceAppearanceProxy: RAAppearance?
    
    // MARK: - View Lifecycle
    open override func loadView() {        
        let nib = UINib(nibName: "RAImagePickerView", bundle: Bundle(for: RAImagePickerView.self))
        view = nib.instantiate(withOwner: nil, options: nil)[0] as! RAImagePickerView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply Appearance
        let appearance = instanceAppearanceProxy ?? RAImagePickerController.classAppearanceProxy
        imagePickerView.backgroundColor = appearance.backgroundColor
        collectionView.backgroundColor = appearance.backgroundColor
        
        // Configure Flow Layout
        let collectionViewLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        collectionViewLayout.scrollDirection = layoutConfiguration.scrollDirection
        collectionViewLayout.minimumInteritemSpacing = layoutConfiguration.interitemSpacing
        collectionViewLayout.minimumLineSpacing = layoutConfiguration.interitemSpacing
        
        // Finish Configuring Collection View
        collectionView.dataSource = self.collectionViewDataSource
        collectionView.delegate = self.collectionViewDelegate
        collectionView.allowsMultipleSelection = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        switch layoutConfiguration.scrollDirection {
        case .horizontal: collectionView.alwaysBounceHorizontal = true
        case .vertical: collectionView.alwaysBounceVertical = true
        }
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        // Gesture Recognizer to Detect Taps on a Camera Cell (where selection is disabled)
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(sender:)))
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        
        // Apply Cell Registrator to Collection View
        collectionView.apply(registrator: cellRegistrator, cameraMode: captureSettings.cameraMode)
        
        collectionViewDataSource.cellRegistrator = cellRegistrator
        collectionViewDelegate.delegate = self
        collectionViewDelegate.layout = RAImagePickerLayout(configuration: layoutConfiguration)
        
        // TODO: Change the way of using PHLibrary, which is used when changing permissions
        PHPhotoLibrary.shared().register(self)
        // Determine Auth Satus and Based on that Reload UI
        reloadData(basedOnAuthorizationStatus: PHPhotoLibrary.authorizationStatus())
        
        // Configure RACaptureSession
        if layoutConfiguration.showsCameraItem {
            let session = RACaptureSession()
            captureSession = session
            session.presetConfiguration = captureSettings.cameraMode.captureSessionPresetConfiguration
            session.videoOrientation = UIApplication.shared.statusBarOrientation.captureVideoOrientation
            session.delegate = self
            session.videoRecordingDelegate = self
            session.photoCapturingDelegate = self
            session.prepare()
        }
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateItemSize()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContentInset()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // Detect interface rotates/changes, which is can be used to reload UICollectionView layout.
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        // Update RACaptureSession with new interface orientation
        captureSession?.updateVideoOrientation(new: UIApplication.shared.statusBarOrientation.captureVideoOrientation)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.updateContentInset()
        }) { (context) in
            self.updateItemSize()
        }
        
    }
    
    // MARK: - Private Methods
    @objc private func tapGestureRecognized(sender: UIGestureRecognizer) {
        
        guard sender.state == .ended else {
            return
        }
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        let point = sender.location(in: cameraCell)
        if cameraCell.touchIsCaptureEffective(point: point) {
            takePicture()
        }
    }
}

// MARK: - PHPhotoLibrary Observer Extension
extension RAImagePickerController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let fetchResult = collectionViewDataSource.assetsModel.fetchResult else {
            return
        }
        DispatchQueue.main.sync {
            guard let changes = changeInstance.changeDetails(for: fetchResult) else {
                // Reload UICollectionView
                self.collectionView.reloadData()
                return
            }
            // Update Fetch Result
            collectionViewDataSource.assetsModel.fetchResult = changes.fetchResultAfterChanges
            // Update Layout Model
            collectionViewDataSource.layoutModel = RALayoutModel(configuration: layoutConfiguration, assets: collectionViewDataSource.assetsModel.fetchResult.count)
            
            if changes.hasIncrementalChanges {
                
                let assetItemsSection = layoutConfiguration.sectionIndexForAssets
                
                // Animate Incremental Differences in UICollectionView
                self.collectionView.performBatchUpdates({
                    
                    // Update Steps: Delete -> Insert -> Reload -> Move
                    if let removed = changes.removedIndexes, removed.isEmpty == false {
                        self.collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.isEmpty == false {
                        self.collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    if let changed = changes.changedIndexes, changed.isEmpty == false {
                        self.collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: assetItemsSection), to: IndexPath(item: toIndex, section: assetItemsSection))
                    }
                })
            }
            else {
                // No Differences
                // Reload UICollectionView
                collectionView.reloadData()
            }
        }
    }
}

// MARK: - Controller && ImagePickerDelegate Extension
extension RAImagePickerController : ImagePickerDelegate {
    
    func imagePicker(delegate: RAImagePickerDelegate, didSelectActionItemAt index: Int) {
        self.delegate?.imagePicker(controller: self, didSelectActionItemAt: index)
    }
    
    func imagePicker(delegate: RAImagePickerDelegate, didSelectAssetItemAt index: Int) {
        self.delegate?.imagePicker(controller: self, didSelect: asset(at: index))
    }
    
    func imagePicker(delegate: RAImagePickerDelegate, didDeselectAssetItemAt index: Int) {
        self.delegate?.imagePicker(controller: self, didDeselect: asset(at: index))
    }
    
    func imagePicker(delegate: RAImagePickerDelegate, willDisplayActionCell cell: UICollectionViewCell, at index: Int)
    {
        if let defaultCell = cell as? RAActionCell {
            defaultCell.update(withIndex: index, layoutConfiguration: layoutConfiguration)
        }
        self.delegate?.imagePicker(controller: self, willDisplayActionItem: cell, at: index)
    }
        
    func imagePicker(delegate: RAImagePickerDelegate, willDisplayAssetCell cell: RAImagePickerAssetCell, at index: Int)
    {
        let theAsset = asset(at: index)
        // Default Cell = Update Cell Asset.
        if let defaultCell = cell as? VideoAssetCell {
            defaultCell.update(with: theAsset)
        }
        self.delegate?.imagePicker(controller: self, willDisplayAssetItem: cell, asset: theAsset)
    }
    
    func imagePicker(delegate: RAImagePickerDelegate, willDisplayCameraCell cell: RACameraCollectionViewCell) {
        if cell.delegate == nil {
            cell.delegate = self
            cell.previewView.session = captureSession?.session
            captureSession?.previewLayer = cell.previewView.previewLayer
            /*
                Using videos preset means using different technique for blurring the cell content
                isVisualEffectViewUsedForBlurring = true, then UIVisualEffectView is used for blurring
                isVisualEffectViewUsedForBlurring = false, then manually blur video data output frame
             */
            if let config = captureSession?.presetConfiguration, config == .videos {
                cell.isVisualEffectViewUsedForBlurring = true
            }
            
        }
        // Default cell RALivePhotoCameraCell, Update Based on Camera Config
        if let liveCameraCell = cell as? RALivePhotoCameraCell {
            liveCameraCell.updateWithCameraMode(captureSettings.cameraMode)
        }
        
        // Update Live Photos
        let inProgressLivePhotos = captureSession?.inProgressLivePhotoCapturesCount ?? 0
        cell.updateLivePhotoStatus(isProcessing: inProgressLivePhotos > 0, shouldAnimate: false)
        
        // Update Video Recording Status
        let isRecordingVideo = captureSession?.isRecordingVideo ?? false
        cell.updateRecordingVideoStatus(isRecording: isRecordingVideo, shouldAnimate: false)
        
        // Update Authorization Status
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if cell.authorizationStatus != status {
            cell.authorizationStatus = status
        }
        
        // Resume Session [Only if not recording video]
        if isRecordingVideo == false {
            captureSession?.resume()
        }
    }
    
    func imagePicker(delegate: RAImagePickerDelegate, didEndDisplayingCameraCell cell: RACameraCollectionViewCell)
    {
        
        let isRecordingVideo = captureSession?.isRecordingVideo ?? false
        // Suspend Session [Only if not recording video]
        // Otherwise the Recording Would be Stopped.
        if isRecordingVideo == false {
            captureSession?.suspend()
            
            // Blur Cell ASAP[as soon as possible]
            DispatchQueue.global(qos: .userInteractive).async {
                if let image = self.captureSession?.latestVideoBufferImage {
                    // Add UIImageEffects Library if needed
                    let blurred = UIImageEffects.imageByApplyingLightEffect(to: image)
                    DispatchQueue.main.async {
                        cell.blurEffect(blurImage: blurred, animated: false, completion: nil)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        cell.blurEffect(blurImage: nil, animated: false, completion: nil)
                    }
                }
            }
        }
    }
    
    func imagePicker(delegate: RAImagePickerDelegate, didScroll scrollView: UIScrollView) {
        guard isViewLoaded && view.window != nil else { return }
        collectionViewDataSource.assetsModel.updateCachedAssets(collectionView: collectionView)
    }
}

// MARK: - Controller && RACaptureSessionDelegate Extension
extension RAImagePickerController : RACaptureSessionDelegate {
    
    func captureSessionDidResume(_ session: RACaptureSession) {
        debugPrint("CaptureSession: Did Resume")
        unblurCell(animated: true)
    }
    
    func captureSessionDidSuspend(_ session: RACaptureSession) {
        debugPrint("CaptureSession: Did Suspend")
        blurCell(animated: true)
    }
    
    func captureSession(_ session: RACaptureSession, didFail error: AVError) {
        debugPrint("CaptureSession: Did Fail")
    }
    
    func captureSessionDidFailConfiguringSession(_ session: RACaptureSession) {
        debugPrint("CaptureSession: Did Fail Configuring")
    }
    
    func captureSession(_ session: RACaptureSession, authorizationStatusFailed status: AVAuthorizationStatus) {
        debugPrint("CaptureSession: Did Fail Get Camera Authorization")
        reloadCameraCell(basedOnAuthorizationStatus: status)
    }
    
    func captureSession(_ session: RACaptureSession, authorizationStatusGranted status: AVAuthorizationStatus) {
        debugPrint("CaptureSession: Did Grant Camera Authorization")
        reloadCameraCell(basedOnAuthorizationStatus: status)
    }
    
    func captureSession(_ session: RACaptureSession, wasInterrupted reason: AVCaptureSession.InterruptionReason) {
        debugPrint("CaptureSession: Interrupted")
    }
    
    func captureSessionInterruptionDidEnd(_ session: RACaptureSession) {
        debugPrint("CaptureSession: Interruption Ended")
    }
    
    private func blurCell(animated: Bool) {
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else { return }
        guard let captureSession = captureSession else { return }
        cameraCell.blurEffect(blurImage: captureSession.latestVideoBufferImage, animated: animated, completion: nil)
    }
    
    private func unblurCell(animated: Bool) {
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        
        cameraCell.unblurEffect(unblurImage: nil, animated: animated, completion: nil)
    }
}

// MARK: - Controller && RACaptureSessionPhotoCapturingDelegate Extension
extension RAImagePickerController : RACaptureSessionPhotoCapturingDelegate {
    
    func captureSession(_ session: RACaptureSession, didCapturePhotoData: Data, with settings: AVCapturePhotoSettings) {
        debugPrint("Photo CaptureSession: Did Capture Photo - \(settings.uniqueID)")
        delegate?.imagePicker(controller: self, didTake: UIImage(data: didCapturePhotoData)!)
    }
    
    func captureSession(_ session: RACaptureSession, willCapturePhotoWith settings: AVCapturePhotoSettings) {
        debugPrint("Photo CaptureSession: Will Capture Photo - \(settings.uniqueID)")
    }
    
    func captureSession(_ session: RACaptureSession, didFailCapturingPhotoWith error: Error) {
        debugPrint("Photo CaptureSession: Did Fail Capturing - \(error)")

    }
    
    func captureSessionDidChangeNumberOfProcessingLivePhotos(_ session: RACaptureSession) {
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        let count = session.inProgressLivePhotoCapturesCount
        cameraCell.updateLivePhotoStatus(isProcessing: count > 0, shouldAnimate: true)
    }
}

// MARK: - Controller && RACaptureSessionVideoRecordingDelegate Extension
extension RAImagePickerController : RACaptureSessionVideoRecordingDelegate {
    
    func captureSessionDidBecomeReadyForVideoRecording(_ session: RACaptureSession) {
        debugPrint("Video CaptureSession: Ready for Recording Video")
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else { return }
        cameraCell.videoRecodingDidBecomeReady()
    }
    
    func captureSessionDidStartVideoRecording(_ session: RACaptureSession) {
        debugPrint("Video CaptureSession: Did Start Recording Video")
        updateCameraCellRecordingStatusIfNeeded(isRecording: true, animated: true)
    }
    
    func captureSessionDidCancelVideoRecording(_ session: RACaptureSession) {
        debugPrint("Video CaptureSession: Did Cancel Recording Video")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    func captureSessionDid(_ session: RACaptureSession, didFinishVideoRecording videoURL: URL) {
        debugPrint("Video CaptureSession: Did Finish Recording Video")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    func captureSessionDid(_ session: RACaptureSession, didInterruptVideoRecording videoURL: URL, reason: Error) {
        debugPrint("Video CaptureSession: Recording Video Has Been Interrupted Due - \(reason)")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    func captureSessionDid(_ session: RACaptureSession, didFailVideoRecording error: Error) {
        debugPrint("Video CaptureSession: Did Fail Recording Video")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    private func updateCameraCellRecordingStatusIfNeeded(isRecording: Bool, animated: Bool) {
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else { return }
        cameraCell.updateRecordingVideoStatus(isRecording: isRecording, shouldAnimate: animated)
    }
}

// MARK: - Controller && RACameraCollectionViewCellDelegate Extension
extension RAImagePickerController: RACameraCollectionViewCellDelegate {
    
    func takePicture() {
        captureSession?.capturePhoto(livePhotoMode: .off, saveToPhotoLibrary: captureSettings.savesCapturedPhotosToPhotoLibrary)
    }
    
    func takeLivePhoto() {
        captureSession?.capturePhoto(livePhotoMode: .on, saveToPhotoLibrary: captureSettings.savesCapturedLivePhotosToPhotoLibrary)
    }
    
    func startVideoRecording() {
        captureSession?.startVideoRecording(saveToPhotoLibrary: captureSettings.savesCapturedVideosToPhotoLibrary)
    }
    
    func stopVideoRecording() {
        captureSession?.stopVideoRecording(cancel: false)
    }
    
    func flipCamera(_ completion: (() -> Void)? = nil) {
        
        guard let captureSession = captureSession else { return  }
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return captureSession.changeCamera(completion: completion)
        }
        
        // Add UIImageEffects Library if needed
        var image = captureSession.latestVideoBufferImage
        if image != nil {
            image = UIImageEffects.imageByApplyingLightEffect(to: image!)
        }
        // 1. Blur
        cameraCell.blurEffect(blurImage: image, animated: true) { _ in
            // 2. Flip Camera
            captureSession.changeCamera(completion: {
                // 3. Flip Animation
                UIView.transition(with: cameraCell.previewView, duration: 0.25, options: [.transitionFlipFromLeft, .allowAnimatedContent], animations: nil) { (finished) in
                    // 4. Set New Image from Buffer
                    var image = captureSession.latestVideoBufferImage
                    if image != nil {
                        image = UIImageEffects.imageByApplyingLightEffect(to: image!)
                    }
                    // 5. Unblur
                    cameraCell.unblurEffect(unblurImage: image, animated: true, completion: { _ in
                        completion?()
                    })
                }
            })
        }
    }
}



