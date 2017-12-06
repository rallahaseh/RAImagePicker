//
//  GalleryViewCell.swift
//  RAImagePicker_Example
//
//  Created by Rashed Al Lahaseh on 12/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import RAImagePicker

class GalleryViewCell: UICollectionViewCell, RAImagePickerAssetCell {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var subtypeImageView: UIImageView!
    @IBOutlet weak var selectedView: UIView!

    var representedAssetIdentifier: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        subtypeImageView.backgroundColor = UIColor.clear
        selectedView.isHidden = !isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Initialization code
        
        imageView.image = nil
        subtypeImageView.image = nil
    }
    
    override var isSelected: Bool {
        didSet {
            selectedView.isHidden = !isSelected
        }
    }
}
