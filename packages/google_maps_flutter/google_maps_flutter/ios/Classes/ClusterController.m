//
//  ClusterController.m
//  google_maps_flutter
//
//  Created by boris on 2021/3/25.
//

#import "ClusterController.h"
#import "JsonConversions.h"

@implementation BClusterItem {}

- (instancetype)initWithPosition:(CLLocationCoordinate2D)position
                        markerId:(NSString*)markerId {
  self = [super init];
  _markerId = markerId;
  self.position = position;
  return self;
}

@synthesize alpha;
@synthesize anchor;
@synthesize consume;
@synthesize draggable;
@synthesize flat;
@synthesize path;
@synthesize name;
@synthesize ratio;
@synthesize status;
@synthesize title;
@synthesize snippet;
@synthesize rotation;
@synthesize visible;
@synthesize zIndex;

@synthesize position;

- (NSUInteger) hash {
    return _markerId.hash;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (![other isKindOfClass:[BClusterItem class]]) {
        return NO;
    }

    return [self.markerId isEqualToString:((BClusterItem*) other).markerId];
}

@end

@implementation ClusterController {
    NSMutableDictionary* _clusterItems;
    FlutterMethodChannel* _methodChannel;
    NSObject<FlutterPluginRegistrar>* _registrar;
    GMSMapView* _mapView;
    GMUClusterManager* _clusterManager;
}

- (instancetype)init:(FlutterMethodChannel*)methodChannel
            mapView:(GMSMapView*)mapView
            registrar:(NSObject<FlutterPluginRegistrar>*)registrar
            clusterManager:(nonnull GMUClusterManager *)clusterManager{
  self = [super init];
  if (self) {
    _methodChannel = methodChannel;
    _mapView = mapView;
    _clusterItems = [NSMutableDictionary dictionaryWithCapacity:1];
    _registrar = registrar;
    _clusterManager = clusterManager;
  }
  return self;
}

- (void)addOrUpdateMarkers:(NSArray *)markers {
    for (NSDictionary* marker in markers) {
        NSString* markerId = [ClusterController getMarkerId:marker];
        if ([self checkMarkerIsExist:markerId]) {
            [self removeClusterItemFromClusterManager:markerId];
        }
        BClusterItem* clusterItem = [self createClusterItem:marker];
        _clusterItems[markerId] = clusterItem;
        [_clusterManager addItem:clusterItem];
    }
    [_clusterManager cluster];
}

- (void)removeMarker:(NSArray *)markerIds {
    for (NSString* markerId in markerIds) {
        if (!markerId) {
            continue;
        }
        [self removeClusterItemFromClusterManager:markerId];
        [_clusterItems removeObjectForKey:markerId];
    }
}

- (BOOL)onMarkerTap:(NSString *)markerId {
    if (!markerId) {
      return NO;
    }
    BClusterItem* item = _clusterItems[markerId];
    if (!item) {
      return NO;
    }
    
    [_methodChannel invokeMethod:@"marker#onTap" arguments:@{@"markerId" : markerId}];
    return item.consume;
}

- (BOOL)checkMarkerIsExist:(NSString *)markerId {
    return _clusterItems[markerId] != nil;
}

- (void) moveCamera:(CLLocationCoordinate2D)position level:(float) level {
    float zoom = _mapView.camera.zoom + level;
    [_mapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:position zoom:zoom]];
}

- (void) removeClusterItemFromClusterManager:(NSString* )markerId {
    BClusterItem* item = _clusterItems[markerId];
    if (item) {
        [_clusterManager removeItem:(id)item];
    }
}

- (CLLocationCoordinate2D)getPosition:(NSDictionary*)marker {
  NSArray* position = marker[@"position"];
  return [FLTGoogleMapJsonConversions toLocation:position];
}

+ (NSString*)getMarkerId:(NSDictionary*)marker {
  return marker[@"markerId"];
}

- (BClusterItem*)createClusterItem: (NSDictionary*)data {
    BClusterItem* item = [[BClusterItem alloc] initWithPosition:[self getPosition:data] markerId:data[@"markerId"]];
    
    NSNumber* alpha = data[@"alpha"];
    if (alpha != nil) {
        item.alpha = [FLTGoogleMapJsonConversions toFloat:alpha];
    }
    
    NSArray* anchor = data[@"anchor"];
    if (anchor) {
        item.anchor = [FLTGoogleMapJsonConversions toPoint:anchor];
    }
    
    NSNumber* draggable = data[@"draggable"];
    if (draggable != nil) {
        item.draggable = [FLTGoogleMapJsonConversions toBool:draggable];
    }
    
    NSNumber* flat = data[@"flat"];
    if (flat != nil) {
        item.flat = [FLTGoogleMapJsonConversions toBool:flat];
    }
    
    NSNumber* consumeTapEvents = data[@"consumeTapEvents"];
    if (consumeTapEvents != nil) {
        item.consume = [FLTGoogleMapJsonConversions toBool:consumeTapEvents];
    }
    
    NSNumber* rotation = data[@"rotation"];
    if (rotation != nil) {
        item.rotation = [FLTGoogleMapJsonConversions toDouble:rotation];
    }
    
    NSNumber* visible = data[@"visible"];
    if (visible != nil) {
        item.visible = [FLTGoogleMapJsonConversions toBool:visible];
    }
    
    NSNumber* zIndex = data[@"zIndex"];
    if (zIndex != nil) {
        item.zIndex = [FLTGoogleMapJsonConversions toInt:zIndex];
    }
    
    NSDictionary* extra = data[@"extra"];
    if (extra != nil) {
        NSString* path = extra[@"path"];
        if (path != nil && path != [NSNull null]) {
            item.path = path;
        }
        
        NSString* name = extra[@"name"];
        if (name != nil) {
            item.name = name;
            item.title = name;
        }
        
        NSNumber* ratio = extra[@"ratio"];
        if (ratio != nil) {
            item.ratio = ratio;
        } else {
            item.ratio = [NSNumber numberWithFloat:1.0f];
        }
        
        NSNumber* status = extra[@"rideStatus"];
        if (status != nil) {
            item.status = status.intValue;
        } else {
            item.status = 0;
        }
    }
    return item;
}

@end
