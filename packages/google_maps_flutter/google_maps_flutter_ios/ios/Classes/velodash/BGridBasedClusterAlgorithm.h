//
//  BGridBasedClusterAlgorithm.h
//  google_maps_flutter
//
//  Created by boris on 2021/3/29.
//

#ifndef BGridBasedClusterAlgorithm_h
#define BGridBasedClusterAlgorithm_h

@import GoogleMapsUtils;

@interface BGridBasedClusterAlgorithm : NSObject<GMUClusterAlgorithm>
- (instancetype)initWithGridSize:(int) gridSize;
@end

#endif /* BGridBasedClusterAlgorithm_h */


