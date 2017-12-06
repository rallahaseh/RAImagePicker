//
//  VideosViewCell.swift
//  RAImagePicker_Example
//
//  Created by Rashed Al Lahaseh on 12/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class VideosViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var representedAssetIdentifier: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
