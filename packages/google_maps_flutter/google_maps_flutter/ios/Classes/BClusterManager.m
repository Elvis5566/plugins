//
//  BClusterManager.m
//  google_maps_flutter
//
//  Created by boris on 2021/3/29.
//

#import <Foundation/Foundation.h>
#import "BClusterManager.h"

@implementation BClusterManager {
    ClusterController* _controller;
}

- (instancetype)initWithClusterController:(id)controller {
    if ((self = [super init])) {
        _controller = controller;
    }
    return self;
}

- (BOOL)clusterManager:(GMUClusterManager *)clusterManager didTapCluster:(id<GMUCluster>)cluster {
    [_controller moveCamera:cluster.position level:1.0f];
    return YES;
}

- (BOOL)clusterManager:(GMUClusterManager *)clusterManager didTapClusterItem:(id<GMUClusterItem>)clusterItem {
    if ([clusterItem isKindOfClass:[BClusterItem class]]) {
        NSString* markerId = ((BClusterItem*)clusterItem).markerId;
        [_controller onMarkerTap:markerId];
        return YES;
    }
    return NO;
}

@end

