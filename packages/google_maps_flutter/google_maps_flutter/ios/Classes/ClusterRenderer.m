//
//  ClusterRendered.m
//  google_maps_flutter
//
//  Created by boris on 2021/3/26.
//

#import "ClusterRenderer.h"

@implementation ClusterRenderer {
    MarkerIconPainter* _markerIconPainter;
    NSArray<NSNumber *> *_buckets;
}

- (instancetype)initWithMarkerIconPainter:(MarkerIconPainter*) painter
{
    self = [super init];
    if (self) {
        _markerIconPainter = painter;
        _buckets = @[@10, @20, @30, @40, @50, @100, @200, @500, @1000];
    }
    return self;
}

- (int)bucketIndexForSize:(int)size {
  int index = 0;
  while (index + 1 < _buckets.count && _buckets[index + 1].unsignedLongValue <= size) {
    ++index;
  }
  return index;
}

- (void)renderer:(id<GMUClusterRenderer>)renderer willRenderMarker:(GMSMarker *)marker {
    if ([marker.userData conformsToProtocol:@protocol(GMUCluster)]) {
        id<GMUCluster> userData = marker.userData;
        int count = (int)userData.count;
        marker.icon = [_markerIconPainter getUIImageFromCluster: count > 10 ? _buckets[[self bucketIndexForSize:count]].intValue : count];
        marker.zIndex = 700;
    } else if ([marker.userData conformsToProtocol:@protocol(GMUClusterItem)]) {
        BClusterItem* typedData = (BClusterItem*)marker.userData;
        marker.position = typedData.position;
        marker.draggable = typedData.draggable;
        marker.flat = typedData.flat;
        marker.icon = [_markerIconPainter getRiderAvatar:typedData.path name:typedData.name status:typedData.status ratio:typedData.ratio];
        marker.opacity = typedData.alpha;
        marker.groundAnchor = typedData.anchor;
        marker.rotation = typedData.rotation;
        marker.zIndex = typedData.zIndex;
    }
}

@end
