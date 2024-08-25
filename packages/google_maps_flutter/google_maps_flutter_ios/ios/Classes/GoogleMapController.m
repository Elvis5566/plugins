// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GoogleMapController.h"
#import "FLTGoogleMapJSONConversions.h"
#import "FLTGoogleMapTileOverlayController.h"

#import "MarkerIconPainter.h"
#import "ClusterController.h"
#import "ClusterRenderer.h"
#import "BGridBasedClusterAlgorithm.h"
#import "BClusterManager.h"

#pragma mark - Conversion of JSON-like values sent via platform channels. Forward declarations.

#define TICK(tag) NSDate* tag = [NSDate date]
#define TOCK(tag) NSLog(@"%s: %f s", #tag, -[tag timeIntervalSinceNow])

static dispatch_block_t delayNotifingAnimationCompletedTask;

@interface FLTGoogleMapFactory ()

@property(weak, nonatomic) NSObject<FlutterPluginRegistrar> *registrar;
@property(strong, nonatomic, readonly) id<NSObject> sharedMapServices;

@end

@implementation FLTGoogleMapFactory

@synthesize sharedMapServices = _sharedMapServices;

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    _registrar = registrar;
  }
  return self;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id _Nullable)args {
  // Precache shared map services, if needed.
  // Retain the shared map services singleton, don't use the result for anything.
  (void)[self sharedMapServices];

  return [[FLTGoogleMapController alloc] initWithFrame:frame
                                        viewIdentifier:viewId
                                             arguments:args
                                             registrar:self.registrar];
}

- (id<NSObject>)sharedMapServices {
  if (_sharedMapServices == nil) {
    // Calling this prepares GMSServices on a background thread controlled
    // by the GoogleMaps framework.
    // Retain the singleton to cache the initialization work across all map views.
    _sharedMapServices = [GMSServices sharedServices];
  }
  return _sharedMapServices;
}

@end

@interface FLTGoogleMapController ()

@property(nonatomic, strong) GMSMapView *mapView;
@property(nonatomic, strong) FlutterMethodChannel *channel;
@property(nonatomic, assign) BOOL trackCameraPosition;
@property(nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;
@property(nonatomic, strong) FLTMarkersController *markersController;
@property(nonatomic, strong) FLTPolygonsController *polygonsController;
@property(nonatomic, strong) FLTPolylinesController *polylinesController;
@property(nonatomic, strong) FLTCirclesController *circlesController;
@property(nonatomic, strong) FLTTileOverlaysController *tileOverlaysController;
@property(nonatomic, strong) MarkerIconPainter *markerIconPainter;
@property(nonatomic, strong) ClusterController *clusterController;
@property(nonatomic, strong) GMUClusterManager *clusterManager;
@property(nonatomic, strong) ClusterRenderer *clusterRenderer;
@property(nonatomic, strong) BClusterManager *bClusterManager;
@property(nonatomic, strong) NSArray<CLLocation*> *navigationPoints;

@end

@implementation FLTGoogleMapController

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
                    registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  GMSCameraPosition *camera =
      [FLTGoogleMapJSONConversions cameraPostionFromDictionary:args[@"initialCameraPosition"]];
  GMSMapView *mapView = [GMSMapView mapWithFrame:frame camera:camera];
  return [self initWithMapView:mapView viewIdentifier:viewId arguments:args registrar:registrar];
}

- (instancetype)initWithMapView:(GMSMapView *_Nonnull)mapView
                 viewIdentifier:(int64_t)viewId
                      arguments:(id _Nullable)args
                      registrar:(NSObject<FlutterPluginRegistrar> *_Nonnull)registrar {
  if (self = [super init]) {
    _mapView = mapView;

    _mapView.accessibilityElementsHidden = NO;
    // TODO(cyanglaz): avoid sending message to self in the middle of the init method.
    // https://github.com/flutter/flutter/issues/104121
    [self interpretMapOptions:args[@"options"]];
    NSString *channelName =
        [NSString stringWithFormat:@"plugins.flutter.dev/google_maps_ios_%lld", viewId];
    _channel = [FlutterMethodChannel methodChannelWithName:channelName
                                           binaryMessenger:registrar.messenger];
    __weak __typeof__(self) weakSelf = self;
    [_channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
      if (weakSelf) {
        [weakSelf onMethodCall:call result:result];
      }
    }];
    _mapView.delegate = weakSelf;
    _mapView.paddingAdjustmentBehavior = kGMSMapViewPaddingAdjustmentBehaviorNever;
    _registrar = registrar;
    _markersController = [[FLTMarkersController alloc] initWithMethodChannel:_channel
                                                                     mapView:_mapView
                                                                   registrar:registrar];
    _polygonsController = [[FLTPolygonsController alloc] init:_channel
                                                      mapView:_mapView
                                                    registrar:registrar];
    _polylinesController = [[FLTPolylinesController alloc] init:_channel
                                                        mapView:_mapView
                                                      registrar:registrar];
    _circlesController = [[FLTCirclesController alloc] init:_channel
                                                    mapView:_mapView
                                                  registrar:registrar];
    _tileOverlaysController = [[FLTTileOverlaysController alloc] init:_channel
                                                              mapView:_mapView
                                                            registrar:registrar];

    _markerIconPainter = [[MarkerIconPainter alloc] init:registrar];

    // begin init ClusterManager and ClusterController
    id<GMUClusterAlgorithm> algorithm = [[BGridBasedClusterAlgorithm alloc] initWithGridSize:50];
    id<GMUClusterIconGenerator> iconGenerator = [[GMUDefaultClusterIconGenerator alloc] init];
    GMUDefaultClusterRenderer* renderer = [[GMUDefaultClusterRenderer alloc] initWithMapView:_mapView clusterIconGenerator:iconGenerator];
    _clusterRenderer = [[ClusterRenderer alloc] initWithMarkerIconPainter:_markerIconPainter];
    renderer.delegate = _clusterRenderer;
    renderer.animatesClusters = NO;
    renderer.animationDuration = 0;
    renderer.minimumClusterSize = 10;

    _clusterManager = [[GMUClusterManager alloc] initWithMap:_mapView algorithm:algorithm renderer:renderer];

    self.clusterController = [[ClusterController alloc] init:_channel
                                                mapView:_mapView
                                                registrar:registrar
                                                clusterManager:_clusterManager];

    _bClusterManager = [[BClusterManager alloc] initWithClusterController:self.clusterController];

    [_clusterManager setDelegate:_bClusterManager mapDelegate:self];
    // end init ClusterManager and ClusterController

    id markersToAdd = args[@"markersToAdd"];
    if ([markersToAdd isKindOfClass:[NSArray class]]) {
      [_markersController addMarkers:markersToAdd];
    }
    id polygonsToAdd = args[@"polygonsToAdd"];
    if ([polygonsToAdd isKindOfClass:[NSArray class]]) {
      [_polygonsController addPolygons:polygonsToAdd];
    }
    id polylinesToAdd = args[@"polylinesToAdd"];
    if ([polylinesToAdd isKindOfClass:[NSArray class]]) {
      [_polylinesController addPolylines:polylinesToAdd];
    }
    id circlesToAdd = args[@"circlesToAdd"];
    if ([circlesToAdd isKindOfClass:[NSArray class]]) {
      [_circlesController addCircles:circlesToAdd];
    }
    id tileOverlaysToAdd = args[@"tileOverlaysToAdd"];
    if ([tileOverlaysToAdd isKindOfClass:[NSArray class]]) {
      [_tileOverlaysController addTileOverlays:tileOverlaysToAdd];
    }

    [_mapView addObserver:self forKeyPath:@"frame" options:0 context:nil];
  }
  return self;
}

- (UIView *)view {
  return self.mapView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (object == self.mapView && [keyPath isEqualToString:@"frame"]) {
    CGRect bounds = self.mapView.bounds;
    if (CGRectEqualToRect(bounds, CGRectZero)) {
      // The workaround is to fix an issue that the camera location is not current when
      // the size of the map is zero at initialization.
      // So We only care about the size of the `self.mapView`, ignore the frame changes when the
      // size is zero.
      return;
    }
    // We only observe the frame for initial setup.
    [self.mapView removeObserver:self forKeyPath:@"frame"];
    [self.mapView moveCamera:[GMSCameraUpdate setCamera:self.mapView.camera]];
    [_channel invokeMethod:@"map#ready" arguments:@{}];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (BOOL)onMethodCallVelodashCustom:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"map#initNavigationPolyline"]) {
        self.navigationPoints = [FLTGoogleMapJSONConversions pointsFromLatLongs:call.arguments[@"points"]];

        [self.polylinesController removePolylineWithIdentifiers:@[@"remainingPolyline"]];
        [self.polylinesController addPolylines:@[call.arguments[@"skippedPolyline"], call.arguments[@"remainingPolyline"]]];

        FLTGoogleMapPolylineController *controller = [_polylinesController getGoogleMapPolylineController: @"remainingPolyline"];

        GMSMutablePath* path = [GMSMutablePath path];

        for (CLLocation* location in self.navigationPoints) {
          [path addCoordinate:location.coordinate];
        }

        [controller.polyline setPath:path];

        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#updateNavigationIndex"]) {
        int index = [call.arguments[@"index"] intValue];

        if (index >= 0 && index < self.navigationPoints.count) {
            id _point = call.arguments[@"point"];
            CLLocation *point = [_point isEqual:[NSNull null]] ? nil : [FLTGoogleMapJSONConversions pointsFromLatLongs:@[_point]].firstObject;

            GMSPolyline* skippedPolyline = [_polylinesController getGoogleMapPolylineController: @"skippedPolyline"].polyline;
            GMSPolyline* remainingPolyline = [_polylinesController getGoogleMapPolylineController: @"remainingPolyline"].polyline;

            NSRange skippedRange = NSMakeRange(0, index + 1);

            GMSMutablePath* skippedPath = [GMSMutablePath path];
            for (CLLocation* location in [self.navigationPoints subarrayWithRange:skippedRange]) {
              [skippedPath addCoordinate:location.coordinate];
            }

            if (point) {
                [skippedPath addCoordinate:point.coordinate];
            }

            [skippedPolyline setPath:skippedPath];

            NSRange remainingRange = NSMakeRange(index, self.navigationPoints.count - index);

            GMSMutablePath* remainingPath = [GMSMutablePath path];
            for (CLLocation* location in [self.navigationPoints subarrayWithRange:remainingRange]) {
              [remainingPath addCoordinate:location.coordinate];
            }

            if (point) {
                [remainingPath replaceCoordinateAtIndex:0 withCoordinate:point.coordinate];
            }

            [remainingPolyline setPath:remainingPath];
        }

        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#initPolyline"]) {
        NSArray *idsToRemove = @[call.arguments[@"polylineId"]];
        [_polylinesController removePolylineWithIdentifiers:idsToRemove];

        id polyline = call.arguments;
        [_polylinesController addPolylines:@[polyline]];

        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#appendPolylinePoints"]) {
        NSString *polylineId = call.arguments[@"polylineId"];
        FLTGoogleMapPolylineController *controller = [_polylinesController getGoogleMapPolylineController: polylineId];

        GMSMutablePath* path = [[GMSMutablePath alloc] initWithPath: controller.path];

        NSArray<CLLocation*> *points = [FLTGoogleMapJSONConversions pointsFromLatLongs:call.arguments[@"points"]];

        for (CLLocation* location in points) {
            [path addCoordinate:location.coordinate];
        }

        [controller setPath:path];

        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#initMarker"]) {
        id markersToAdd = call.arguments[@"markers"];
        if ([markersToAdd isKindOfClass:[NSArray class]]) {
          [self.markersController addMarkers:markersToAdd];
        }
        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#updateMarker"]) {
        id markersToChange = call.arguments[@"markers"];
        if ([markersToChange isKindOfClass:[NSArray class]]) {
          [self.markersController changeMarkers:markersToChange];
        }
        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#updateDynamicMarkers"]) {
        TICK(updateRiderExecuteTime);
        id markersToUpdate = call.arguments[@"markers"];
        NSMutableArray* markersToChange = [[NSMutableArray alloc] init];
        NSMutableArray* markersToAdd = [[NSMutableArray alloc] init];
        NSMutableArray* clusterMarkers = [[NSMutableArray alloc] init];
        NSMutableArray* removeFromCluster = [[NSMutableArray alloc] init];
        NSMutableArray* removeFromMarkerManager = [[NSMutableArray alloc] init];

        for (NSMutableDictionary* dict in markersToUpdate) {
            BOOL clusterable = [dict[@"clusterable"] boolValue];
            NSString* markerId = dict[@"markerId"];
            if (clusterable) {
                [clusterMarkers addObject:dict];
                if ([self.markersController checkIfMarkerExists:markerId]) {
                    [removeFromMarkerManager addObject:markerId];
                }
            } else {
                NSMutableDictionary* extra = dict[@"extra"];
                if ([self.clusterController checkIfMarkerExists:markerId]) {
                    [removeFromCluster addObject:markerId];
                }
                if ([extra count] == 0) {
                    [dict removeObjectForKey:@"icon"];
                    [markersToChange addObject:dict];
                } else {
                    NSString* path = extra[@"path"];
                    NSString* name = extra[@"name"];
                    NSNumber* rideStatus = extra[@"rideStatus"];
                    if (!rideStatus) rideStatus = [NSNumber numberWithInt:0];
                    NSNumber* ratio = extra[@"ratio"];
                    if (!ratio) ratio = [NSNumber numberWithFloat:1.0];
                    BOOL highlight = [extra[@"highlight"] boolValue];
                    if (!highlight) highlight = NO;
                    UIImage* image = [_markerIconPainter getRiderAvatar:path name:name status:rideStatus.intValue ratio:ratio highlight:highlight];
                    NSMutableArray* icon = [[NSMutableArray alloc] init];
                    [icon addObject:@"fromUIImage"];
                    [icon addObject:image];
                    [dict setValue:icon forKey:@"icon"];
                    if([self.markersController checkIfMarkerExists:markerId]) {
                        [markersToChange addObject:dict];
                    } else {
                        [markersToAdd addObject:dict];
                    }
                }

            }
        }
        TOCK(updateRiderExecuteTime);
        [self.markersController addMarkers:markersToAdd];
        [self.markersController changeMarkers:markersToChange];
        [self.clusterController addOrUpdateMarkers:clusterMarkers];
        [self.markersController removeMarkersWithIdentifiers:removeFromMarkerManager];
        [self.clusterController removeMarker:removeFromCluster];

        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#removeMarkers"]) {
        id markerIdsToRemove = call.arguments[@"markerIds"];
        if ([markerIdsToRemove isKindOfClass:[NSArray class]]) {
          [self.markersController removeMarkersWithIdentifiers:markerIdsToRemove];
          [self.clusterController removeMarker:markerIdsToRemove];
        }
        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#setPadding"]) {
        double top = [call.arguments[@"top"] doubleValue];
        double left = [call.arguments[@"left"] doubleValue];
        double bottom = [call.arguments[@"bottom"] doubleValue];
        double right = [call.arguments[@"right"] doubleValue];
        [self setPaddingTop:top left:left bottom:bottom right:right];
        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#cluster"]) {
        [_clusterManager cluster];
        result(nil);
        return true;
    } else if ([call.method isEqualToString:@"map#setClusterMarkerStyle"]) {
        NSDictionary* background = call.arguments[@"background"];
        NSDictionary* font = call.arguments[@"font"];
        NSNumber* br = background[@"r"];
        NSNumber* bg = background[@"g"];
        NSNumber* bb = background[@"b"];
        NSNumber* ba = background[@"a"];
        if (!br) br = [NSNumber numberWithInt:8];
        if (!bg) bg = [NSNumber numberWithInt:27];
        if (!bb) bb = [NSNumber numberWithInt:51];
        if (!ba) ba = [NSNumber numberWithInt:153];
        NSNumber* fr = font[@"r"];
        NSNumber* fg = font[@"g"];
        NSNumber* fb = font[@"b"];
        NSNumber* fa = font[@"a"];
        if (!fr) fr = [NSNumber numberWithInt:255];
        if (!fg) fg = [NSNumber numberWithInt:255];
        if (!fb) fb = [NSNumber numberWithInt:255];
        if (!fa) fa = [NSNumber numberWithInt:255.0];
        _markerIconPainter.clusterBackgroundColor = [UIColor colorWithRed:br.intValue/255.0f
                                                                    green:bg.intValue/255.0f
                                                                     blue:bb.intValue/255.0f
                                                                    alpha:ba.intValue/255.0f];
        _markerIconPainter.clusterFontColor = [UIColor colorWithRed:fr.intValue/255.0f
                                                              green:fg.intValue/255.0f
                                                               blue:fb.intValue/255.0f
                                                              alpha:fa.intValue/255.0f];
        result(nil);
        return true;
    }

     return false;
}

- (void)onMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([self onMethodCallVelodashCustom:call result:result]) {
    return;
  }

  if ([call.method isEqualToString:@"map#show"]) {
    [self showAtOrigin:CGPointMake([call.arguments[@"x"] doubleValue],
                                   [call.arguments[@"y"] doubleValue])];
    result(nil);
  } else if ([call.method isEqualToString:@"map#hide"]) {
    [self hide];
    result(nil);
  } else if ([call.method isEqualToString:@"camera#animate"]) {

    [self animateWithCameraUpdate:[FLTGoogleMapJSONConversions cameraUpdateFromChannelValue:call.arguments[@"cameraUpdate"]]
                   animationSpeed:[call.arguments[@"animationSpeed"] doubleValue]];
    result(nil);
  } else if ([call.method isEqualToString:@"camera#move"]) {
    [self moveWithCameraUpdate:[FLTGoogleMapJSONConversions
                                   cameraUpdateFromChannelValue:call.arguments[@"cameraUpdate"]]];
    result(nil);
  } else if ([call.method isEqualToString:@"map#update"]) {
    [self interpretMapOptions:call.arguments[@"options"]];
    result([FLTGoogleMapJSONConversions dictionaryFromPosition:[self cameraPosition]]);
  } else if ([call.method isEqualToString:@"map#getVisibleRegion"]) {
    if (self.mapView != nil) {
      GMSVisibleRegion visibleRegion = self.mapView.projection.visibleRegion;
      GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithRegion:visibleRegion];
      result([FLTGoogleMapJSONConversions dictionaryFromCoordinateBounds:bounds]);
    } else {
      result([FlutterError errorWithCode:@"GoogleMap uninitialized"
                                 message:@"getVisibleRegion called prior to map initialization"
                                 details:nil]);
    }
  } else if ([call.method isEqualToString:@"map#getScreenCoordinate"]) {
    if (self.mapView != nil) {
      CLLocationCoordinate2D location =
          [FLTGoogleMapJSONConversions locationFromLatLong:call.arguments];
      CGPoint point = [self.mapView.projection pointForCoordinate:location];
      result([FLTGoogleMapJSONConversions dictionaryFromPoint:point]);
    } else {
      result([FlutterError errorWithCode:@"GoogleMap uninitialized"
                                 message:@"getScreenCoordinate called prior to map initialization"
                                 details:nil]);
    }
  } else if ([call.method isEqualToString:@"map#getLatLng"]) {
    if (self.mapView != nil && call.arguments) {
      CGPoint point = [FLTGoogleMapJSONConversions pointFromDictionary:call.arguments];
      CLLocationCoordinate2D latlng = [self.mapView.projection coordinateForPoint:point];
      result([FLTGoogleMapJSONConversions arrayFromLocation:latlng]);
    } else {
      result([FlutterError errorWithCode:@"GoogleMap uninitialized"
                                 message:@"getLatLng called prior to map initialization"
                                 details:nil]);
    }
  } else if ([call.method isEqualToString:@"map#waitForMap"]) {
    result(nil);
  } else if ([call.method isEqualToString:@"map#takeSnapshot"]) {
    if (@available(iOS 10.0, *)) {
      if (self.mapView != nil) {
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.scale = [[UIScreen mainScreen] scale];
        UIGraphicsImageRenderer *renderer =
            [[UIGraphicsImageRenderer alloc] initWithSize:self.mapView.frame.size format:format];

        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
          [self.mapView.layer renderInContext:context.CGContext];
        }];
        result([FlutterStandardTypedData typedDataWithBytes:UIImagePNGRepresentation(image)]);
      } else {
        result([FlutterError errorWithCode:@"GoogleMap uninitialized"
                                   message:@"takeSnapshot called prior to map initialization"
                                   details:nil]);
      }
    } else {
      NSLog(@"Taking snapshots is not supported for Flutter Google Maps prior to iOS 10.");
      result(nil);
    }
  } else if ([call.method isEqualToString:@"markers#update"]) {
    id markersToAdd = call.arguments[@"markersToAdd"];
    if ([markersToAdd isKindOfClass:[NSArray class]]) {
      [self.markersController addMarkers:markersToAdd];
    }
    id markersToChange = call.arguments[@"markersToChange"];
    if ([markersToChange isKindOfClass:[NSArray class]]) {
      [self.markersController changeMarkers:markersToChange];
    }
    id markerIdsToRemove = call.arguments[@"markerIdsToRemove"];
    if ([markerIdsToRemove isKindOfClass:[NSArray class]]) {
      [self.markersController removeMarkersWithIdentifiers:markerIdsToRemove];
    }
    result(nil);
  } else if ([call.method isEqualToString:@"markers#showInfoWindow"]) {
    id markerId = call.arguments[@"markerId"];
    if ([markerId isKindOfClass:[NSString class]]) {
      [self.markersController showMarkerInfoWindowWithIdentifier:markerId result:result];
    } else {
      result([FlutterError errorWithCode:@"Invalid markerId"
                                 message:@"showInfoWindow called with invalid markerId"
                                 details:nil]);
    }
  } else if ([call.method isEqualToString:@"markers#hideInfoWindow"]) {
    id markerId = call.arguments[@"markerId"];
    if ([markerId isKindOfClass:[NSString class]]) {
      [self.markersController hideMarkerInfoWindowWithIdentifier:markerId result:result];
    } else {
      result([FlutterError errorWithCode:@"Invalid markerId"
                                 message:@"hideInfoWindow called with invalid markerId"
                                 details:nil]);
    }
  } else if ([call.method isEqualToString:@"markers#isInfoWindowShown"]) {
    id markerId = call.arguments[@"markerId"];
    if ([markerId isKindOfClass:[NSString class]]) {
      [self.markersController isInfoWindowShownForMarkerWithIdentifier:markerId result:result];
    } else {
      result([FlutterError errorWithCode:@"Invalid markerId"
                                 message:@"isInfoWindowShown called with invalid markerId"
                                 details:nil]);
    }
  } else if ([call.method isEqualToString:@"polygons#update"]) {
    id polygonsToAdd = call.arguments[@"polygonsToAdd"];
    if ([polygonsToAdd isKindOfClass:[NSArray class]]) {
      [self.polygonsController addPolygons:polygonsToAdd];
    }
    id polygonsToChange = call.arguments[@"polygonsToChange"];
    if ([polygonsToChange isKindOfClass:[NSArray class]]) {
      [self.polygonsController changePolygons:polygonsToChange];
    }
    id polygonIdsToRemove = call.arguments[@"polygonIdsToRemove"];
    if ([polygonIdsToRemove isKindOfClass:[NSArray class]]) {
      [self.polygonsController removePolygonWithIdentifiers:polygonIdsToRemove];
    }
    result(nil);
  } else if ([call.method isEqualToString:@"polylines#update"]) {
    id polylinesToAdd = call.arguments[@"polylinesToAdd"];
    if ([polylinesToAdd isKindOfClass:[NSArray class]]) {
      [self.polylinesController addPolylines:polylinesToAdd];
    }
    id polylinesToChange = call.arguments[@"polylinesToChange"];
    if ([polylinesToChange isKindOfClass:[NSArray class]]) {
      [self.polylinesController changePolylines:polylinesToChange];
    }
    id polylineIdsToRemove = call.arguments[@"polylineIdsToRemove"];
    if ([polylineIdsToRemove isKindOfClass:[NSArray class]]) {
      [self.polylinesController removePolylineWithIdentifiers:polylineIdsToRemove];
    }
    result(nil);
  } else if ([call.method isEqualToString:@"circles#update"]) {
    id circlesToAdd = call.arguments[@"circlesToAdd"];
    if ([circlesToAdd isKindOfClass:[NSArray class]]) {
      [self.circlesController addCircles:circlesToAdd];
    }
    id circlesToChange = call.arguments[@"circlesToChange"];
    if ([circlesToChange isKindOfClass:[NSArray class]]) {
      [self.circlesController changeCircles:circlesToChange];
    }
    id circleIdsToRemove = call.arguments[@"circleIdsToRemove"];
    if ([circleIdsToRemove isKindOfClass:[NSArray class]]) {
      [self.circlesController removeCircleWithIdentifiers:circleIdsToRemove];
    }
    result(nil);
  } else if ([call.method isEqualToString:@"tileOverlays#update"]) {
    id tileOverlaysToAdd = call.arguments[@"tileOverlaysToAdd"];
    if ([tileOverlaysToAdd isKindOfClass:[NSArray class]]) {
      [self.tileOverlaysController addTileOverlays:tileOverlaysToAdd];
    }
    id tileOverlaysToChange = call.arguments[@"tileOverlaysToChange"];
    if ([tileOverlaysToChange isKindOfClass:[NSArray class]]) {
      [self.tileOverlaysController changeTileOverlays:tileOverlaysToChange];
    }
    id tileOverlayIdsToRemove = call.arguments[@"tileOverlayIdsToRemove"];
    if ([tileOverlayIdsToRemove isKindOfClass:[NSArray class]]) {
      [self.tileOverlaysController removeTileOverlayWithIdentifiers:tileOverlayIdsToRemove];
    }
    result(nil);
  } else if ([call.method isEqualToString:@"tileOverlays#clearTileCache"]) {
    id rawTileOverlayId = call.arguments[@"tileOverlayId"];
    [self.tileOverlaysController clearTileCacheWithIdentifier:rawTileOverlayId];
    result(nil);
  } else if ([call.method isEqualToString:@"map#isCompassEnabled"]) {
    NSNumber *isCompassEnabled = @(self.mapView.settings.compassButton);
    result(isCompassEnabled);
  } else if ([call.method isEqualToString:@"map#isMapToolbarEnabled"]) {
    NSNumber *isMapToolbarEnabled = @NO;
    result(isMapToolbarEnabled);
  } else if ([call.method isEqualToString:@"map#getMinMaxZoomLevels"]) {
    NSArray *zoomLevels = @[ @(self.mapView.minZoom), @(self.mapView.maxZoom) ];
    result(zoomLevels);
  } else if ([call.method isEqualToString:@"map#getZoomLevel"]) {
    result(@(self.mapView.camera.zoom));
  } else if ([call.method isEqualToString:@"map#isZoomGesturesEnabled"]) {
    NSNumber *isZoomGesturesEnabled = @(self.mapView.settings.zoomGestures);
    result(isZoomGesturesEnabled);
  } else if ([call.method isEqualToString:@"map#isZoomControlsEnabled"]) {
    NSNumber *isZoomControlsEnabled = @NO;
    result(isZoomControlsEnabled);
  } else if ([call.method isEqualToString:@"map#isTiltGesturesEnabled"]) {
    NSNumber *isTiltGesturesEnabled = @(self.mapView.settings.tiltGestures);
    result(isTiltGesturesEnabled);
  } else if ([call.method isEqualToString:@"map#isRotateGesturesEnabled"]) {
    NSNumber *isRotateGesturesEnabled = @(self.mapView.settings.rotateGestures);
    result(isRotateGesturesEnabled);
  } else if ([call.method isEqualToString:@"map#isScrollGesturesEnabled"]) {
    NSNumber *isScrollGesturesEnabled = @(self.mapView.settings.scrollGestures);
    result(isScrollGesturesEnabled);
  } else if ([call.method isEqualToString:@"map#isMyLocationButtonEnabled"]) {
    NSNumber *isMyLocationButtonEnabled = @(self.mapView.settings.myLocationButton);
    result(isMyLocationButtonEnabled);
  } else if ([call.method isEqualToString:@"map#isTrafficEnabled"]) {
    NSNumber *isTrafficEnabled = @(self.mapView.trafficEnabled);
    result(isTrafficEnabled);
  } else if ([call.method isEqualToString:@"map#isBuildingsEnabled"]) {
    NSNumber *isBuildingsEnabled = @(self.mapView.buildingsEnabled);
    result(isBuildingsEnabled);
  } else if ([call.method isEqualToString:@"map#setStyle"]) {
    NSString *mapStyle = [call arguments];
    NSString *error = [self setMapStyle:mapStyle];
    if (error == nil) {
      result(@[ @(YES) ]);
    } else {
      result(@[ @(NO), error ]);
    }
  } else if ([call.method isEqualToString:@"map#getTileOverlayInfo"]) {
    NSString *rawTileOverlayId = call.arguments[@"tileOverlayId"];
    result([self.tileOverlaysController tileOverlayInfoWithIdentifier:rawTileOverlayId]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)showAtOrigin:(CGPoint)origin {
  CGRect frame = {origin, self.mapView.frame.size};
  self.mapView.frame = frame;
  self.mapView.hidden = NO;
}

- (void)hide {
  self.mapView.hidden = YES;
}

- (void)animateWithCameraUpdate:(GMSCameraUpdate*)cameraUpdate animationSpeed: (double)animationSpeed {
  [CATransaction begin];
  [CATransaction setAnimationTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
  [CATransaction setCompletionBlock: ^ {
      [self delayNotifingAnimationCompleted];
  }];
  [CATransaction setAnimationDuration: (animationSpeed) / 1000];
  [_mapView animateWithCameraUpdate:cameraUpdate];
  [CATransaction commit];
}

- (void)moveWithCameraUpdate:(GMSCameraUpdate *)cameraUpdate {
  [self.mapView moveCamera:cameraUpdate];
}

- (GMSCameraPosition *)cameraPosition {
  if (self.trackCameraPosition) {
    return self.mapView.camera;
  } else {
    return nil;
  }
}

- (void)setCamera:(GMSCameraPosition *)camera {
  self.mapView.camera = camera;
}

- (void)setCameraTargetBounds:(GMSCoordinateBounds *)bounds {
  self.mapView.cameraTargetBounds = bounds;
}

- (void)setCompassEnabled:(BOOL)enabled {
  self.mapView.settings.compassButton = enabled;
}

- (void)setIndoorEnabled:(BOOL)enabled {
  self.mapView.indoorEnabled = enabled;
}

- (void)setTrafficEnabled:(BOOL)enabled {
  self.mapView.trafficEnabled = enabled;
}

- (void)setBuildingsEnabled:(BOOL)enabled {
  self.mapView.buildingsEnabled = enabled;
}

- (void)setMapType:(GMSMapViewType)mapType {
  self.mapView.mapType = mapType;
}

- (void)setMinZoom:(float)minZoom maxZoom:(float)maxZoom {
  [self.mapView setMinZoom:minZoom maxZoom:maxZoom];
}

- (void)setPaddingTop:(float)top left:(float)left bottom:(float)bottom right:(float)right {
  self.mapView.padding = UIEdgeInsetsMake(top, left, bottom, right);
}

- (void)setRotateGesturesEnabled:(BOOL)enabled {
  self.mapView.settings.rotateGestures = enabled;
}

- (void)setScrollGesturesEnabled:(BOOL)enabled {
  self.mapView.settings.scrollGestures = enabled;
}

- (void)setTiltGesturesEnabled:(BOOL)enabled {
  self.mapView.settings.tiltGestures = enabled;
}

- (void)setTrackCameraPosition:(BOOL)enabled {
  _trackCameraPosition = enabled;
}

- (void)setZoomGesturesEnabled:(BOOL)enabled {
  self.mapView.settings.zoomGestures = enabled;
}

- (void)setMyLocationEnabled:(BOOL)enabled {
  self.mapView.myLocationEnabled = enabled;
}

- (void)setMyLocationButtonEnabled:(BOOL)enabled {
  self.mapView.settings.myLocationButton = enabled;
}

- (NSString *)setMapStyle:(NSString *)mapStyle {
  if (mapStyle == (id)[NSNull null] || mapStyle.length == 0) {
    self.mapView.mapStyle = nil;
    return nil;
  }
  NSError *error;
  GMSMapStyle *style = [GMSMapStyle styleWithJSONString:mapStyle error:&error];
  if (!style) {
    return [error localizedDescription];
  } else {
    self.mapView.mapStyle = style;
    return nil;
  }
}

#pragma mark - GMSMapViewDelegate methods

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
  [self.channel invokeMethod:@"camera#onMoveStarted" arguments:@{@"isGesture" : @(gesture)}];
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
  if (self.trackCameraPosition) {
    if (delayNotifingAnimationCompletedTask) {
      [self delayNotifingAnimationCompleted];
    }
    [self.channel invokeMethod:@"camera#onMove"
                     arguments:@{
                       @"position" : [FLTGoogleMapJSONConversions dictionaryFromPosition:position]
                     }];
  }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
  [self.channel invokeMethod:@"camera#onIdle" arguments:@{}];
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
  NSString *markerId = marker.userData[0];
  return [self.markersController didTapMarkerWithIdentifier:markerId];
}

- (void)mapView:(GMSMapView *)mapView didEndDraggingMarker:(GMSMarker *)marker {
  NSString *markerId = marker.userData[0];
  [self.markersController didEndDraggingMarkerWithIdentifier:markerId location:marker.position];
}

- (void)mapView:(GMSMapView *)mapView didStartDraggingMarker:(GMSMarker *)marker {
  NSString *markerId = marker.userData[0];
  [self.markersController didStartDraggingMarkerWithIdentifier:markerId location:marker.position];
}

- (void)mapView:(GMSMapView *)mapView didDragMarker:(GMSMarker *)marker {
  NSString *markerId = marker.userData[0];
  [self.markersController didDragMarkerWithIdentifier:markerId location:marker.position];
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
  NSString *markerId = marker.userData[0];
  [self.markersController didTapInfoWindowOfMarkerWithIdentifier:markerId];
}
- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay {
  NSString *overlayId = overlay.userData[0];
  if ([self.polylinesController hasPolylineWithIdentifier:overlayId]) {
    [self.polylinesController didTapPolylineWithIdentifier:overlayId];
  } else if ([self.polygonsController hasPolygonWithIdentifier:overlayId]) {
    [self.polygonsController didTapPolygonWithIdentifier:overlayId];
  } else if ([self.circlesController hasCircleWithIdentifier:overlayId]) {
    [self.circlesController didTapCircleWithIdentifier:overlayId];
  }
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
  [self.channel
      invokeMethod:@"map#onTap"
         arguments:@{@"position" : [FLTGoogleMapJSONConversions arrayFromLocation:coordinate]}];
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
  [self.channel
      invokeMethod:@"map#onLongPress"
         arguments:@{@"position" : [FLTGoogleMapJSONConversions arrayFromLocation:coordinate]}];
}

- (void)interpretMapOptions:(NSDictionary *)data {
  NSArray *cameraTargetBounds = data[@"cameraTargetBounds"];
  if (cameraTargetBounds && cameraTargetBounds != (id)[NSNull null]) {
    [self
        setCameraTargetBounds:cameraTargetBounds.count > 0 && cameraTargetBounds[0] != [NSNull null]
                                  ? [FLTGoogleMapJSONConversions
                                        coordinateBoundsFromLatLongs:cameraTargetBounds.firstObject]
                                  : nil];
  }
  NSNumber *compassEnabled = data[@"compassEnabled"];
  if (compassEnabled && compassEnabled != (id)[NSNull null]) {
    [self setCompassEnabled:[compassEnabled boolValue]];
  }
  id indoorEnabled = data[@"indoorEnabled"];
  if (indoorEnabled && indoorEnabled != [NSNull null]) {
    [self setIndoorEnabled:[indoorEnabled boolValue]];
  }
  id trafficEnabled = data[@"trafficEnabled"];
  if (trafficEnabled && trafficEnabled != [NSNull null]) {
    [self setTrafficEnabled:[trafficEnabled boolValue]];
  }
  id buildingsEnabled = data[@"buildingsEnabled"];
  if (buildingsEnabled && buildingsEnabled != [NSNull null]) {
    [self setBuildingsEnabled:[buildingsEnabled boolValue]];
  }
  id mapType = data[@"mapType"];
  if (mapType && mapType != [NSNull null]) {
    [self setMapType:[FLTGoogleMapJSONConversions mapViewTypeFromTypeValue:mapType]];
  }
  NSArray *zoomData = data[@"minMaxZoomPreference"];
  if (zoomData && zoomData != (id)[NSNull null]) {
    float minZoom = (zoomData[0] == [NSNull null]) ? kGMSMinZoomLevel : [zoomData[0] floatValue];
    float maxZoom = (zoomData[1] == [NSNull null]) ? kGMSMaxZoomLevel : [zoomData[1] floatValue];
    [self setMinZoom:minZoom maxZoom:maxZoom];
  }
  NSArray *paddingData = data[@"padding"];
  if (paddingData) {
    float top = (paddingData[0] == [NSNull null]) ? 0 : [paddingData[0] floatValue];
    float left = (paddingData[1] == [NSNull null]) ? 0 : [paddingData[1] floatValue];
    float bottom = (paddingData[2] == [NSNull null]) ? 0 : [paddingData[2] floatValue];
    float right = (paddingData[3] == [NSNull null]) ? 0 : [paddingData[3] floatValue];
    [self setPaddingTop:top left:left bottom:bottom right:right];
  }

  NSNumber *rotateGesturesEnabled = data[@"rotateGesturesEnabled"];
  if (rotateGesturesEnabled && rotateGesturesEnabled != (id)[NSNull null]) {
    [self setRotateGesturesEnabled:[rotateGesturesEnabled boolValue]];
  }
  NSNumber *scrollGesturesEnabled = data[@"scrollGesturesEnabled"];
  if (scrollGesturesEnabled && scrollGesturesEnabled != (id)[NSNull null]) {
    [self setScrollGesturesEnabled:[scrollGesturesEnabled boolValue]];
  }
  NSNumber *tiltGesturesEnabled = data[@"tiltGesturesEnabled"];
  if (tiltGesturesEnabled && tiltGesturesEnabled != (id)[NSNull null]) {
    [self setTiltGesturesEnabled:[tiltGesturesEnabled boolValue]];
  }
  NSNumber *trackCameraPosition = data[@"trackCameraPosition"];
  if (trackCameraPosition && trackCameraPosition != (id)[NSNull null]) {
    [self setTrackCameraPosition:[trackCameraPosition boolValue]];
  }
  NSNumber *zoomGesturesEnabled = data[@"zoomGesturesEnabled"];
  if (zoomGesturesEnabled && zoomGesturesEnabled != (id)[NSNull null]) {
    [self setZoomGesturesEnabled:[zoomGesturesEnabled boolValue]];
  }
  NSNumber *myLocationEnabled = data[@"myLocationEnabled"];
  if (myLocationEnabled && myLocationEnabled != (id)[NSNull null]) {
    [self setMyLocationEnabled:[myLocationEnabled boolValue]];
  }
  NSNumber *myLocationButtonEnabled = data[@"myLocationButtonEnabled"];
  if (myLocationButtonEnabled && myLocationButtonEnabled != (id)[NSNull null]) {
    [self setMyLocationButtonEnabled:[myLocationButtonEnabled boolValue]];
  }
}

- (void)mapView:(GMSMapView *)mapView didTapPOIWithPlaceID:(NSString *)placeID name:(NSString *)name location:(CLLocationCoordinate2D)location {
  [_channel invokeMethod:@"map#onTap" arguments:@{@"position" : [FLTGoogleMapJSONConversions arrayFromLocation:location]}];
}

// Fix issue: still get onMove after onAnimationCompleted on iOS.
- (void)delayNotifingAnimationCompleted {
    if (delayNotifingAnimationCompletedTask) {
        dispatch_block_cancel(delayNotifingAnimationCompletedTask);
    }

    delayNotifingAnimationCompletedTask = dispatch_block_create(0, ^{
        [self->_channel invokeMethod:@"camera#animationCompleted" arguments:@{}];
        delayNotifingAnimationCompletedTask = nil;
    });

    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), delayNotifingAnimationCompletedTask);
}

@end
