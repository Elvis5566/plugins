// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

part of google_maps_flutter;

typedef OnAnimationCompletedCallback = Future<void> Function();

/// Controller for a single GoogleMap instance running on the host platform.
class GoogleMapController {
  GoogleMapController._(
    this._googleMapState, {
    required this.mapId,
  }) {
    _connectStreams(mapId);
  }

  /// The mapId for this controller
  final int mapId;
  final StreamController<MarkerId> _markerOnTapStreamController = StreamController<MarkerId>();
  Stream<MarkerId> get onMarkerTapStream => _markerOnTapStreamController.stream;

  OnAnimationCompletedCallback? _onAnimationCompletedCallback;
  /// Initialize control of a [GoogleMap] with [id].
  ///
  /// Mainly for internal use when instantiating a [GoogleMapController] passed
  /// in [GoogleMap.onMapCreated] callback.
  static Future<GoogleMapController> init(int id,
      CameraPosition initialCameraPosition,
      _GoogleMapState googleMapState,) async {
    assert(id != null);
    await GoogleMapsFlutterPlatform.instance.init(id);
    return GoogleMapController._(
      googleMapState,
      mapId: id,
    );
  }

  final _GoogleMapState _googleMapState;

  final Set<StreamSubscription<dynamic>> _subscriptions = {};

  void _connectStreams(int mapId) {
    if (_googleMapState.widget.onMapReady != null) {
      _subscriptions.add(GoogleMapsFlutterPlatform.instance
          .onMapReady(mapId: mapId)
          .listen((_) {
        _googleMapState.widget.onMapReady?.call();
      }));
    }

    if (_googleMapState.widget.onCameraMoveStarted != null) {
      _subscriptions.add(GoogleMapsFlutterPlatform.instance
          .onCameraMoveStarted(mapId: mapId)
          .listen((_) => _googleMapState.widget.onCameraMoveStarted!()));
    }

    if (_googleMapState.widget.onCameraMove != null) {
      _subscriptions.add(GoogleMapsFlutterPlatform.instance.onCameraMove(mapId: mapId).listen(
              (CameraMoveEvent e) => _googleMapState.widget.onCameraMove!(e.value)));
    }

    if (_googleMapState.widget.onCameraIdle != null) {
      _subscriptions.add(GoogleMapsFlutterPlatform.instance
          .onCameraIdle(mapId: mapId)
          .listen((_) => _googleMapState.widget.onCameraIdle!()));
    }

    _subscriptions.add(GoogleMapsFlutterPlatform.instance
        .onMarkerTap(mapId: mapId)
        .listen((MarkerTapEvent e) {
      try {
        _googleMapState.onMarkerTap(e.value);
      } on UnknownMapObjectIdError {
        // [Fix][Boris] Cannot pass through the marker on tap event. ???
        _markerOnTapStreamController.add(e.value);
      }
    }));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance.onMarkerDragStart(mapId: mapId).listen(
            (MarkerDragStartEvent e) =>
            _googleMapState.onMarkerDragStart(e.value, e.position)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance.onMarkerDrag(mapId: mapId).listen(
            (MarkerDragEvent e) =>
            _googleMapState.onMarkerDrag(e.value, e.position)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance.onMarkerDragEnd(mapId: mapId).listen(
            (MarkerDragEndEvent e) =>
            _googleMapState.onMarkerDragEnd(e.value, e.position)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance.onInfoWindowTap(mapId: mapId).listen(
            (InfoWindowTapEvent e) => _googleMapState.onInfoWindowTap(e.value)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance
        .onPolylineTap(mapId: mapId)
        .listen((PolylineTapEvent e) => _googleMapState.onPolylineTap(e.value)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance
        .onPolygonTap(mapId: mapId)
        .listen((PolygonTapEvent e) => _googleMapState.onPolygonTap(e.value)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance
        .onCircleTap(mapId: mapId)
        .listen((CircleTapEvent e) => _googleMapState.onCircleTap(e.value)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance
        .onTap(mapId: mapId)
        .listen((MapTapEvent e) => _googleMapState.onTap(e.position)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance.onLongPress(mapId: mapId).listen(
            (MapLongPressEvent e) => _googleMapState.onLongPress(e.position)));

    _subscriptions.add(GoogleMapsFlutterPlatform.instance.animateCameraCompleted(mapId: mapId).listen((event) {
      _onAnimationCompletedCallback?.call();
      _onAnimationCompletedCallback = null;
    }));
  }

  /// Updates configuration options of the map user interface.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMapConfiguration(MapConfiguration update) {
    return GoogleMapsFlutterPlatform.instance
        .updateMapConfiguration(update, mapId: mapId);
  }

  /// Updates marker configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMarkers(MarkerUpdates markerUpdates) {
    assert(markerUpdates != null);
    return GoogleMapsFlutterPlatform.instance
        .updateMarkers(markerUpdates, mapId: mapId);
  }

  /// Updates polygon configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolygons(PolygonUpdates polygonUpdates) {
    assert(polygonUpdates != null);
    return GoogleMapsFlutterPlatform.instance
        .updatePolygons(polygonUpdates, mapId: mapId);
  }

  /// Updates polyline configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolylines(PolylineUpdates polylineUpdates) {
    assert(polylineUpdates != null);
    return GoogleMapsFlutterPlatform.instance
        .updatePolylines(polylineUpdates, mapId: mapId);
  }

  /// Updates circle configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateCircles(CircleUpdates circleUpdates) {
    assert(circleUpdates != null);
    return GoogleMapsFlutterPlatform.instance
        .updateCircles(circleUpdates, mapId: mapId);
  }

  /// Updates tile overlays configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateTileOverlays(Set<TileOverlay> newTileOverlays) {
    return GoogleMapsFlutterPlatform.instance
        .updateTileOverlays(newTileOverlays: newTileOverlays, mapId: mapId);
  }

  /// Clears the tile cache so that all tiles will be requested again from the
  /// [TileProvider].
  ///
  /// The current tiles from this tile overlay will also be
  /// cleared from the map after calling this method. The API maintains a small
  /// in-memory cache of tiles. If you want to cache tiles for longer, you
  /// should implement an on-disk cache.
  Future<void> clearTileCache(TileOverlayId tileOverlayId) async {
    assert(tileOverlayId != null);
    return GoogleMapsFlutterPlatform.instance
        .clearTileCache(tileOverlayId, mapId: mapId);
  }

  /// Starts an animated change of the map camera position.
  ///
  /// The returned [Future] completes after the change has been started on the
  /// platform side.
  Future<void> animateCamera(CameraUpdate cameraUpdate, {int animationSpeed = 2000, OnAnimationCompletedCallback? onAnimationCompletedCallback}) {
    _onAnimationCompletedCallback = onAnimationCompletedCallback;
    return GoogleMapsFlutterPlatform.instance.animateCamera(cameraUpdate, mapId: mapId, animationSpeed: animationSpeed);
  }

  /// Changes the map camera position.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> moveCamera(CameraUpdate cameraUpdate) {
    return GoogleMapsFlutterPlatform.instance
        .moveCamera(cameraUpdate, mapId: mapId);
  }

  /// Sets the styling of the base map.
  ///
  /// Set to `null` to clear any previous custom styling.
  ///
  /// If problems were detected with the [mapStyle], including un-parsable
  /// styling JSON, unrecognized feature type, unrecognized element type, or
  /// invalid styler keys: [MapStyleException] is thrown and the current
  /// style is left unchanged.
  ///
  /// The style string can be generated using [map style tool](https://mapstyle.withgoogle.com/).
  /// Also, refer [iOS](https://developers.google.com/maps/documentation/ios-sdk/style-reference)
  /// and [Android](https://developers.google.com/maps/documentation/android-sdk/style-reference)
  /// style reference for more information regarding the supported styles.
  Future<void> setMapStyle(String? mapStyle) {
    return GoogleMapsFlutterPlatform.instance
        .setMapStyle(mapStyle, mapId: mapId);
  }

  /// Return [LatLngBounds] defining the region that is visible in a map.
  Future<LatLngBounds> getVisibleRegion() {
    return GoogleMapsFlutterPlatform.instance.getVisibleRegion(mapId: mapId);
  }

  /// Return [ScreenCoordinate] of the [LatLng] in the current map view.
  ///
  /// A projection is used to translate between on screen location and geographic coordinates.
  /// Screen location is in screen pixels (not display pixels) with respect to the top left corner
  /// of the map, not necessarily of the whole screen.
  Future<ScreenCoordinate> getScreenCoordinate(LatLng latLng) {
    return GoogleMapsFlutterPlatform.instance
        .getScreenCoordinate(latLng, mapId: mapId);
  }

  /// Returns [LatLng] corresponding to the [ScreenCoordinate] in the current map view.
  ///
  /// Returned [LatLng] corresponds to a screen location. The screen location is specified in screen
  /// pixels (not display pixels) relative to the top left of the map, not top left of the whole screen.
  Future<LatLng> getLatLng(ScreenCoordinate screenCoordinate) {
    return GoogleMapsFlutterPlatform.instance
        .getLatLng(screenCoordinate, mapId: mapId);
  }

  /// Programmatically show the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> showMarkerInfoWindow(MarkerId markerId) {
    assert(markerId != null);
    return GoogleMapsFlutterPlatform.instance
        .showMarkerInfoWindow(markerId, mapId: mapId);
  }

  /// Programmatically hide the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> hideMarkerInfoWindow(MarkerId markerId) {
    assert(markerId != null);
    return GoogleMapsFlutterPlatform.instance
        .hideMarkerInfoWindow(markerId, mapId: mapId);
  }

  /// Returns `true` when the [InfoWindow] is showing, `false` otherwise.
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  Future<bool> isMarkerInfoWindowShown(MarkerId markerId) {
    assert(markerId != null);
    return GoogleMapsFlutterPlatform.instance
        .isMarkerInfoWindowShown(markerId, mapId: mapId);
  }

  /// Returns the current zoom level of the map
  Future<double> getZoomLevel() {
    return GoogleMapsFlutterPlatform.instance.getZoomLevel(mapId: mapId);
  }

  /// Returns the image bytes of the map
  Future<Uint8List?> takeSnapshot() {
    return GoogleMapsFlutterPlatform.instance.takeSnapshot(mapId: mapId);
  }

  /// Disposes of the platform resources
  void dispose() {
    _subscriptions.forEach((s) => s.cancel());
    _subscriptions.clear();
    GoogleMapsFlutterPlatform.instance.dispose(mapId: mapId);
  }

  Future<void> updateNavigationIndex(int index, dynamic point) {
    return GoogleMapsFlutterPlatform.instance.updateNavigationIndex(index, point, mapId: mapId);
  }

  Future<void> initNavigationPolyline(List<dynamic> points, {required Polyline skippedPolyline, required Polyline remainingPolyline}) {
    return GoogleMapsFlutterPlatform.instance.initNavigationPolyline(points, skippedPolyline: skippedPolyline, remainingPolyline: remainingPolyline, mapId: mapId);
  }

  Future<void> initPolyline(Polyline polyline) {
    return GoogleMapsFlutterPlatform.instance.initPolyline(polyline, mapId: mapId);
  }

  Future<void> appendPolylinePoints(PolylineId polylineId, List<dynamic> points) {
    return GoogleMapsFlutterPlatform.instance.appendPolylinePoints(polylineId, points, mapId: mapId);
  }

  Future<void> updateDynamicMarkers(Set<Marker> markers) {
    return GoogleMapsFlutterPlatform.instance.updateDynamicMarkers(markers, mapId: mapId);
  }

  Future<void> removeMarkers(Set<MarkerId> markerIds) {
    return GoogleMapsFlutterPlatform.instance.vdRemoveMarkers(markerIds, mapId: mapId);
  }

  Future<void> addSelfMarker(Marker marker) {
    return GoogleMapsFlutterPlatform.instance.vdAddSelfMarker(marker, mapId: mapId);
  }

  Future<void> updateSelfMarker(Marker marker) {
    return GoogleMapsFlutterPlatform.instance.vdUpdateSelfMarker(marker, mapId: mapId);
  }

  Future<void> cluster() {
    return GoogleMapsFlutterPlatform.instance.cluster(mapId: mapId);
  }

  Future<void> setClusterMarkerStyle(Color background, Color font) {
    return GoogleMapsFlutterPlatform.instance.setClusterMarkerStyle(background, font, mapId: mapId);
  }
}
