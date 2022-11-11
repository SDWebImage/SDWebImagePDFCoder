//
//  SDWebImagePDFCoderDefine.h
//  SDWebImagePDFCoder
//
//  Created by lizhuoli on 2018/10/28.
//

#if __has_include(<SDWebImage/SDWebImage.h>)
#import <SDWebImage/SDWebImage.h>
#else
@import SDWebImage;
#endif

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Coder Options
/**
 A unsigned interger raw value which specify the desired PDF image page number. Because PDF can contains mutiple pages. The page number index is started with 0. (NSNumber)
 If you don't provide this value, use 0 (the first page) instead.
 @note works for `SDImageCoder`
 */
FOUNDATION_EXPORT SDImageCoderOption _Nonnull const SDImageCoderDecodePDFPageNumber;

/**
 `SDImageCoderDecodeThumnailPixelSize`: See more in SDWebImage. Pass `.zero` means Bitmap PDF of MediaBox size, pass nil to prefer vector image. Defaults to nil.
 `SDImageCoderDecodePreserveAspectRatio`: See more in SDWebImage. Defaults to YES.
 */

NS_ASSUME_NONNULL_END
