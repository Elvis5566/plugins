//
//  MarkerIconPainter.h
//  Pods
//
//  Created by boris on 2021/1/19.
//

#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MarkerIconPainter : NSObject
- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar;
- (UIImage*) getUIImageFromPath:(NSString*)path;
- (UIImage*) getUIImageFromAsset:(NSString*)assetName;
- (UIImage*) getUIImageFromText:(NSString*)text;
- (UIImage*) getUIImageFromCluster:(int)index;
- (UIImage*) combineAvatarAndStatus:(UIImage*)avatar status:(UIImage*)status;
@end
