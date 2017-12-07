# RAImagePicker

[![CI Status](http://img.shields.io/travis/rallahaseh/RAImagePicker.svg?style=flat)](https://travis-ci.org/rallahaseh/RAImagePicker)
[![Version](https://img.shields.io/cocoapods/v/RAImagePicker.svg?style=flat)](http://cocoapods.org/pods/RAImagePicker)
[![License](https://img.shields.io/cocoapods/l/RAImagePicker.svg?style=flat)](http://cocoapods.org/pods/RAImagePicker)
[![Platform](https://img.shields.io/cocoapods/p/RAImagePicker.svg?style=flat)](http://cocoapods.org/pods/RAImagePicker)

## Description

RAImagePicker is a protocol-oriented framework that provides custom features from the built-in Image Picker Edit.

<br>
<img src="https://media.giphy.com/media/3ohs7QgfzREzPpDsk0/giphy.gif"/>
<br>

## Overview

Object `RAImagePickerController` manages user interactions and delivers the results of those interactions to a delegate object.

**RAImagePickerController** depend on the configuration you set up before presenting it.

Functional Parts:
1. **Action Items(Default Asset.)** - Supports two actions, this section is optional and by default contains action item for camera and photos.
2. **Camera** - Camera's output(Capture Videos/Photos), this section is optinal and by default it's turned on.
3. **Asset.** - Thumbnails of assets found in gallery, this section is mandatory and and can not be turned off.

**Protocol**
Provide a delegate that conforms to `RAImagePickerControllerDelegate` protocol. Use delegate to get informed when user takes a picture or selects an asset from library and configure custom action and asset collection view cells.

## Usage

Follow the following steps to get started:
1. Add permissions to your `info.plist` file.
2. Create new instance of RAImagePickerController.
3. Present the controller
**Note:** You can configure the controller by set **Custom Cells**, change **Appearance and Layout** and the **Capture Mode**

## Features

- [x] Presentation Design Handeled for `.horizontal`(like iMessage) and `.vertical` Modes
- [x] Portrait and Landscape Supported
- [x] Support iPhone X
- [x] Support Live Photos
- [x] Flip Camera (Rear/Front)
- [x] Highly and Easly Customisable Layout

## Plist Privacy Permissions

In order to get access to the user Camera and Photos/Videos Gallery, you will need to add permissions to the `plist` file :
- Privacy - Camera Usage Description (Photos/Videos)
- Privacy - Photo Library Usage Description (Gallery)
- Privacy - Microphone Usage Description (Videos)

```xml
<key>NSCameraUsageDescription</key>
<string>Access Description</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Access Description</string>
<key>NSMicrophoneUsageDescription</key>
<string>Access Description</string>
```

## Capture Modes

Currently it supports capturing **Photos**, **Live Photos** and **Videos**.

To configure RAImagePicker to support desired media type use `captureSettings` struct. Use property `cameraMode` to specify what kind of output you are interested in.
- [x] photo [Support Photos Only (Default)]
- [x] video [Support Videos Only]
- [x] photoAndLivePhoto [Support Photos & Live Photos]
- [x] photoAndVideo [Support Videos & Photos]

<br>

**Example:**
```swift
let imagePicker = RAImagePickerController()
imagePicker.captureSettings.cameraMode = .photoAndLivePhoto
```

To save the captured photos to the gallery. Set the flag `savesCapturedPhotosToPhotoLibrary` to true.

<br>

**Example:**
```swift
let imagePicker = RAImagePickerController()
imagePicker.captureSettings.savesCapturedPhotosToPhotoLibrary = true
```

## Fetching

Default Image Picker fetches from Photo Library 1000 photos and videos from smart album `smartAlbumUserLibrary` that should represent **Camera Roll** album. If you wish to provide your own fetch result please implement image picker controller's `assetsFetchResultBlock` block.

For example the following code snippet can fetch only live photos:
```swift
let imagePicker = RAImagePickerController()
imagePicker.assetsFetchResultBlock = {
    guard let livePhotosCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumLivePhotos, options: nil).firstObject else {
        return nil //you can return nil if you did not find desired fetch result, default fetch result will be used.
    }
    return PHAsset.fetchAssets(in: livePhotosCollection, options: nil)
}
```
Reference [Photos Framework](https://developer.apple.com/documentation/photos).

## Customization

<br>
<img src="https://media.giphy.com/media/3oxHQoBwQwoETbaxZS/giphy.gif"/>
<br>

**Action Cells**
1. Set Layout Configuration
```swift
let imagePicker = RAImagePickerController()
imagePicker.layoutConfiguration.showsDefaultCameraItem  = true
imagePicker.layoutConfiguration.showsDefaultGalleryItem = true
```

2. Register Action Cells
Now there's multiple ways to register your custom cells
- [x] Using nib 
```swift 
imagePicker.registerNibForActionItems(CustomNib) 
```
- [x] Using class 
```swift 
imagePicker.registerCellClassForActionItems(CustomCell) 
```
- [x] For specific item(nib) 
```swift 
imagePicker.cellRegistrator.register(nib: CustomNib, forActionItemAt: 0) 
```
- [x] For specific item(class) 
```swift 
imagePicker.cellRegistrator.register(nib: CustomCell, forActionItemAt: 0) 
```

3. Configure Delegate
```swift
func imagePicker(controller: RAImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {
    switch cell {
    case let customCell as CustomCell:
        switch index {
        case 0:
            customCell.title.text = "Title"
            customCell.icon.image = UIImage(named: "icon_name")
        case 1:
            customCell.title.text = "Title"
            customCell.icon.image = UIImage(named: "icon_name")
        default: break
        }
    default:
        break
    }
}
```

4. Handle Selected Assets
```swift
func imagePicker(controller: RAImagePickerController, didSelectActionItemAt index: Int) {
    print("Selected Asset. Index: \(index)")
}
```

**Appearance Cells**

1. Register Cell Classes
```swift
let imagePicker = RAImagePickerController()
imagePicker.register(cellClass: CustomImageCell.self, forAssetItemOf: .image)
imagePicker.register(cellClass: CustomVideoCell.self, forAssetItemOf: .video)
```
> Please note, that `RACellRegistrator` provides a method to register one cell or nib for any asset media type.

2. Configure Delegate
```swift
func imagePicker(controller: RAImagePickerController, willDisplayAssetItem cell: RAImagePickerAssetCell, asset: PHAsset) {
    switch cell {
    case let imageCell as CustomImageCell:
        if asset.mediaSubtypes.contains(.photoLive) {
            imageCell.subtypeImageView.image = UIImage(named: "icon_name")
        }
        else if asset.mediaSubtypes.contains(.photoPanorama) {
            imageCell.subtypeImageView.image = UIImage(named: "icon_name")
        }
        else if #available(iOS 10.2, *), asset.mediaSubtypes.contains(.photoDepthEffect) {
            imageCell.subtypeImageView.image = UIImage(named: "icon_name")
        }
        // etc ...
    case let videoCell as CustomVideoCell:
        videoCell.label.text = asset.duration
    default:
        break
    }
}
```

## Presentation

```swift
let imagePicker = RAImagePickerController()
navigationController.present(imagePicker, animated: true, completion: nil)
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## References

- [Photos Framework](https://developer.apple.com/documentation/photos)
- [devxoul - UIImage Category](https://github.com/devxoul/ImageEffects)

## Requirements

- Xcode +9.0
- iOS 10.0+
- Swift 4

## Installation

RAImagePicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RAImagePicker'
```

## Author

rallahaseh, rallahaseh@gmail.com

## License

RAImagePicker is available under the MIT license. See the LICENSE file for more info.
