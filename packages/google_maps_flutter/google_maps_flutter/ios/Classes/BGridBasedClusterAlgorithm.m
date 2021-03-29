//
//  BGridBasedClusterAlgorithm.m
//  google_maps_flutter
//
//  Created by boris on 2021/3/29.
//

#import <Foundation/Foundation.h>

#import "BGridBasedClusterAlgorithm.h"

@implementation BGridBasedClusterAlgorithm {
    NSMutableArray<id<GMUClusterItem>> *_items;
    int _gridSize;
}

- (instancetype)initWithGridSize:(int) gridSize {
    if ((self = [super init])) {
        _items = [[NSMutableArray alloc] init];
        _gridSize = gridSize;
    }
    return self;
}

- (void)addItems:(NSArray<id<GMUClusterItem>> *)items {
  [_items addObjectsFromArray:items];
}

- (void)removeItem:(id<GMUClusterItem>)item {
  [_items removeObject:item];
}

- (void)clearItems {
  [_items removeAllObjects];
}

- (NSArray<id<GMUCluster>> *)clustersAtZoom:(float)zoom {
    NSMutableDictionary<NSNumber *, id<GMUCluster>> *clusters = [[NSMutableDictionary alloc] init];

    // Divide the whole map into a numCells x numCells grid and assign items to them.
    long numCells = (long)ceil(256 * pow(2, zoom) / _gridSize);
    for (id<GMUClusterItem> item in _items) {
      GMSMapPoint point = GMSProject(item.position);
      long col = (long)(numCells * (1.0 + point.x) / 2);  // point.x is in [-1, 1] range
      long row = (long)(numCells * (1.0 + point.y) / 2);  // point.y is in [-1, 1] range
      long index = numCells * row + col;
      NSNumber *cellKey = [NSNumber numberWithLong:index];
      GMUStaticCluster *cluster = clusters[cellKey];
      if (cluster == nil) {
        // Normalize cluster's centroid to center of the cell.
        GMSMapPoint point2 = {(double)(col + 0.5) * 2.0 / numCells - 1,
                              (double)(row + 0.5) * 2.0 / numCells - 1};
        CLLocationCoordinate2D position = GMSUnproject(point2);
        cluster = [[GMUStaticCluster alloc] initWithPosition:position];
        clusters[cellKey] = cluster;
      }
      [cluster addItem:item];
    }
    return [clusters allValues];
}

@end
