//
//  RAImagePickerDataSource.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import Foundation
import Photos


// Datasource for a collection view that is used by RAImagePickerViewController.

final class RAImagePickerDataSource : NSObject, UICollectionViewDataSource {
    
    var layoutModel = RALayoutModel.empty
    var cellRegistrator: RACellRegistrator?
    var assetsModel: RAImagePickerAssetModel
    
    init(assetsModel: RAImagePickerAssetModel) {
        self.assetsModel = assetsModel
        super.init()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return layoutModel.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return layoutModel.numberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cellsRegistrator = cellRegistrator else {
            fatalError("cells registrator must be set at this moment")
        }
        
        //TODO: change these hardcoded section numbers to those defined in layoutModel.layoutConfiguration
        switch indexPath.section {
        case 0:
            guard let id = cellsRegistrator.cellIdentifier(forActionItemAt: indexPath.row) else {
                fatalError("there is an action item at index \(indexPath.row) but no cell is registered.")
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
            
        case 1:
            let id = cellsRegistrator.cameraItemIdentifierPrefix
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? RACameraCollectionViewCell else {
                fatalError("there is a camera item but no cell class `CameraCollectionViewCell` is registered.")
            }
            return cell
            
        case 2:
            
            let asset = assetsModel.fetchResult.object(at: indexPath.item)
            let cellId = cellsRegistrator.cellIdentifier(forAsset: asset.mediaType) ?? cellsRegistrator.cellIdentifierForAssetItems
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? RAImagePickerAssetCell else {
                fatalError("asset item cell must conform to \(RAImagePickerAssetCell.self) protocol")
            }
            
            let thumbnailSize = assetsModel.thumbnailSize ?? .zero
            
            // Request an image for the asset from the PHCachingImageManager.
            cell.representedAssetIdentifier = asset.localIdentifier
            assetsModel.imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                // The cell may have been recycled by the time this handler gets called;
                // set the cell's thumbnail image only if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                    cell.imageView.image = image
                }
            })
            
            return cell as! UICollectionViewCell
            
        default: fatalError("only 3 sections are supported")
        }
    }
    
    
}
