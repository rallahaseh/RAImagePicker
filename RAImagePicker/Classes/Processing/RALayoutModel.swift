//
//  RALayoutModel.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import UIKit

/*
    A model that contains info that is used by layout code and collection view data source when figuring out layout structure.
    Contains three sections:
        1. for actions (supports up to 2 action items).
        2. for camera (1 camera item).
        3. for image assets (any number of image asset items).
 
    Note: Each section can be empty.
 */

struct RALayoutModel {
    
    private var sections: [Int] = [0, 0, 0]
    
    init(configuration: RALayoutConfiguration, assets: Int) {
        var actionItems: Int = configuration.showsDefaultCameraItem ? 1 : 0
        actionItems += configuration.showsDefaultGalleryItem ? 1 : 0
        sections[configuration.sectionIndexForActions] = actionItems
        sections[configuration.sectionIndexForCamera] = configuration.showsCameraItem ? 1 : 0
        sections[configuration.sectionIndexForAssets] = assets
    }
    
    var numberOfSections: Int {
        return sections.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        return sections[section]
    }
    
    static var empty: RALayoutModel {
        let emptyConfiguration = RALayoutConfiguration(showsDefaultCameraItem: false, showsDefaultGalleryItem: false, showsCameraItem: false, scrollDirection: .horizontal, numberOfAssetItemsInRow: 0, interitemSpacing: 0, actionSectionSpacing: 0, cameraSectionSpacing: 0)
        return RALayoutModel(configuration: emptyConfiguration, assets: 0)
    }
}
