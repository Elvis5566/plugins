//
//  ClusterRenderer.h
//  google_maps_flutter
//
//  Created by boris on 2021/3/29.
//

#ifndef ClusterRenderer_h
#define ClusterRenderer_h

#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>
#import "GoogleMapController.h"
#import "MarkerIconPainter.h"
#import "ClusterController.h"

@import GoogleMapsUtils;

@interface ClusterRenderer : NSObject<GMUClusterRendererDelegate>
- (instancetype)initWithMarkerIconPainter:(MarkerIconPainter*) painter;
@end

#endif /* ClusterRenderer_h */
