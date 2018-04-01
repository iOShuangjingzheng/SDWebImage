/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDefine.h"
#import "UIImage+WebCache.h"
#import "NSImage+Additions.h"

#pragma mark - Image scale

static inline NSArray<NSNumber *> * _Nonnull SDImageScaleFactors() {
    return @[@2, @3];
}

inline CGFloat SDImageScaleForKey(NSString * _Nullable key) {
    CGFloat scale = 1;
    if (!key) {
        return scale;
    }
    // Check if target OS support scale
#if SD_WATCH
    if ([[WKInterfaceDevice currentDevice] respondsToSelector:@selector(screenScale)])
#elif SD_UIKIT
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
#elif SD_MAC
    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)])
#endif
    {
        // a@2x.png -> 8
        if (key.length >= 8) {
            // Fast check
            BOOL isURL = [key hasPrefix:@"http://"] || [key hasPrefix:@"https://"];
            for (NSNumber *scaleFactor in SDImageScaleFactors()) {
                // @2x. for file name and normal url
                NSString *fileScale = [NSString stringWithFormat:@"@%@x.", scaleFactor];
                if ([key containsString:fileScale]) {
                    scale = scaleFactor.doubleValue;
                    return scale;
                }
                if (isURL) {
                    // %402x. for url encode
                    NSString *urlScale = [NSString stringWithFormat:@"%%40%@x.", scaleFactor];
                    if ([key containsString:urlScale]) {
                        scale = scaleFactor.doubleValue;
                        return scale;
                    }
                }
            }
        }
    }
    return scale;
}

inline UIImage *SDScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image) {
    if (!image) {
        return nil;
    }
    
    CGFloat scale = SDImageScaleForKey(key);
    if (scale > 1) {
        UIImage *scaledImage;
        if (image.sd_isAnimated) {
            UIImage *animatedImage;
#if SD_UIKIT || SD_WATCH
            // `UIAnimatedImage` images share the same size and scale.
            NSMutableArray<UIImage *> *scaledImages = [NSMutableArray array];
            
            for (UIImage *tempImage in image.images) {
                UIImage *tempScaledImage = [[UIImage alloc] initWithCGImage:tempImage.CGImage scale:scale orientation:tempImage.imageOrientation];
                [scaledImages addObject:tempScaledImage];
            }
            
            animatedImage = [UIImage animatedImageWithImages:scaledImages duration:image.duration];
            animatedImage.sd_imageLoopCount = image.sd_imageLoopCount;
#else
            // Animated GIF for `NSImage` need to grab `NSBitmapImageRep`
            NSSize size = NSMakeSize(image.size.width / scale, image.size.height / scale);
            animatedImage = [[NSImage alloc] initWithSize:size];
            NSBitmapImageRep *bitmapImageRep = image.bitmapImageRep;
            [animatedImage addRepresentation:bitmapImageRep];
#endif
            scaledImage = animatedImage;
        } else {
#if SD_UIKIT || SD_WATCH
            scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
#else
            scaledImage = [[NSImage alloc] initWithCGImage:image.CGImage size:NSZeroSize];
#endif
        }
        
        return scaledImage;
    }
    return image;
}

#pragma mark - Context option

SDWebImageContextOption const SDWebImageContextSetImageOperationKey = @"setImageOperationKey";
SDWebImageContextOption const SDWebImageContextSetImageGroup = @"setImageGroup";
SDWebImageContextOption const SDWebImageContextCustomManager = @"customManager";
SDWebImageContextOption const SDWebImageContextCustomTransformer = @"customTransformer";
SDWebImageContextOption const SDWebImageContextAnimatedImageClass = @"animatedImageClass";
