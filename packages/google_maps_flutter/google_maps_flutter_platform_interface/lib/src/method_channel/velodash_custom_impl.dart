import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_platform_interface/src/platform_interface/velodash_custom.dart';
import 'package:stream_transform/stream_transform.dart';

mixin VelodashCustomImpl on VelodashCustom {
  StreamController<MapEvent<Object?>> get mapEventStreamController;

  MethodChannel channel(int mapId);

  Stream<MapEvent<Object?>> events(int mapId) =>
      mapEventStreamController.stream
          .where((MapEvent<Object?> event) => event.mapId == mapId);

  bool isMapReady = false;

  bool velodashHandle(MethodCall call, int mapId) {
    switch (call.method) {
      case 'map#ready':
        isMapReady = true;
        mapEventStreamController.add(MapReadyEvent(mapId));
        return true;
      case 'camera#animationCompleted':
        mapEventStreamController.add(AnimateCameraCompletedEvent(mapId));
        return true;
    }

    return false;
  }

  @override
  Future<void> updateNavigationIndex(int index, dynamic point, { required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#updateNavigationIndex', {
      "index": index,
      "point": point,
    });
  }

  @override
  Future<void> initNavigationPolyline(List<dynamic> points, {required Polyline skippedPolyline, required Polyline remainingPolyline, required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#initNavigationPolyline', {
      'points': points,
      'skippedPolyline': skippedPolyline.toJson(),
      'remainingPolyline': remainingPolyline.toJson(),
    });
  }

  @override
  Future<void> initPolyline(Polyline polyline, {required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#initPolyline', polyline.toJson());
  }

  @override
  Future<void> appendPolylinePoints(PolylineId polylineId, List<dynamic> points, {required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#appendPolylinePoints', {
      'polylineId': polylineId.value,
      "points": points,
    });
  }

  Future<void> updateDynamicMarkers(Set<Marker> markers, {required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#updateDynamicMarkers', {
      'markers': serializeMarkerSet(markers),
    });
  }

  Future<void> vdRemoveMarkers(Set<MarkerId> markerIds, {required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#removeMarkers', {
      'markerIds': markerIds.map<dynamic>((MarkerId m) => m.value).toList(),
    });
  }

  Future<void> vdAddSelfMarker(Marker marker, {required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#initMarker', {
      'markers': serializeMarkerSet({marker}),
    });
  }

  Future<void> vdUpdateSelfMarker(Marker marker, {required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#updateMarker', {
      'markers': serializeMarkerSet({marker}),
    });
  }

  Future<void> cluster({required int mapId}) {
    return channel(mapId).invokeMethod<void>("map#cluster");
  }

  Future<void> setClusterMarkerStyle(Color background, Color font, {required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#setClusterMarkerStyle', {
      'background': {
        'a': background.alpha,
        'r': background.red,
        'g': background.green,
        'b': background.blue,
      },
      'font': {
        'r': font.red,
        'g': font.green,
        'b': font.blue,
        'a': font.alpha,
      }
    });
  }

  /// set padding to map
  Future<void> setPadding({double top = 0, double left = 0, double bottom = 0, double right = 0, required int mapId}) {
    return channel(mapId).invokeMethod<void>('map#setPadding', <String, double>{
      'top': top,
      'left': left,
      'bottom': bottom,
      'right': right,
    });
  }

  @override
  Stream<AnimateCameraCompletedEvent> animateCameraCompleted({required int mapId}) {
    return events(mapId).whereType<AnimateCameraCompletedEvent>();
  }

  @override
  Stream<MapReadyEvent> onMapReady({required int mapId}) {
    return isMapReady ? Stream.multi((controller) {
      controller.add(MapReadyEvent(mapId));
    }) : events(mapId).whereType<MapReadyEvent>();
  }
}