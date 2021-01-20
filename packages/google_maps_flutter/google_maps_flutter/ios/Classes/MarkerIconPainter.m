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

static UIImage* toAvatar(UIImage* image) {
    float iconSize = 48.0;
    float borderSize = 4.0;
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
        return 60;
    } else if (index >= 500 && index < 1000) {
        return 56;
    } else if (index >= 200 && index < 500) {
        return 52;
    } else if (index >= 100 && index < 200) {
        return 48;
    } else if (index >= 50 && index < 100) {
        return 44;
    } else {
        return 40;
    }
}

@implementation MarkerIconPainter {
    NSObject<FlutterPluginRegistrar>* _registrar;
}

- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar {
  self = [super init];
  if (self) {
    _registrar = registrar;
  }
  return self;
}

- (UIImage*) getUIImageFromPath:(NSString *)path {
    @try {
        return toAvatar([UIImage imageWithContentsOfFile:path]);
    } @catch (NSException *exception) {
        @throw [NSException exceptionWithName:@"getUIImageFromPathInvalidPath"
                                       reason:@"unable to load image from path"
                                     userInfo:nil];
    }
}

- (UIImage*) getUIImageFromAsset:(NSString *)assetName {
    return [UIImage imageNamed:[_registrar lookupKeyForAsset:assetName]];
}

- (UIImage*) combineAvatarAndStatus:(UIImage *)avatar status:(UIImage *)status {
    float iconSize = avatar.size.width;
    float paddingSize = 2.0;
    status = scaleImage(status, [[NSNumber alloc] initWithFloat:status.size.width / 24]);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconSize + paddingSize * 2, iconSize + paddingSize * 2), NO, 0.0);
    
    [avatar drawInRect:CGRectMake(0, paddingSize * 2, iconSize, iconSize)];
    [status drawInRect:CGRectMake(iconSize + paddingSize * 2 - status.size.width, 0, status.size.width, status.size.height)];

    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return view;
}

- (UIImage*) getUIImageFromText:(NSString *)text {
    float iconSize = 48.0;
    float borderSize = 4.0;
    
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
    
    CGRect backgroundRect = CGRectMake(0, 0, iconSize, iconSize);
    CGContextSetRGBFillColor(context, 8.0 / 2550., 27.0 / 255.0, 51.0 / 255.0, 0.7f);
    CGContextAddEllipseInRect(context, backgroundRect);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawPath(context, kCGPathFill);
    CGContextFillRect(context, backgroundRect);
    
    UIFont* font = [UIFont boldSystemFontOfSize:18.0];
    NSDictionary* attr = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    CGSize textSize = [text sizeWithAttributes:attr];
    CGRect textRect = CGRectMake(0 + floorf((iconSize - textSize.width) / 2), 0 + floorf((iconSize - textSize.height) / 2), textSize.width, textSize.height);
    [text drawInRect:textRect withAttributes:attr];
    
    UIImage* view = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return view;
}

@end
