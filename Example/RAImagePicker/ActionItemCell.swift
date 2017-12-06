//
//  ActionItemCell.swift
//  RAImagePicker_Example
//
//  Created by Rashed Al Lahaseh on 12/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class ActionItemCell: UICollectionViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var topOffset: NSLayoutConstraint!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!

    private var originalBC: UIColor?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        originalBC              = backgroundColor
        icon.backgroundColor    = UIColor.clear
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UIColor.red
            }
            else {
                backgroundColor = originalBC
            }
        }
    }
}
