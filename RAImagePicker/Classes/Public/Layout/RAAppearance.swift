//
//  RAAppearance.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import UIKit
import AVFoundation

// Provides access to styling attributes of ImagePicker

public class RAAppearance {
    
    // ImagePicker background color
    public var backgroundColor: UIColor     = UIColor(red: 208/255, green: 213/255, blue: 218/255, alpha: 1)
}

extension UIInterfaceOrientation {
    
    var captureVideoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait, .unknown: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        }
    }
}
extension UIInterfaceOrientation : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portrait upside down"
        case .landscapeRight: return "landscape right"
        case .landscapeLeft: return "landscape left"
        }
    }
}

extension UICollectionView {
    
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        let paths = allLayoutAttributes.map { $0.indexPath }
        return paths
    }
}

// MARK: - Functions
func differencesBetweenRects(_ old: CGRect, _ new: CGRect, _ scrollDirection: UICollectionViewScrollDirection) -> (added: [CGRect], removed: [CGRect]) {
    switch scrollDirection {
    case .horizontal: return differencesBetweenRectsHorizontal(old, new)
    case .vertical: return differencesBetweenRectsVertical(old, new)
    }
}

func differencesBetweenRectsVertical(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
    if old.intersects(new) {
        var added = [CGRect]()
        if new.maxY > old.maxY {
            added += [CGRect(x: new.origin.x, y: old.maxY, width: new.width, height: new.maxY - old.maxY)]
        }
        if old.minY > new.minY {
            added += [CGRect(x: new.origin.x, y: new.minY, width: new.width, height: old.minY - new.minY)]
        }
        var removed = [CGRect]()
        if new.maxY < old.maxY {
            removed += [CGRect(x: new.origin.x, y: new.maxY, width: new.width, height: old.maxY - new.maxY)]
        }
        if old.minY < new.minY {
            removed += [CGRect(x: new.origin.x, y: old.minY, width: new.width, height: new.minY - old.minY)]
        }
        return (added, removed)
    }
    else {
        return ([new], [old])
    }
}

func differencesBetweenRectsHorizontal(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
    if old.intersects(new) {
        var added = [CGRect]()
        if new.maxX > old.maxX {
            added += [CGRect(x: old.maxX, y: old.origin.y, width: new.maxX - old.maxX, height: old.height)]
        }
        if old.minX > new.minX {
            added += [CGRect(x: new.minX, y: old.origin.y, width: old.maxX - new.maxX, height: old.height)]
        }
        var removed = [CGRect]()
        if new.maxX < old.maxX {
            removed += [CGRect(x: new.maxX, y: old.origin.y, width: old.maxX - new.maxX, height: old.height)]
        }
        if old.minX < new.minX {
            removed += [CGRect(x: old.minX, y: old.origin.y, width: new.maxX - old.maxX, height: old.height)]
        }
        return (added, removed)
    }
    else {
        return ([new], [old])
    }
}

extension UIImage {
    static func fromWrappedBundleImage(_ wrappedImage: WrappedBundleImage) -> UIImage {
        return wrappedImage.image
    }
}
struct WrappedBundleImage: _ExpressibleByImageLiteral {
    let image: UIImage
    
    init(imageLiteralResourceName name: String) {
        let bundle = Bundle(for: RAActionCell.self)
        image = UIImage(named: name, in: bundle, compatibleWith: nil)!
    }
}

