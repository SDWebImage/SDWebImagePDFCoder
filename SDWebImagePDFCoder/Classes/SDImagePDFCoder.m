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

#if SD_UIKIT || SD_WATCH
static SEL SDImageWithCGPDFPageSEL = NULL;
static SEL SDCGPDFPageSEL = NULL;

static inline NSString *SDBase64DecodedString(NSString *base64String) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
#endif

@implementation SDImagePDFCoder

#if SD_UIKIT || SD_WATCH
+ (void)initialize {
    SDImageWithCGPDFPageSEL = NSSelectorFromString(SDBase64DecodedString(@"X2ltYWdlV2l0aENHUERGUGFnZTo="));
    SDCGPDFPageSEL = NSSelectorFromString(SDBase64DecodedString(@"X0NHUERGUGFnZQ=="));
}
#endif

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
    BOOL prefersBitmap = NO;
    CGSize imageSize = CGSizeZero;
    BOOL preserveAspectRatio = YES;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Parse args
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextPDFPageNumber]) {
        pageNumber = [context[SDWebImageContextPDFPageNumber] unsignedIntegerValue];
    } else if (options[SDImageCoderDecodePDFPageNumber]) {
        pageNumber = [options[SDImageCoderDecodePDFPageNumber] unsignedIntegerValue];
    }
    if (context[SDWebImageContextPDFImageSize]) {
        prefersBitmap = YES;
        NSValue *sizeValue = context[SDWebImageContextPDFImageSize];
#if SD_MAC
        imageSize = sizeValue.sizeValue;
#else
        imageSize = sizeValue.CGSizeValue;
#endif
    } else if (options[SDImageCoderDecodeThumbnailPixelSize]) {
        prefersBitmap = YES;
        NSValue *sizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
#if SD_MAC
        imageSize = sizeValue.sizeValue;
#else
        imageSize = sizeValue.CGSizeValue;
#endif
    } else if (context[SDWebImageContextPDFPrefersBitmap]) {
        prefersBitmap = [context[SDWebImageContextPDFPrefersBitmap] boolValue];
    }
    if (context[SDWebImageContextPDFImagePreserveAspectRatio]) {
        preserveAspectRatio = [context[SDWebImageContextPDFImagePreserveAspectRatio] boolValue];
    } else if (options[SDImageCoderDecodePreserveAspectRatio]) {
        preserveAspectRatio = [context[SDImageCoderDecodePreserveAspectRatio] boolValue];
    }
#pragma clang diagnostic pop
    
    UIImage *image;
    if (!prefersBitmap && [self.class supportsVectorPDFImage]) {
        image = [self createVectorPDFWithData:data pageNumber:pageNumber];
    } else {
        image = [self createBitmapPDFWithData:data pageNumber:pageNumber targetSize:imageSize preserveAspectRatio:preserveAspectRatio];
    }
    
    image.sd_imageFormat = SDImageFormatPDF;
    
    return image;
}


- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return format == SDImageFormatPDF;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    if (![self.class supportsVectorPDFImage]) {
        return nil;
    }
#if SD_MAC
    // Pixel size use `NSImageRepMatchesDevice` to avoid CGImage bitmap format
    NSRect imageRect = NSMakeRect(0, 0, NSImageRepMatchesDevice, NSImageRepMatchesDevice);
    NSImageRep *imageRep = [image bestRepresentationForRect:imageRect context:nil hints:nil];
    if (![imageRep isKindOfClass:NSPDFImageRep.class]) {
        return nil;
    }
    return ((NSPDFImageRep *)imageRep).PDFRepresentation;
#else
    CGPDFPageRef page = ((CGPDFPageRef (*)(id,SEL))[image methodForSelector:SDCGPDFPageSEL])(image, SDCGPDFPageSEL);
    if (!page) {
        return nil;
    }
    
    // Draw the PDF page using PDFContextToData
    NSMutableData *data = [NSMutableData data];
    CGPDFBox box = kCGPDFMediaBox;
    CGRect rect = CGPDFPageGetBoxRect(page, box);
    
    UIGraphicsBeginPDFContextToData(data, CGRectZero, nil);
    UIGraphicsBeginPDFPageWithInfo(rect, nil);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    // Core Graphics Coordinate System convert
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -CGRectGetHeight(rect));
    CGContextDrawPDFPage(context, page);
    UIGraphicsEndPDFContext();
    
    return [data copy];
#endif
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
    
    image = ((UIImage *(*)(id,SEL,CGPDFPageRef))[UIImage.class methodForSelector:SDImageWithCGPDFPageSEL])(UIImage.class, SDImageWithCGPDFPageSEL, page);
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
    
    CGPDFBox box = kCGPDFMediaBox;
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
    
#if SD_UIKIT || SD_WATCH
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
        if ([UIImage respondsToSelector:SDImageWithCGPDFPageSEL]) {
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
