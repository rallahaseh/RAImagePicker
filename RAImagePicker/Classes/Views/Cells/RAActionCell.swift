//
//  RAActionCell.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import UIKit
import Foundation


final class RAActionCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet var leadingOffset: NSLayoutConstraint!
    @IBOutlet var trailingOffset: NSLayoutConstraint!
    @IBOutlet var topOffset: NSLayoutConstraint!
    @IBOutlet var bottomOffset: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        imageView.backgroundColor = UIColor.clear
    }
}

extension RAActionCell {
    
    func updateCell(cameraText:String, cameraIconColor: UIColor,
                      galleryText: String, galleryIconColor: UIColor, index: Int)
    {
        titleLabel.textColor = .black
        switch index {
            case 0:
                titleLabel.text = cameraText
                imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = cameraIconColor
            break
            case 1:
                titleLabel.text = galleryText
                imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = galleryIconColor
            break
            default:
            break
        }
    }
    
    func update(withIndex index: Int, layoutConfiguration: RALayoutConfiguration) {
        
        // Layout
        let layoutModel = RALayoutModel(configuration: layoutConfiguration, assets: 0)
        let actionCount = layoutModel.numberOfItems(in: layoutConfiguration.sectionIndexForActions)
        
        titleLabel.textColor = .black
        switch index {
            case 0:
                titleLabel.text = "Camera"
                imageView.image = UIImage.fromWrappedBundleImage(#imageLiteral(resourceName: "icon-camera"))
                imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = .black
            break
            case 1:
                titleLabel.text = "Gallery"
                imageView.image = UIImage.fromWrappedBundleImage(#imageLiteral(resourceName: "icon-gallery"))
                imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = .black
            break
            default:
            break
        }
        
        let isFirst = index == 0
        let isLast = index == actionCount - 1
        
        switch layoutConfiguration.scrollDirection {
        case .horizontal:
            topOffset.constant = isFirst ? 10 : 5
            bottomOffset.constant = isLast ? 10 : 5
            leadingOffset.constant = 5
            trailingOffset.constant = 5
        case .vertical:
            topOffset.constant = 5
            bottomOffset.constant = 5
            leadingOffset.constant = isFirst ? 10 : 5
            trailingOffset.constant = isLast ? 10 : 5
        }
    }
}
