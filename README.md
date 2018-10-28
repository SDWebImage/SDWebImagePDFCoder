# SDWebImagePDFCoder

[![CI Status](https://img.shields.io/travis/SDWebImage/SDWebImagePDFCoder.PDF?style=flat)](https://travis-ci.org/SDWebImage/SDWebImagePDFCoder)
[![Version](https://img.shields.io/cocoapods/v/SDWebImagePDFCoder.PDF?style=flat)](https://cocoapods.org/pods/SDWebImagePDFCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImagePDFCoder.PDF?style=flat)](https://cocoapods.org/pods/SDWebImagePDFCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImagePDFCoder.PDF?style=flat)](https://cocoapods.org/pods/SDWebImagePDFCoder)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.PDF?style=flat)](https://github.com/SDWebImage/SDWebImagePDFCoder)

## What's for
SDWebImagePDFCoder is a PDF coder plugin for [SDWebImage](https://github.com/rs/SDWebImage/) framework, which provide the image loading support for [PDF](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics). The PDF rendering is done using Apple's built-in framework (UIKit/AppKit/Core Graphics).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

You can modify the code or use some other PDF files to check the compatibility.

## Requirements

+ iOS 8
+ tvOS 9
+ macOS 10.10

## Installation

#### CocoaPods

SDWebImagePDFCoder is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SDWebImagePDFCoder'
```

#### Carthage

SDWebImagePDFCoder is available through [Carthage](https://github.com/Carthage/Carthage).

Note that because the dependency SDWebImage currently is in beta. You should use `Carthage v0.30.1` or above to support beta [sem-version](https://semver.org/).

```
github "SDWebImage/SDWebImagePDFCoder"
```

## Usage

To use PDF coder, you should firstly add the `SDImagePDFCoder` to the coders manager. Then you can call the View Category method to start load PDF images.

### Use UIImageView vector rendering (iOS/tvOS 11+, Mac)

**Important**: Apple add the built-in vector image support for PDF format  for UIKit from iOS/tvOS 11+. Which means you can create a `UIImage` with PDF data, and set it on the `UIImageView`. When the imageView bounds/contentMode changed, the PDF image also get scaled without losing any detail. You can also use `+[UIImage imageNamed:]` with Xcode Asset Catalog for PDF image, remember to turn on `Preserve Vector Data`.

For macOS user, `NSImage`/`NSImageView` support PDF image from the day one. Use it as usual.

+ Objective-C

```objectivec
SDImagePDFCoder *PDFCoder = [SDImagePDFCoder sharedCoder];
[[SDImageCodersManager sharedManager] addCoder:PDFCoder];
UIImageView *imageView;
[imageView sd_setImageWithURL:url];
```

+ Swift

```swift
let PDFCoder = SDImagePDFCoder.shared
SDImageCodersManager.shared.addCoder(PDFCoder)
let imageView: UIImageView
imageView.sd_setImage(with: url)
```

### Use UIImageView bitmap rendering (iOS/tvOS 10-)

For firmware which is below iOS/tvOS 11+, `UIImage` && `UIImageView` does not support vector image rendering. Even you can add PDF image in Xcode Asset Catalog, it was encoded to bitmap PNG format when compiled but not support runtime scale. 

For `UIImageView`, we will only parse PDF with a fixed image size (from the PDF cropBox information). But we also support you to specify a desired size during image loading using `PDFImageSize` context option. And you can specify whether to keep aspect ratio using `PDFImagePreserveAspectRatio` context option.

+ Objective-C

```objectivec
SDImagePDFCoder *PDFCoder = [SDImagePDFCoder sharedCoder];
[[SDImageCodersManager sharedManager] addCoder:PDFCoder];
UIImageView *imageView;
CGSize PDFImageSize = CGSizeMake(500, 500);
[imageView sd_setImageWithURL:url placeholderImage:nil options:0 context:@{SDWebImageContextPDFImageSize : @(PDFImageSize)];
```

+ Swift

```swift
let PDFCoder = SDImagePDFCoder.shared
SDImageCodersManager.shared.addCoder(PDFCoder)
let imageView: UIImageView
let PDFImageSize = CGSize(width: 500, height: 500)
imageView.sd_setImage(with: url, placeholderImage: nil, options: [], context: [.pdfImageSize : PDFImageSize])
```

## Screenshot

<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImagePDFCoder/master/Example/Screenshot/PDFDemo.png" width="300" />

## Author

DreamPiggy

## License

SDWebImagePDFCoder is available under the MIT license. See the LICENSE file for more info.


