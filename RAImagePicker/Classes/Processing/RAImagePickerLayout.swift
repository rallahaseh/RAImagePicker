//
//  RAImagePickerLayout.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 12/1/17.
//

import UIKit

/*
    Helper class that contains logic doing layout of collection view cells. UICollectionViewFlowLayout Workaround
*/

final class RAImagePickerLayout {
    
    var configuration: RALayoutConfiguration
    
    init(configuration: RALayoutConfiguration) {
        self.configuration = configuration
    }
    
    /*
        Returns the size for item considering the number of rows and scroll direction.
        if preferredWidthOrHeight == nil, then square size is returned
     */
    func sizeForItem(numberOfItemsInRow: Int, preferredWidthOrHeight: CGFloat?, collectionView: UICollectionView, scrollDirection: UICollectionViewScrollDirection) -> CGSize {
        
        switch scrollDirection {
        case .horizontal:
            var itemHeight = collectionView.frame.height
            itemHeight -= (collectionView.contentInset.top + collectionView.contentInset.bottom)
            itemHeight -= (CGFloat(numberOfItemsInRow) - 1) * configuration.interitemSpacing
            itemHeight /= CGFloat(numberOfItemsInRow)
            return CGSize(width: preferredWidthOrHeight ?? itemHeight, height: itemHeight)
            
        case .vertical:
            var itemWidth = collectionView.frame.width
            itemWidth -= (collectionView.contentInset.left + collectionView.contentInset.right)
            itemWidth -= (CGFloat(numberOfItemsInRow) - 1) * configuration.interitemSpacing
            itemWidth /= CGFloat(numberOfItemsInRow)
            return CGSize(width: itemWidth, height: preferredWidthOrHeight ?? itemWidth)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            fatalError("currently only UICollectionViewFlowLayout is supported")
        }
        
        let layoutModel = RALayoutModel(configuration: configuration, assets: 0)
        
        switch indexPath.section {
        case configuration.sectionIndexForActions:
            /*
                This will make sure that action item is either square if there are 2 items or rectangle if there is only 1 item
             */
            //let width = sizeForItem(numberOfItemsInRow: 2, preferredWidthOrHeight: nil, collectionView: collectionView, scrollDirection: layout.scrollDirection).width
            let ratio: CGFloat = 0.25
            let width = collectionView.frame.width * ratio
            return sizeForItem(numberOfItemsInRow: layoutModel.numberOfItems(in: configuration.sectionIndexForActions), preferredWidthOrHeight: width, collectionView: collectionView, scrollDirection: layout.scrollDirection)
            
        case configuration.sectionIndexForCamera:
            //lets keep this ratio so camera item is a nice rectangle
            
            let traitCollection = collectionView.traitCollection
            
            var ratio: CGFloat = 160/212
            
            // For landscape we need different ratio
            switch traitCollection.userInterfaceIdiom {
            case .phone:
                switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
                // Sizes for iPhone Landscape
                case (.unspecified, .compact):
                    fallthrough
                // Sizes for iPhone+ Landscape
                case (.regular, .compact):
                    fallthrough
                // Sizes for iPhones in Landscape except iPhone+
                case (.compact, .compact):
                    ratio = 1/ratio
                default: break
                }
                
            default:
                break
            }
            
            let widthOrHeight: CGFloat = collectionView.frame.height * ratio
            return sizeForItem(numberOfItemsInRow: layoutModel.numberOfItems(in: configuration.sectionIndexForCamera), preferredWidthOrHeight: widthOrHeight, collectionView: collectionView, scrollDirection: layout.scrollDirection)
            
        case configuration.sectionIndexForAssets:
            // Make sure there is at least 1 item, othewise invalid layout
            assert(configuration.numberOfAssetItemsInRow > 0, "invalid layout - numberOfAssetItemsInRow must be > 0, check your layout configuration ")
            return sizeForItem(numberOfItemsInRow: configuration.numberOfAssetItemsInRow, preferredWidthOrHeight: nil, collectionView: collectionView, scrollDirection: layout.scrollDirection)
            
        default:
            fatalError("unexpected sections count")
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            fatalError("currently only UICollectionViewFlowLayout is supported")
        }
        
        /// helper method that creates edge insets considering scroll direction
        func sectionInsets(_ inset: CGFloat) -> UIEdgeInsets {
            switch layout.scrollDirection {
            case .horizontal: return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: inset)
            case .vertical: return UIEdgeInsets(top: 0, left: 0, bottom: inset, right: 0)
            }
        }
        
        let layoutModel = RALayoutModel(configuration: configuration, assets: 0)
        
        switch section {
        case 0 where layoutModel.numberOfItems(in: section) > 0:
            return sectionInsets(configuration.actionSectionSpacing)
        case 1 where layoutModel.numberOfItems(in: section) > 0:
            return sectionInsets(configuration.cameraSectionSpacing)
        default:
            return .zero
        }
    }
    
}

