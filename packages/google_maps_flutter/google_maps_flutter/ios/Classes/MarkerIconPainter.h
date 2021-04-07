//
//  MarkerIconPainter.h
//  Pods
//
//  Created by boris on 2021/1/19.
//

#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MarkerIconPainter : NSObject
@property(atomic) UIColor* clusterBackgroundColor;
@property(atomic) UIColor* clusterFontColor;
- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar;
- (UIImage*) getRiderAvatar:(NSString *)path name:(NSString*)name status:(int)status ratio:(NSNumber *)ratio;
- (UIImage*) getUIImageFromPath:(NSString*)path ratio:(NSNumber*)ratio;
- (UIImage*) getUIImageFromAsset:(NSString*)assetName;
- (UIImage*) getUIImageFromText:(NSString*)text ratio:(NSNumber*)ratio;
- (UIImage*) getUIImageFromCluster:(int)index;
- (UIImage*) combineAvatarAndStatus:(UIImage*)avatar status:(UIImage*)status;
- (UIImage*) withSos:(UIImage*)avatar ratio:(NSNumber*)ratio;
@end
