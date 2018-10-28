//
//  SDWebImagePDFCoderDefine.h
//  SDWebImagePDFCoder
//
//  Created by lizhuoli on 2018/10/28.
//

#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A unsigned interger raw value which specify the desired PDF image page number. Because PDF can contains mutiple pages. Attention the page number index is started with 1. (NSNumber)
 If you don't provide this value, or the value is out of [1,MAX], use 1 (the first page) instead.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextPDFPageNumber;

/**
 A CGSize raw value which specify the desired PDF image size during image loading. Because vector image like PDF format, may not contains a fixed size, or you want to get a larger size bitmap representation UIImage. (NSValue)
 If you don't provide this value, use the PDF cropBox size instead.
 @note For iOS/tvOS 11+, you don't need this option and it will be ignored. Because UIImage support built-in vector rendering and scaling for PDF. Changing imageView's contentMode and bounds instead.
 @note For macOS user. Changing imageViews' imageScaling and bounds instead.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextPDFImageSize;

/**
 A BOOL value which specify the whether PDF image should keep aspect ratio during image loading. Because when you specify image size via `SDWebImageContextPDFImageSize`, we need to know whether to keep aspect ratio or not when image size is not equal to PDF cropBox size. (NSNumber)
 If you don't provide this value, use YES for default value.
 @note For iOS/tvOS 11+, you don't need this option and it will be ignored. Because UIImage support built-in vector rendering and scaling for PDF. Changing imageView's contentMode and bounds instead.
 @note For macOS user. Changing imageViews' imageScaling and bounds instead.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextPDFImagePreserveAspectRatio;

NS_ASSUME_NONNULL_END
