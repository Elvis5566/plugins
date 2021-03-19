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
- (UIImage*) getUIImageFromPath:(NSString*)path ratio:(NSNumber*)ratio;
- (UIImage*) getUIImageFromAsset:(NSString*)assetName;
- (UIImage*) getUIImageFromText:(NSString*)text ratio:(NSNumber*)ratio;
- (UIImage*) getUIImageFromCluster:(int)index;
- (UIImage*) combineAvatarAndStatus:(UIImage*)avatar status:(UIImage*)status;
- (UIImage*) withSos:(UIImage*)avatar ratio:(NSNumber*)ratio;
@end
