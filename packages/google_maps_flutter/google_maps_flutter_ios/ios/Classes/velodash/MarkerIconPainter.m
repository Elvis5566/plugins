//
//  MarkerIconPainter.m
//  google_maps_flutter
//
//  Created by boris on 2021/1/19.
//

#import "MarkerIconPainter.h"

static UIImage* scaleImage(UIImage* image, NSNumber* scaleParam) {
  double scale = 1.0;
  if ([scaleParam isKindOfClass:[NSNumber class]]) {
    scale = scaleParam.doubleValue;
  }
  if (fabs(scale - 1) > 1e-3) {
    return [UIImage imageWithCGImage:[image CGImage]
                               scale:(image.scale * scale)
                         orientation:(image.imageOrientation)];
  }
  return image;
}

static UIImage* toAvatar(UIImage* image, NSNumber* ratio) {
    float iconSize = 48.0 * ratio.floatValue;
    float borderSize = 4.0 * ratio.floatValue;
    image = scaleImage(image, [[NSNumber alloc] initWithFloat:image.size.width / iconSize]);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconSize + borderSize * 2, iconSize + borderSize * 2), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect backgroundRect = CGRectMake(0, 0, iconSize + borderSize * 2, iconSize + borderSize * 2);
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextAddEllipseInRect(context, backgroundRect);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawPath(context, kCGPathFill);
    CGContextFillRect(context, backgroundRect);
    
    CGContextAddEllipseInRect(context, CGRectMake(borderSize, borderSize, iconSize, iconSize));
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawPath(context, kCGPathFill);
    [image drawInRect:CGRectMake(borderSize, borderSize, iconSize, iconSize)];
    
    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return view;
}

static int getClusterSize(int index) {
    if (index >= 1000) {
        return 80;
    } else if (index >= 500 && index < 1000) {
        return 72;
    } else if (index >= 100 && index < 500) {
        return 64;
    } else if (index >= 50 && index < 100) {
        return 56;
    } else {
        return 48;
    }
}

@implementation MarkerIconPainter {
    NSObject<FlutterPluginRegistrar>* _registrar;
    UIImage* statusOfLeft;
    UIImage* statusOfLost;
    UIImage* statusOfPause;
}

- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar {
  self = [super init];
  if (self) {
    _registrar = registrar;
    statusOfLeft = [self getUIImageFromAsset:@"common_app/assets/rider_left_png.png"];
    statusOfLost = [self getUIImageFromAsset:@"common_app/assets/rider_disconnected_png.png"];
    statusOfPause = [self getUIImageFromAsset:@"common_app/assets/rider_pause_png.png"];
  }
  return self;
}

- (UIImage*) getRiderAvatar:(NSString *)path name:(NSString*)name status:(int)status ratio:(NSNumber *)ratio highlight:(BOOL)highlight {
    UIImage* image;
    if (path != nil && path != [NSNull null]) {
        image = [self getUIImageFromPath:path ratio:ratio];
    } else {
        image = [self getUIImageFromText:name ratio:ratio];
    }
    
    switch (status) {
        case 1:
            if (highlight) {
                return [self withHighlight:[self combineAvatarAndStatus:image status:statusOfPause] ratio:ratio hasPadding:YES];
            } else {
                return [self combineAvatarAndStatus:image status:statusOfPause];
            }
        case 2:
            if (highlight) {
                return [self withHighlight:[self combineAvatarAndStatus:image status:statusOfLost] ratio:ratio hasPadding:YES];
            } else {
                return [self combineAvatarAndStatus:image status:statusOfLost];
            }
        case 3:
            if (highlight) {
                return [self withHighlight:[self combineAvatarAndStatus:image status:statusOfLeft] ratio:ratio hasPadding:YES];
            } else {
                return [self combineAvatarAndStatus:image status:statusOfLeft];
            }
        case 5:
            return [self withSos:image ratio:ratio];
        default:
            if (highlight) {
                return [self withHighlight:image ratio:ratio  hasPadding:NO];
            } else {
                return image;
            }
    }
}

- (UIImage*) getUIImageFromPath:(NSString *)path ratio:(NSNumber *)ratio {
    @try {
        return toAvatar([UIImage imageWithContentsOfFile:path], ratio);
    } @catch (NSException *exception) {
        @throw [NSException exceptionWithName:@"getUIImageFromPathInvalidPath"
                                       reason:[NSString stringWithFormat:@"%@%@", @"unable to load image from path", path]
                                     userInfo:nil];
    }
}

- (UIImage*) getUIImageFromAsset:(NSString *)assetName {
    UIImage* status = [UIImage imageNamed:[_registrar lookupKeyForAsset:assetName]];
    status = scaleImage(status, [[NSNumber alloc] initWithFloat:status.size.width / 24]);
    return status;
}

- (UIImage*) combineAvatarAndStatus:(UIImage *)avatar status:(UIImage *)status {
    float paddingSize = 2.0;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(avatar.size.width + paddingSize * 2, avatar.size.height + paddingSize * 2), NO, 0.0);
    
    [avatar drawInRect:CGRectMake(0, paddingSize * 2, avatar.size.width, avatar.size.height)];
    [status drawInRect:CGRectMake(avatar.size.width + paddingSize * 2 - status.size.width, 0, status.size.width, status.size.height)];

    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return view;
}

- (UIImage*) getUIImageFromText:(NSString *)text ratio:(NSNumber *)ratio {
    float iconSize = 48.0 * ratio.floatValue;
    float borderSize = 4.0 * ratio.floatValue;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconSize + borderSize * 2, iconSize + borderSize * 2), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect backgroundRect = CGRectMake(0, 0, iconSize + borderSize * 2, iconSize + borderSize * 2);
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextAddEllipseInRect(context, backgroundRect);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawPath(context, kCGPathFill);
    CGContextFillRect(context, backgroundRect);
    
    CGRect bodyRect = CGRectMake(borderSize, borderSize, iconSize, iconSize);
    CGContextAddEllipseInRect(context, bodyRect);
    CGContextSetRGBFillColor(context, 149.0/255.0, 149.0/255.0, 149.0/255.0, 1.0f);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawPath(context, kCGPathFill);
    CGContextFillRect(context, bodyRect);
    
    UIFont* font = [UIFont boldSystemFontOfSize:18.0];
    NSDictionary* attr = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    CGSize textSize = [text sizeWithAttributes:attr];
    CGRect textRect = CGRectMake(borderSize + floorf((iconSize + borderSize - textSize.width) / 2), borderSize + floorf((iconSize + borderSize - textSize.height) / 2), textSize.width, textSize.height);
    [text drawInRect:textRect withAttributes:attr];
    
    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return view;
}

- (UIImage*) getUIImageFromCluster:(int)index {
    float iconSize = getClusterSize(index);
    NSString* text;
    if (index >= 10) {
        text = [NSString stringWithFormat:@"%@%@", [@(index) stringValue], @"+"];
    } else {
        text = [@(index) stringValue];
    }
    
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconSize, iconSize), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [_clusterBackgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    CGRect backgroundRect = CGRectMake(0, 0, iconSize, iconSize);
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    CGContextAddEllipseInRect(context, backgroundRect);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawPath(context, kCGPathFill);
    CGContextFillRect(context, backgroundRect);
    
    UIFont* font = [UIFont boldSystemFontOfSize:18.0];
    NSDictionary* attr = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: _clusterFontColor,
    };
    CGSize textSize = [text sizeWithAttributes:attr];
    CGRect textRect = CGRectMake(0 + floorf((iconSize - textSize.width) / 2), 0 + floorf((iconSize - textSize.height) / 2), textSize.width, textSize.height);
    [text drawInRect:textRect withAttributes:attr];
    
    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return view;
}

- (UIImage*) withSos:(UIImage *)avatar ratio:(NSNumber *)ratio {
    float shadowSize = 6 * ratio.floatValue;
    float iconSize = avatar.size.width + shadowSize * 2;
    CGPoint center = CGPointMake(iconSize / 2, iconSize / 2);
    float radius = iconSize / 2;
    CGRect ellipseRect = CGRectMake(0, 0, iconSize, iconSize);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconSize, iconSize), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat colors[] = {
        1.0, 0.0, 0.0, 0.0,
        1.0, 0.0, 0.0, 0.1,
        1.0, 0.0, 0.0, 0.15,
        1.0, 0.0, 0.0, 0.2,
        1.0, 0.0, 0.0, 0.25,
        1.0, 0.0, 0.0, 0.3,
        1.0, 0.0, 0.0, 0.31,
        1.0, 0.0, 0.0, 0.32,
        1.0, 0.0, 0.0, 0.33,
        1.0, 0.0, 0.0, 0.65,
        1.0, 0.0, 0.0, 0.7,
    };
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradientref = CGGradientCreateWithColorComponents(colorSpaceRef, colors, NULL, 11);
    CGContextAddEllipseInRect(context, ellipseRect);
    CGContextClip(context);

    CGContextDrawRadialGradient(context, gradientref, center, radius, center, radius - shadowSize, kCGGradientDrawsAfterEndLocation);

    [avatar drawInRect:CGRectMake(shadowSize, shadowSize, avatar.size.width, avatar.size.height)];

    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return view;
}

- (UIImage*) withHighlight:(UIImage *)avatar ratio:(NSNumber *)ratio hasPadding:(BOOL)hasPadding {
    float shadowSize = 6 * ratio.floatValue;
    float paddingSize = 2 * ratio.floatValue;
    float iconSize = avatar.size.width + shadowSize * 2 + paddingSize * 2;
    float offset = 0;
    if (hasPadding) {
        offset = 2;
    }
    CGPoint center = CGPointMake(iconSize / 2 - offset, iconSize / 2 + offset);
    float radius = iconSize / 2;
    CGRect ellipseRect = CGRectMake(0, 0, iconSize, iconSize);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconSize, iconSize), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat colors[] = {
        0.0, 1.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.08,
        0.0, 1.0, 0.0, 0.16,
        0.0, 1.0, 0.0, 0.24,
        0.0, 1.0, 0.0, 0.32,
        0.0, 1.0, 0.0, 0.40,
        0.0, 1.0, 0.0, 0.48,
        0.0, 1.0, 0.0, 0.56,
        0.0, 1.0, 0.0, 0.62,
        0.0, 1.0, 0.0, 0.68,
        0.0, 1.0, 0.0, 0.74,
    };
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradientref = CGGradientCreateWithColorComponents(colorSpaceRef, colors, NULL, 11);
    CGContextAddEllipseInRect(context, ellipseRect);
    CGContextClip(context);

    CGContextDrawRadialGradient(context, gradientref, center, radius, center, radius - shadowSize, kCGGradientDrawsAfterEndLocation);

    [avatar drawInRect:CGRectMake(shadowSize + paddingSize, shadowSize + paddingSize, avatar.size.width, avatar.size.height)];

    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return view;
}
@end
