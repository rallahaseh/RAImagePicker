//
//  RACellRegistrator.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import UIKit
import Foundation
import Photos


/*
    Register custom cell Classes/Xibs for each item type eaisly.
    Provided item types :
        1. action item, register a cell for all items or different cell for each index.
        2. asset item, register a cell for each asset type (video, image).
        3. camera item, register a subclass of the default CollectionViewCell to provide a custom cell implementation.
 */

public final class RACellRegistrator {
    
    // MARK: - Private Methods
    
    /*
        Cells
     */
    // Unique identifier
    fileprivate let actionItemIdentifierPrefix = "action-item.cell-id"
    // (UINib, String) => cell xib + identifier
    fileprivate var actionItemNibsData: [Int: (UINib, String)]?
    // (UICollectionViewCell.Type, String) => cell class type + identifier
    fileprivate var actionItemClassesData: [Int: (UICollectionViewCell.Type, String)]?
    
    /*
        Assets [Image || Video]
    */
    // Unique identifier
    fileprivate let assetItemIdentifierPrefix = "asset-item.cell-id"
    // (UINib, String) => cell xib + identifier
    fileprivate var assetItemNibsData: [PHAssetMediaType: (UINib, String)]?
    // (UICollectionViewCell.Type, String) => cell class type + identifier
    fileprivate var assetItemClassesData: [PHAssetMediaType: (UICollectionViewCell.Type, String)]?
    
    /*
        Camera xib with type only since it has one cell no need for identifiers
     */
    fileprivate var cameraItemNib: UINib?
    fileprivate var cameraItemClass: UICollectionViewCell.Type?
    
    /*
        Default, if the assets type is not specified it sets to all types [Image && Video]
     */
    fileprivate var assetItemNib: UINib?
    fileprivate var assetItemClass: UICollectionViewCell.Type?
    
    // MARK: - Internal Methods
    
    let cameraItemIdentifierPrefix = "camera-item.cell-id"
    
    // Returns registered cell identifier if found
    func cellIdentifier(forActionItemAt index: Int) -> String? {
        
        // Check if there is a registered cell for the specified index
        if let index = actionItemNibsData?[index]?.1 ?? actionItemClassesData?[index]?.1 {
            return index
        }
        // Check if there is a globally registered cell for all indices
        guard index < Int.max else {
            return nil
        }
        return cellIdentifier(forActionItemAt: Int.max)
    }
    
    // Check if there is any registered action cell
    var hasUserRegisteredActionCell: Bool {
        return (actionItemNibsData?.count ?? 0) > 0 || (actionItemClassesData?.count ?? 0) > 0
    }
    
    // Return asset cell identifier
    var cellIdentifierForAssetItems: String {
        return assetItemIdentifierPrefix
    }
    
    // Return asset cell identifier depending on asset type
    func cellIdentifier(forAsset type: PHAssetMediaType) -> String? {
        return assetItemNibsData?[type]?.1 ?? assetItemClassesData?[type]?.1
    }

    // MARK: - Public Methods
    
    /*
        Register a cell Xib/Class/Camera-Asset/Asset-Items for an action item at particular index.
            - Use this method if you wish to use different cells at each index.
     */
    // Xib
    public func register(nib: UINib, forActionItemAt index: Int) {
        if actionItemNibsData == nil {
            actionItemNibsData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemNibsData?[index] = (nib, cellIdentifier)
    }
    // Class
    public func register(cellClass: UICollectionViewCell.Type, forActionItemAt index: Int) {
        if actionItemClassesData == nil {
            actionItemClassesData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemClassesData?[index] = (cellClass, cellIdentifier)
    }
    // Camera
    /*public func registerCellClassForCameraItem(_ cellClass: CameraCollectionViewCell.Type) {
     cameraItemClass = cellClass
     }
     */
    // Assets
    // Note: must register cells for media types thats supported in the app only, or error exception will be thrown.
    public func register(nib: UINib, forAssetItemOf type: PHAssetMediaType) {
        if assetItemNibsData == nil {
            assetItemNibsData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type.rawValue)
        assetItemNibsData?[type] = (nib, cellIdentifier)
    }
    
    // Register a cell nib for all action items. [All action items have the same cell xib]
    public func registerNibForActionItems(_ nib: UINib) {
        register(nib: nib, forActionItemAt: Int.max)
    }
    // Register a cell class for all action items. [All action items have the same cell class]
    public func registerCellClassForActionItems(_ cellClass: UICollectionViewCell.Type) {
        register(cellClass: cellClass, forActionItemAt: Int.max)
    }
    // Register a cell nib for camera item. [Cell class must be a subclass of of the default CollectionViewCell]
    public func registerNibForCameraItem(_ nib: UINib) {
        cameraItemNib = nib
    }

    // Register a cell calss for all asset items types [Image && Video].
    public func registerCellClassForAssetItems<T: UICollectionViewCell>(_ cellClass: T.Type) where T: RAImagePickerAssetCell {
        assetItemClass = cellClass
    }
    // Register a cell xib for all asset items types [Image && Video].
    // Note: Please note that cell's class must conform to `ImagePickerAssetCell` protocol, otherwise an exception will be thrown.
    public func registerNibForAssetItems(_ nib: UINib) {
        assetItemNib = nib
    }

    // Register a cell calss for asset items of specific type [Image || Video].
    // Note: must register cells for media types thats supported in the app only, or error exception will be thrown.
    public func register<T: UICollectionViewCell>(cellClass: T.Type, forAssetItemOf type: PHAssetMediaType) where T: RAImagePickerAssetCell {
        if assetItemClassesData == nil {
            assetItemClassesData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type.rawValue)
        assetItemClassesData?[type] = (cellClass, cellIdentifier)
    }
}


extension UICollectionView {
    
    /*
        DataSource use it when registering cells to the UICollectionView, so if we do not register custom cells this method will be the default.
     */
    func apply(registrator: RACellRegistrator, cameraMode: RACaptureSettings.CameraMode) {
        
        // Register Action Items Considering Type
        // Note: dedault case if did not register Xib or Cell is RAActionCell
        if registrator.hasUserRegisteredActionCell == false {
            registrator.registerCellClassForActionItems(RAActionCell.self)
            guard let identifier = registrator.cellIdentifier(forActionItemAt: Int.max) else {
                fatalError("Image Picker: unable to register default action item cell")
            }
            let nib = UINib(nibName: "RAActionCell", bundle: Bundle(for: RAActionCell.self))
            register(nib, forCellWithReuseIdentifier: identifier)
        }
        else {
            register(nibsData: registrator.actionItemNibsData?.map { $1 })
            register(classData: registrator.actionItemClassesData?.map { $1 })
        }
        
        // Camera Item
        switch (registrator.cameraItemNib, registrator.cameraItemClass) {
        case (nil, nil):
            // Use default cells since no custom xib/classes registered
            switch cameraMode {
                case .photo, .photoAndLivePhoto:
                    let nib = UINib(nibName: "RALivePhotoCameraCell", bundle: Bundle(for: RALivePhotoCameraCell.self))
                    register(nib, forCellWithReuseIdentifier: registrator.cameraItemIdentifierPrefix)
            case .photoAndVideo, .video:
                let nib = UINib(nibName: "RAVideoCameraCell", bundle: Bundle(for: RAVideoCameraCell.self))
                register(nib, forCellWithReuseIdentifier: registrator.cameraItemIdentifierPrefix)
            }
        case (let nib, nil):
            register(nib, forCellWithReuseIdentifier: registrator.cameraItemIdentifierPrefix)
            
        case (_, let cellClass):
            register(cellClass, forCellWithReuseIdentifier: registrator.cameraItemIdentifierPrefix)
        }
        
        // Register Asset Items Considering Types
        register(nibsData: registrator.assetItemNibsData?.map { $1 })
        register(classData: registrator.assetItemClassesData?.map { $1 })
        
        // Register Asset Items Regardless of Specified Type
        switch (registrator.assetItemNib, registrator.assetItemClass) {
            case (nil, nil):
                // If did not register all required Xibs/Classes | Register Default Cells
                register(VideoAssetCell.self, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
            case (let nib, nil):
                register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
            case (_, let cellClass):
                register(cellClass, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
        }
    }
    
    // Registers UICollectionView through Xib/cell_id
    fileprivate func register(nibsData: [(UINib, String)]?) {
        guard let nibsData = nibsData else { return }
        for (nib, cellIdentifier) in nibsData {
            register(nib, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    // Registers UICollectionView through types/cell_id
    fileprivate func register(classData: [(UICollectionViewCell.Type, String)]?) {
        guard let classData = classData else { return }
        for (cellType, cellIdentifier) in classData {
            register(cellType, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    
}
