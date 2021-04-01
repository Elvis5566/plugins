//
//  ClusterController.h
//  google_maps_flutter
//
//  Created by boris on 2021/3/25.
//

#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>
#import "GoogleMapController.h"

@import GoogleMapsUtils;

NS_ASSUME_NONNULL_BEGIN

@interface BClusterItem : NSObject <GMUClusterItem>
@property(atomic, readonly) NSString* markerId;
@property(atomic) float alpha;
@property(atomic) CGPoint anchor;
@property(atomic) BOOL consume;
@property(atomic) BOOL draggable;
@property(atomic) BOOL flat;
@property(atomic) NSString* path;
@property(atomic) NSString* name;
@property(atomic) NSNumber* ratio;
@property(atomic) int status;
@property(atomic) CLLocationDegrees rotation;
@property(atomic) BOOL visible;
@property(atomic) int zIndex;
@property(nonatomic) CLLocationCoordinate2D position;

- (instancetype)initWithPosition:(CLLocationCoordinate2D)position
                        markerId:(NSString*)markerId;

@end

@interface ClusterController : NSObject
- (instancetype)init:(FlutterMethodChannel*)methodChannel
             mapView:(GMSMapView*)mapView
             registrar:(NSObject<FlutterPluginRegistrar>*)registrar
             clusterManager:(GMUClusterManager*)clusterManager;
- (void)addOrUpdateMarkers:(NSArray*)markers;
- (void)removeMarker:(NSArray*)markerIds;
- (BOOL)onMarkerTap:(NSString*)markerId;
- (BOOL)checkMarkerIsExist:(NSString*)markerId;
- (void)moveCamera:(CLLocationCoordinate2D)position level:(float) level;

@end

NS_ASSUME_NONNULL_END
