//
//  ViewController.swift
//  RAImagePicker
//
//  Created by rallahaseh on 11/29/2017.
//  Copyright (c) 2017 rallahaseh. All rights reserved.
//

import UIKit
import Photos
import RAImagePicker

class ViewController: UIViewController {

    @IBOutlet weak var switchControl: UISwitch!
    
    var currentInputView: UIView?
    
    lazy var presentButton: UIButton = {
        let button = UIButton(type: .custom)
        var bottomAdjustment: CGFloat       = 0
        button.frame.size                   = CGSize(width: 0, height: 44 + bottomAdjustment)
        button.contentEdgeInsets.bottom     = bottomAdjustment / 2
        button.backgroundColor              = .white
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitle(NSLocalizedString("Present", comment: "Present Button"), for: .normal)
        button.setTitle(NSLocalizedString("Dismiss", comment: "Dismiss Title"), for: .selected)
        button.addTarget(self, action: #selector(presentButtonTapped(sender:)), for: .touchUpInside)
        return button
    }()

    // MARK: -  RAImagePickerController Configuration
    
    // Presentation Mode ? (true = vertical, false = horizontal)
    var presentsModally: Bool                       = false
    // Number of asset. per row ?
    var assetItemsInRow: Int                        = 2
    // Camera Type ?
    var captureMode: RACaptureSettings.CameraMode   = .photoAndLivePhoto
    // Save Captured Assets ?
    var savesCapturedAssets: Bool                   = false
    
    // RAImagePicer Viewer
    enum AssetsSource: Int {
        // _default is the RAImagePicker default cells
        case _default
        // custom
        case gallery
        case selfies
        case videos
    }
    var assetsSource: AssetsSource = .gallery

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.title = "RAImagePicker"
    }
    
    @IBAction func setPresentationMode(_ sender: UISwitch!) {
        presentsModally = sender.isOn ? true : false
    }
    
    @objc func presentButtonTapped(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            // Delegation
            let imagePicker         = RAImagePickerController()
            imagePicker.delegate    = self
            imagePicker.dataSource  = self
            // Check Photos Library Authorization
            PHPhotoLibrary.requestAuthorization({ [unowned self] (_) in
                DispatchQueue.main.async {
                    if self.presentsModally {
                        imagePicker.layoutConfiguration.scrollDirection = .vertical
                        self.presentPickerModally(imagePicker)
                    }
                    else {
                        imagePicker.layoutConfiguration.scrollDirection = .horizontal
                        self.presentPickerAsInputView(imagePicker)
                    }
                }
            })
            // Show Default ImagePicker items ?
            imagePicker.layoutConfiguration.showsDefaultCameraItem  = true
            imagePicker.layoutConfiguration.showsDefaultGalleryItem = true
            // If you wich to use custom action layout
            let nib = UINib(nibName: "ActionItemCell", bundle: nil)
            imagePicker.cellRegistrator.register(nib: nib, forActionItemAt: 0)
            imagePicker.cellRegistrator.register(nib: nib, forActionItemAt: 1)

            // Show RAImagePicker Camera Item ?
            imagePicker.layoutConfiguration.showsCameraItem         = true
            // Camera Capture Mode
            imagePicker.captureSettings.cameraMode                  = .photoAndLivePhoto
            // Save Captured Photos ?
            imagePicker.captureSettings.savesCapturedPhotosToPhotoLibrary = savesCapturedAssets

            // MARK: RAImagePicker Assets Configuration
            
            // we can replace default cells with custom
            // Note: Custom cell must sublcass 'RAImagePickerAssetCell'
            switch assetsSource {
                case .gallery:
                    let nib = UINib(nibName: "GalleryViewCell", bundle: nil)
                    imagePicker.cellRegistrator.register(nib: nib, forAssetItemOf: .image)
                    imagePicker.assetsFetchResultBlock = {
                        guard let assetCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumGeneric, options: nil).firstObject else {
                            return nil
                        }
                        return PHAsset.fetchAssets(in: assetCollection, options: nil)
                    }
                    break
                case .selfies:
                    let nib = UINib(nibName: "SelfiesCellID", bundle: nil)
                    imagePicker.cellRegistrator.register(nib: nib, forAssetItemOf: .image)
                    imagePicker.assetsFetchResultBlock = {
                        guard let assetCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: nil).firstObject else {
                            return nil
                        }
                        return PHAsset.fetchAssets(in: assetCollection, options: nil)
                    }
                    break
                case .videos:
                    let nib = UINib(nibName: "VideoCellID", bundle: nil)
                    imagePicker.cellRegistrator.register(nib: nib, forAssetItemOf: .image)
                    imagePicker.assetsFetchResultBlock = {
                        guard let assetCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil).firstObject else {
                            return nil
                        }
                        return PHAsset.fetchAssets(in: assetCollection, options: nil)
                    }
                    break
                case ._default:
                    break
            }
            
            // we can replace default cells with custom
            // Note: Custom cell must sublcass 'RACameraCollectionViewCell'
            switch captureMode {
                case .photo:
                    imagePicker.captureSettings.cameraMode = .photo
                    let nib = UINib(nibName: "CapturePhotosCellID", bundle: nil)
                    imagePicker.cellRegistrator.registerNibForCameraItem(nib)
                break
                case .photoAndLivePhoto:
                break
                case .photoAndVideo:
                    imagePicker.captureSettings.cameraMode = .photoAndVideo
                    let nib = UINib(nibName: "CapturePhotosVideosCellID", bundle: nil)
                    imagePicker.cellRegistrator.registerNibForCameraItem(nib)
                break
                case .video:
                    imagePicker.captureSettings.cameraMode = .video
                    let nib = UINib(nibName: "CaptureVideosCellID", bundle: nil)
                    imagePicker.cellRegistrator.registerNibForCameraItem(nib)
                break
            }

        } else {
            updateSelectedItemsCount(count: 0)
            currentInputView = nil
            reloadInputViews()
        }
    }
    
    func presentPickerAsInputView(_ imageController: RAImagePickerController) {
        // .flexibleHeight to adopt keyboard height or Set an layout constraint height for specific height
        imageController.view.autoresizingMask = .flexibleHeight
        currentInputView = imageController.view
        reloadInputViews()
    }
    
    func presentPickerModally(_ imageController: RAImagePickerController) {
        let item = UIBarButtonItem(title: "Dismiss",
                                   style: .done,
                                   target: self,
                                   action: #selector(dismissPresentedImagePicker(sender:)))
        imageController.navigationItem.leftBarButtonItem = item
        let navigationController = UINavigationController(rootViewController: imageController)
        present(navigationController, animated: true, completion: nil)
    }
    
    @objc func dismissPresentedImagePicker(sender: UIBarButtonItem) {
        presentButton.isSelected = false
        updateSelectedItemsCount(count: 0)
        navigationController?.visibleViewController?.dismiss(animated: true, completion: nil)
    }
    
    func updateSelectedItemsCount(count: Int) {
        if count > 0 {
            let item = UIBarButtonItem(title: "Items (\(count))", style: .plain, target: nil, action: nil)
            navigationController?.visibleViewController?.navigationItem.setRightBarButton(item, animated: true)
        } else {
            navigationController?.visibleViewController?.navigationItem.setRightBarButton(nil, animated: true)
        }
    }
}

// MARK: - RAImagePicker Data Source
extension ViewController: RAImagePickerControllerDataSource {
    func imagePicker(controller: RAImagePickerController,
                     viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView
    {
        let info               = UILabel(frame: .zero)
        info.backgroundColor   = .red
        info.textAlignment     = .center
        info.numberOfLines     = 0
        switch status {
        case .restricted:
            info.text = NSLocalizedString("Access Restricted, Check Settings to Update Privacy Settings",
                                          comment: "Restricted Access")
        case .denied:
            info.text = NSLocalizedString("Access Denied, Check Settings to Update Privacy Settings",
                                          comment: "User Denied Access")
        default:
            break
        }
        return info
    }
}

// MARK: - RAImagePicker Delegate
extension ViewController : RAImagePickerControllerDelegate {
    
    public func imagePicker(controller: RAImagePickerController, didSelectActionItemAt index: Int) {
        
        print("Selected Action: \(index)")
        presentButton.isSelected = false
        let imagePicker = UIImagePickerController()
        switch index {
        case 0:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType      = .camera
                imagePicker.allowsEditing   = true
                if let media = UIImagePickerController.availableMediaTypes(for: .camera) {
                    imagePicker.mediaTypes = media
                }
                navigationController?.visibleViewController?.present(imagePicker, animated: true, completion: nil)
            }
            break
        case 1:
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                imagePicker.sourceType = .photoLibrary
                navigationController?.visibleViewController?.present(imagePicker, animated: true, completion: nil)
            }
            break
        default:
            break
        }
    }
    
    public func imagePicker(controller: RAImagePickerController, didSelect asset: PHAsset) {
        
        print("Selected Assets: \(controller.selectedAssets.count)")
        updateSelectedItemsCount(count: controller.selectedAssets.count)
    }
    
    public func imagePicker(controller: RAImagePickerController, didDeselect asset: PHAsset) {
        
        print("Selected Assets: \(controller.selectedAssets.count)")
        updateSelectedItemsCount(count: controller.selectedAssets.count)
    }
    
    public func imagePicker(controller: RAImagePickerController, didTake image: UIImage) {
        
        print("Toke Image: \(image)")
    }

    func imagePicker(controller: RAImagePickerController,
                     willDisplayActionItem cell: UICollectionViewCell,
                     at index: Int)
    {

        switch cell {
            case let cell as ActionItemCell:
                cell.title.textColor = .black
                switch index {
                    case 0:
                        cell.title.text = NSLocalizedString("Use Camera", comment: "Camera")
                        cell.icon.image = #imageLiteral(resourceName: "camera")
                    break
                    case 1:
                        cell.title.text = NSLocalizedString("Photos Gallery", comment: "Gallery")
                        cell.icon.image = #imageLiteral(resourceName: "gallery")
                    break
                    default:
                    break
                }
            default:
            break
        }
    }
    
    func imagePicker(controller: RAImagePickerController,
                     willDisplayAssetItem cell: RAImagePickerAssetCell,
                     asset: PHAsset)
    {
        switch cell {
        case let photosCell as GalleryViewCell:
            if asset.mediaSubtypes.contains(.photoLive) {
                photosCell.subtypeImageView.image = #imageLiteral(resourceName: "live")
            }
            else if asset.mediaSubtypes.contains(.photoPanorama) {
                photosCell.subtypeImageView.image = #imageLiteral(resourceName: "panorama")
            }
            else if #available(iOS 10.2, *), asset.mediaSubtypes.contains(.photoDepthEffect) {
                photosCell.subtypeImageView.image = #imageLiteral(resourceName: "depth")
            }
        case let videosCell as VideosViewCell:
            videosCell.label.text = ViewController.durationFormatter.string(from: asset.duration)
        default:
            break
        }
    }
}

extension ViewController {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        let responder = super.resignFirstResponder()
        if responder {
            currentInputView = nil
        }
        return responder
    }
    
    // Called and presented when object becomes first responder
    override var inputView: UIView? {
        return currentInputView
    }
    
    override var inputAccessoryView: UIView? {
        return presentButton
    }
    
    // Date Formatter Style
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}
