//
//  RALayoutConfiguration.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import Foundation


// Helper struct thats used with the ImagePickerLayout when configuring and laying out CollectionView items.
public struct RALayoutConfiguration {
    
    public var showsDefaultCameraItem       = true
    public var showsDefaultGalleryItem      = true
    public var showsCameraItem              = true
    
    let showsAssetItems                     = true
    
    // Scroll and Layout Direction
    public var scrollDirection: UICollectionViewScrollDirection = .horizontal
    
    // Define the number of image assets will be in a row
    public var numberOfAssetItemsInRow: Int = 2
    
    // Space between items within a section
    public var interitemSpacing: CGFloat = 1
    
    // Spacing between actions section and camera section
    public var actionSectionSpacing: CGFloat = 1
    
    // Spacing between camera section and assets section
    public var cameraSectionSpacing: CGFloat = 10
}

extension RALayoutConfiguration {
    
    var hasAnyAction: Bool {
        return showsDefaultCameraItem || showsDefaultGalleryItem
    }
    var sectionIndexForActions: Int {
        return 0
    }
    var sectionIndexForCamera: Int {
        return 1
    }
    var sectionIndexForAssets: Int {
        return 2
    }
    
    public static var `default` = RALayoutConfiguration()
}

extension UICollectionView {
    
    // Method for convenienet access to camera cell
    func cameraCell(layout: RALayoutConfiguration) -> RACameraCollectionViewCell? {
        return cellForItem(at: IndexPath(row: 0, section: layout.sectionIndexForCamera)) as? RACameraCollectionViewCell
    }
}
