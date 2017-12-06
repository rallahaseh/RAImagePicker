//
//  ImagePickerSelectionPolicy.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import Foundation

/*
    Determines which cells are selected, multiple selected or highlighted. Allow selecting only asset items, action items are only highlighted, camera item is untouched.
 */
struct RAImagePickerSelectionPolicy {
    
    func shouldSelectItem(atSection section: Int, layoutConfiguration: RALayoutConfiguration) -> Bool {
        switch section {
        case layoutConfiguration.sectionIndexForActions, layoutConfiguration.sectionIndexForCamera:
            return false
        default:
            return true
        }
    }
    
    func shouldHighlightItem(atSection section: Int, layoutConfiguration: RALayoutConfiguration) -> Bool {
        switch section {
        case layoutConfiguration.sectionIndexForCamera:
            return false
        default:
            return true
        }
    }
    
}
