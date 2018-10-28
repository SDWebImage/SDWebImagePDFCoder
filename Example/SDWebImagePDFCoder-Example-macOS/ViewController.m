//
//  ViewController.m
//  SDWebImagePDFCoder-Example-macOS
//
//  Created by lizhuoli on 2018/10/28.
//  Copyright © 2018 lizhuoli1126@126.com. All rights reserved.
//

#import "ViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImagePDFCoder/SDWebImagePDFCoder.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    SDImagePDFCoder *PDFCoder = [SDImagePDFCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:PDFCoder];
    NSURL *pdfURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/icons8/flat-color-icons/master/pdf/about.pdf"];
    NSURL *pdfURL2 = [NSURL URLWithString:@"https://raw.githubusercontent.com/icons8/flat-color-icons/master/pdf/webcam.pdf"];
    
    CGSize screenSize = self.view.bounds.size;
    
    UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width / 2, screenSize.height)];
    imageView1.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(screenSize.width / 2, 0, screenSize.width / 2, screenSize.height)];
    imageView2.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    [self.view addSubview:imageView1];
    [self.view addSubview:imageView2];
    
    [imageView1 sd_setImageWithURL:pdfURL placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"PDF load success");
        }
    }];
    [imageView2 sd_setImageWithURL:pdfURL2 placeholderImage:nil options:SDWebImageRetryFailed context:@{SDWebImageContextPDFImageSize : @(imageView2.bounds.size)} progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"PDF load animation success");
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                NSAnimationContext *currentContext = [NSAnimationContext currentContext];
                currentContext.duration = 2;
                imageView2.animator.bounds = CGRectMake(0, 0, screenSize.width / 4, screenSize.height / 2);
            } completionHandler:^{
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                    NSAnimationContext *currentContext = [NSAnimationContext currentContext];
                    currentContext.duration = 2;
                    imageView2.animator.bounds = CGRectMake(0, 0, screenSize.width / 2, screenSize.height);
                }];
            }];
        }
    }];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
