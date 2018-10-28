//
//  SDImagePDFCoder.m
//  SDWebImagePDFCoder
//
//  Created by lizhuoli on 2018/10/28.
//

#import "SDImagePDFCoder.h"
#import "SDWebImagePDFCoderDefine.h"

#define SD_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))

// iOS/tvOS 11+ UIImage add built-in vector PDF image support. So we use that instead of drawing bitmap image
@interface UIImage (PrivatePDFSupport)

- (instancetype)_initWithCGPDFPage:(CGPDFPageRef)page;
- (instancetype)_initWithCGPDFPage:(CGPDFPageRef)page scale:(double)scale orientation:(UIImageOrientation)orientation;
+ (instancetype)_imageWithCGPDFPage:(CGPDFPageRef)page;
+ (instancetype)_imageWithCGPDFPage:(CGPDFPageRef)page scale:(double)scale orientation:(UIImageOrientation)orientation;

@end

@implementation SDImagePDFCoder

+ (SDImagePDFCoder *)sharedCoder {
    static dispatch_once_t onceToken;
    static SDImagePDFCoder *coder;
    dispatch_once(&onceToken, ^{
        coder = [[SDImagePDFCoder alloc] init];
    });
    return coder;
}

- (BOOL)canDecodeFromData:(NSData *)data {
    return [[self class] isPDFFormatForData:data];
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    
    NSUInteger pageNumber = 1;
    CGSize imageSize = CGSizeZero;
    BOOL preserveAspectRatio = YES;
    // Parse args
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextPDFPageNumber]) {
        NSUInteger rawPageNumber = [context[SDWebImageContextPDFPageNumber] unsignedIntegerValue];
        if (rawPageNumber == 0) {
            // start with 1 index
            rawPageNumber = 1;
        }
        pageNumber = rawPageNumber;
    }
    if (context[SDWebImageContextPDFImageSize]) {
        NSValue *sizeValue = context[SDWebImageContextPDFImageSize];
#if SD_UIKIT
        imageSize = sizeValue.CGSizeValue;
#else
        imageSize = sizeValue.sizeValue;
#endif
    }
    if (context[SDWebImageContextPDFImagePreserveAspectRatio]) {
        preserveAspectRatio = [context[SDWebImageContextPDFImagePreserveAspectRatio] boolValue];
    }
    
    UIImage *image = [self sd_createPDFImageWithData:data pageNumber:pageNumber targetSize:imageSize preserveAspectRatio:preserveAspectRatio];
    
    return image;
}


- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return NO;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    return nil;
}

// Using Core Graphics to draw PDF but not PDFKit(iOS 11+/macOS 10.4+) to keep old firmware compatible
- (UIImage *)sd_createPDFImageWithData:(nonnull NSData *)data pageNumber:(NSUInteger)pageNumber targetSize:(CGSize)targetSize preserveAspectRatio:(BOOL)preserveAspectRatio {
    NSParameterAssert(data);
    UIImage *image;
    
#if SD_MAC
    // macOS's `NSImage` supports PDF built-in rendering
    image = [[NSImage alloc] initWithData:data];
    
#else
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    if (!provider) {
        return nil;
    }
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
    CGDataProviderRelease(provider);
    if (!document) {
        return nil;
    }
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, pageNumber);
    if (!page) {
        CGPDFDocumentRelease(document);
        return nil;
    }
    
    // Check if we can use built-in PDF image support, instead of draw bitmap
    if ([[self class] supportsBuiltInPDFImage]) {
        UIImage *image = [UIImage _imageWithCGPDFPage:page];
        CGPDFDocumentRelease(document);
        return image;
    }
    
    CGPDFBox box = kCGPDFCropBox;
    CGRect rect = CGPDFPageGetBoxRect(page, box);
    CGRect targetRect = rect;
    if (!CGSizeEqualToSize(targetSize, CGSizeZero)) {
        targetRect = CGRectMake(0, 0, targetSize.width, targetSize.height);
    }
    
    CGFloat xRatio = targetRect.size.width / rect.size.width;
    CGFloat yRatio = targetRect.size.height / rect.size.height;
    CGFloat xScale = preserveAspectRatio ? MIN(xRatio, yRatio) : xRatio;
    CGFloat yScale = preserveAspectRatio ? MIN(xRatio, yRatio) : yRatio;
    
    // CGPDFPageGetDrawingTransform will only scale down, but not scale up, so we need calculcate the actual scale again
    CGRect drawRect = CGRectMake( 0, 0, targetRect.size.width / xScale, targetRect.size.height / yScale);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(xScale, yScale);
    CGAffineTransform transform = CGPDFPageGetDrawingTransform(page, box, drawRect, 0, preserveAspectRatio);
    
    UIGraphicsBeginImageContextWithOptions(targetRect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Core Graphics coordinate system use the bottom-left, iOS use the flipped one
    CGContextTranslateCTM(context, 0, targetRect.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    CGContextConcatCTM(context, scaleTransform);
    CGContextConcatCTM(context, transform);
    
    CGContextDrawPDFPage(context, page);
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGPDFDocumentRelease(document);
#endif
    
    return image;
}

+ (BOOL)supportsBuiltInPDFImage {
    static dispatch_once_t onceToken;
    static BOOL supports;
    dispatch_once(&onceToken, ^{
        // iOS 11+ supports PDF built-in rendering, use selector to check is more accurate
        if ([UIImage respondsToSelector:@selector(_imageWithCGPDFPage:)]) {
            supports = YES;
        } else {
            supports = NO;
        }
    });
    return supports;
}

+ (BOOL)isPDFFormatForData:(NSData *)data {
    if (!data) {
        return NO;
    }
    uint32_t magic4;
    [data getBytes:&magic4 length:4]; // 4 Bytes Magic Code for most file format.
    switch (magic4) {
        case SD_FOUR_CC('%', 'P', 'D', 'F'): { // %PDF
            return YES;
        }
        default: {
            return NO;
        }
    }
}

@end
