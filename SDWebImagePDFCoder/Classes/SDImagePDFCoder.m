//
//  SDImagePDFCoder.m
//  SDWebImagePDFCoder
//
//  Created by lizhuoli on 2018/10/28.
//

#import "SDImagePDFCoder.h"
#import "SDWebImagePDFCoderDefine.h"
#import "objc/runtime.h"

#define SD_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))

#if SD_UIKIT
// iOS/tvOS 11+ UIImage add built-in vector PDF image support. So we use that instead of drawing bitmap image
@interface UIImage (PrivatePDFSupport)

- (instancetype)_initWithCGPDFPage:(CGPDFPageRef)page;
- (instancetype)_initWithCGPDFPage:(CGPDFPageRef)page scale:(double)scale orientation:(UIImageOrientation)orientation;
+ (instancetype)_imageWithCGPDFPage:(CGPDFPageRef)page;
+ (instancetype)_imageWithCGPDFPage:(CGPDFPageRef)page scale:(double)scale orientation:(UIImageOrientation)orientation;

@end
#endif

#if SD_MAC
static void *kNSGraphicsContextScaleFactorKey;

static CGContextRef SDCGContextCreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale) {
    if (scale == 0) {
        // Match `UIGraphicsBeginImageContextWithOptions`, reset to the scale factor of the device’s main screen if scale is 0.
        scale = [NSScreen mainScreen].backingScaleFactor;
    }
    size_t width = ceil(size.width * scale);
    size_t height = ceil(size.height * scale);
    if (width < 1 || height < 1) return NULL;
    
    //pre-multiplied BGRA for non-opaque, BGRX for opaque, 8-bits per component, as Apple's doc
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGImageAlphaInfo alphaInfo = kCGBitmapByteOrder32Host | (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, space, kCGBitmapByteOrderDefault | alphaInfo);
    CGColorSpaceRelease(space);
    if (!context) {
        return NULL;
    }
    CGContextScaleCTM(context, scale, scale);
    
    return context;
}
#endif

static void SDGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale) {
#if SD_UIKIT || SD_WATCH
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
#else
    CGContextRef context = SDCGContextCreateBitmapContext(size, opaque, scale);
    if (!context) {
        return;
    }
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
    objc_setAssociatedObject(graphicsContext, &kNSGraphicsContextScaleFactorKey, @(scale), OBJC_ASSOCIATION_RETAIN);
    CGContextRelease(context);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = graphicsContext;
#endif
}

static CGContextRef SDGraphicsGetCurrentContext(void) {
#if SD_UIKIT || SD_WATCH
    return UIGraphicsGetCurrentContext();
#else
    return NSGraphicsContext.currentContext.CGContext;
#endif
}

static void SDGraphicsEndImageContext(void) {
#if SD_UIKIT || SD_WATCH
    UIGraphicsEndImageContext();
#else
    [NSGraphicsContext restoreGraphicsState];
#endif
}

static UIImage * SDGraphicsGetImageFromCurrentImageContext(void) {
#if SD_UIKIT || SD_WATCH
    return UIGraphicsGetImageFromCurrentImageContext();
#else
    NSGraphicsContext *context = NSGraphicsContext.currentContext;
    CGContextRef contextRef = context.CGContext;
    if (!contextRef) {
        return nil;
    }
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    if (!imageRef) {
        return nil;
    }
    CGFloat scale = 0;
    NSNumber *scaleFactor = objc_getAssociatedObject(context, &kNSGraphicsContextScaleFactorKey);
    if ([scaleFactor isKindOfClass:[NSNumber class]]) {
        scale = scaleFactor.doubleValue;
    }
    if (!scale) {
        // reset to the scale factor of the device’s main screen if scale is 0.
        scale = [NSScreen mainScreen].backingScaleFactor;
    }
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
    CGImageRelease(imageRef);
    return image;
#endif
}

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
    
    NSUInteger pageNumber = 0;
    BOOL preferredBitmap = NO;
    CGSize imageSize = CGSizeZero;
    BOOL preserveAspectRatio = YES;
    // Parse args
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextPDFPageNumber]) {
        pageNumber = [context[SDWebImageContextPDFPageNumber] unsignedIntegerValue];
    }
    if (context[SDWebImageContextPDFPerferredBitmap]) {
        preferredBitmap = [context[SDWebImageContextPDFPerferredBitmap] boolValue];
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
    
    UIImage *image;
    if (!preferredBitmap && [self.class supportsVectorPDFImage]) {
        image = [self createVectorPDFWithData:data pageNumber:pageNumber];
    } else {
        image = [self createBitmapPDFWithData:data pageNumber:pageNumber targetSize:imageSize preserveAspectRatio:preserveAspectRatio];
    }
    
    image.sd_imageFormat = SDImageFormatPDF;
    
    return image;
}


- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return NO;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    return nil;
}

#pragma mark - Vector PDF representation
- (UIImage *)createVectorPDFWithData:(nonnull NSData *)data pageNumber:(NSUInteger)pageNumber {
    NSParameterAssert(data);
    UIImage *image;
    
#if SD_MAC
    // macOS's `NSImage` supports PDF built-in rendering
    NSPDFImageRep *imageRep = [[NSPDFImageRep alloc] initWithData:data];
    if (!imageRep) {
        return nil;
    }
    imageRep.currentPage = pageNumber;
    image = [[NSImage alloc] initWithSize:imageRep.size];
    [image addRepresentation:imageRep];
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
    
    // `CGPDFDocumentGetPage` page number is 1-indexed.
    CGPDFPageRef page = CGPDFDocumentGetPage(document, pageNumber + 1);
    if (!page) {
        CGPDFDocumentRelease(document);
        return nil;
    }
    
    image = [UIImage _imageWithCGPDFPage:page];
    CGPDFDocumentRelease(document);
#endif
    
    return image;
}

#pragma mark - Bitmap PDF representation
- (UIImage *)createBitmapPDFWithData:(nonnull NSData *)data pageNumber:(NSUInteger)pageNumber targetSize:(CGSize)targetSize preserveAspectRatio:(BOOL)preserveAspectRatio {
    NSParameterAssert(data);
    UIImage *image;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    if (!provider) {
        return nil;
    }
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
    CGDataProviderRelease(provider);
    if (!document) {
        return nil;
    }
    
    // `CGPDFDocumentGetPage` page number is 1-indexed.
    CGPDFPageRef page = CGPDFDocumentGetPage(document, pageNumber + 1);
    if (!page) {
        CGPDFDocumentRelease(document);
        return nil;
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
    
    SDGraphicsBeginImageContextWithOptions(targetRect.size, NO, 0);
    CGContextRef context = SDGraphicsGetCurrentContext();
    
#if SD_UIKIT
    // Core Graphics coordinate system use the bottom-left, UIkit use the flipped one
    CGContextTranslateCTM(context, 0, targetRect.size.height);
    CGContextScaleCTM(context, 1, -1);
#endif
    
    CGContextConcatCTM(context, scaleTransform);
    CGContextConcatCTM(context, transform);
    
    CGContextDrawPDFPage(context, page);
    
    image = SDGraphicsGetImageFromCurrentImageContext();
    SDGraphicsEndImageContext();
    
    CGPDFDocumentRelease(document);
    
    return image;
}

+ (BOOL)supportsVectorPDFImage {
#if SD_MAC
    // macOS's `NSImage` supports PDF built-in rendering
    return YES;
#else
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
#endif
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
