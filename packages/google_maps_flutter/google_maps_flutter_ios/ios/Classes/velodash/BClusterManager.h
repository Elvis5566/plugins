//
//  BClusterManager.h
//  google_maps_flutter
//
//  Created by boris on 2021/3/29.
//

#ifndef BClusterManager_h
#define BClusterManager_h

#import "ClusterController.h"

@import GoogleMapsUtils;

@interface BClusterManager : NSObject<GMUClusterManagerDelegate>
- (instancetype) initWithClusterController:(ClusterController*)controller;
@end

#endif /* BClusterManager_h */


