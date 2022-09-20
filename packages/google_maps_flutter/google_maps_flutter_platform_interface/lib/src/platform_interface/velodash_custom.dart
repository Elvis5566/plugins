import 'dart:ui';

import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

mixin VelodashCustom {
  Future<void> updateNavigationIndex(int index, dynamic point, { required int mapId}) {
    throw UnimplementedError('initNavigationPolyline() has not been implemented.');
  }

  Future<void> initNavigationPolyline(List<dynamic> points, {required Polyline skippedPolyline, required Polyline remainingPolyline, required int mapId}) {
    throw UnimplementedError('initNavigationPolyline() has not been implemented.');
  }

  Future<void> initPolyline(Polyline polyline, {required int mapId}) {
    throw UnimplementedError('initPolyline() has not been implemented.');
  }

  Future<void> appendPolylinePoints(PolylineId polylineId, List<dynamic> points, {required int mapId}) {
    throw UnimplementedError('addTrackingPoints() has not been implemented.');
  }

  Future<void> updateDynamicMarkers(Set<Marker> markers, {required int mapId}) {
    throw UnimplementedError('vdUpdateRiderMarkers() has not been implemented.');
  }

  Future<void> vdRemoveMarkers(Set<MarkerId> markerIds, {required int mapId}) {
    throw UnimplementedError('removeMarkers() has not been implemented.');
  }

  Future<void> vdAddSelfMarker(Marker marker, {required int mapId}) {
    throw UnimplementedError('vdAddSelfMarker() has not been implemented.');
  }

  Future<void> vdUpdateSelfMarker(Marker marker, {required int mapId}) {
    throw UnimplementedError('vdUpdateSelfMarker() has not been implemented.');
  }

  Future<void> cluster({required int mapId}) {
    throw UnimplementedError("cluster has not been implemented.");
  }

  Future<void> setClusterMarkerStyle(Color background, Color font, {required int mapId}) {
    throw UnimplementedError("setClusterMarkerStyle has not been implemented.");
  }

  /// Event fired when animate camera is completed
  Stream<AnimateCameraCompletedEvent> animateCameraCompleted({required int mapId}) {
    throw UnimplementedError('animateCameraCompleted() has not been implemented.');
  }

  /// Event fired when map is ready
  Stream<MapReadyEvent> onMapReady({required int mapId}) {
    throw UnimplementedError('onMapReady() has not been implemented.');
  }

  /// set padding to map
  Future<void> setPadding({double top = 0, double left = 0, double bottom = 0, double right = 0, required int mapId}) {
    throw UnimplementedError('setPadding has not been implemented.');
  }
}