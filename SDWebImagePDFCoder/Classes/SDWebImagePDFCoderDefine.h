//
//  SDWebImagePDFCoderDefine.h
//  SDWebImagePDFCoder
//
//  Created by lizhuoli on 2018/10/28.
//

@import SDWebImage;

NS_ASSUME_NONNULL_BEGIN

/**
 A unsigned interger raw value which specify the desired PDF image page number. Because PDF can contains mutiple pages. The page number index is started with 0. (NSNumber)
 If you don't provide this value, use 0 (the first page) instead.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextPDFPageNumber;

/**
 A BOOL value which specify whether we prefer the actual bitmap representation instead of vector representation for PDF image. This is because the UIImage on iOS 11+ (NSImgae on macOS) can use the vector image format, which support dynamic scale without losing any detail. However, for some image processing logic, user may need the actual bitmap representation to manage pixels. Also, for lower firmware on iOS, the `UIImage` does not support vector rendering, user may want to handle them using the same code. (NSNumber)
 If you don't provide this value, use NO for default value and prefer the vector format when possible.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextPDFPrefersBitmap;

#pragma mark - Bitmap Representation Options
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
