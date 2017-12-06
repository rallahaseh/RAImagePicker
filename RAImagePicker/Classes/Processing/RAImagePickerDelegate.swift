//
//  RAImagePickerDelegate.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import Foundation

protocol ImagePickerDelegate : class {
    
    // Selects one of action items
    func imagePicker(delegate: RAImagePickerDelegate, didSelectActionItemAt index: Int)
    
    // Selects one of asset items
    func imagePicker(delegate: RAImagePickerDelegate, didSelectAssetItemAt index: Int)
    
    // Deselects one of selected asset items
    func imagePicker(delegate: RAImagePickerDelegate, didDeselectAssetItemAt index: Int)
    
    // Action item is about to be displayed
    func imagePicker(delegate: RAImagePickerDelegate, willDisplayActionCell cell: UICollectionViewCell, at index: Int)
    
    // Camera item is about to be displayed
    func imagePicker(delegate: RAImagePickerDelegate, willDisplayCameraCell cell: RACameraCollectionViewCell)
    
    // Camera item ended displaying
    func imagePicker(delegate: RAImagePickerDelegate, didEndDisplayingCameraCell cell: RACameraCollectionViewCell)
    
    func imagePicker(delegate: RAImagePickerDelegate, willDisplayAssetCell cell: RAImagePickerAssetCell, at index: Int)
    
    func imagePicker(delegate: RAImagePickerDelegate, didScroll scrollView: UIScrollView)
}

final class RAImagePickerDelegate : NSObject, UICollectionViewDelegateFlowLayout {
    
    var layout: RAImagePickerLayout?
    weak var delegate: ImagePickerDelegate?
    
    private let selectionPolicy = RAImagePickerSelectionPolicy()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layout?.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return layout?.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == layout?.configuration.sectionIndexForAssets {
            delegate?.imagePicker(delegate: self, didSelectAssetItemAt: indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if indexPath.section == layout?.configuration.sectionIndexForAssets {
            delegate?.imagePicker(delegate: self, didDeselectAssetItemAt: indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let configuration = layout?.configuration else { return false }
        return selectionPolicy.shouldSelectItem(atSection: indexPath.section, layoutConfiguration: configuration)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let configuration = layout?.configuration else { return false }
        return selectionPolicy.shouldHighlightItem(atSection: indexPath.section, layoutConfiguration: configuration)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if indexPath.section == layout?.configuration.sectionIndexForActions {
            delegate?.imagePicker(delegate: self, didSelectActionItemAt: indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let configuration = layout?.configuration else { return }
        
        switch indexPath.section {
        case configuration.sectionIndexForActions: delegate?.imagePicker(delegate: self, willDisplayActionCell: cell, at: indexPath.row)
        case configuration.sectionIndexForCamera: delegate?.imagePicker(delegate: self, willDisplayCameraCell: cell as! RACameraCollectionViewCell)
        case configuration.sectionIndexForAssets: delegate?.imagePicker(delegate: self, willDisplayAssetCell: cell as! RAImagePickerAssetCell, at: indexPath.row)
        default: fatalError("index path not supported")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let configuration = layout?.configuration else { return }
        
        switch indexPath.section {
        case configuration.sectionIndexForCamera: delegate?.imagePicker(delegate: self, didEndDisplayingCameraCell: cell as! RACameraCollectionViewCell)
        case configuration.sectionIndexForActions, configuration.sectionIndexForAssets: break
        default: fatalError("index path not supported")
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.imagePicker(delegate: self, didScroll: scrollView)
    }
    
    @available(iOS 11.0, *)
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        print("XXX: \(scrollView.adjustedContentInset)")
    }
    
}
