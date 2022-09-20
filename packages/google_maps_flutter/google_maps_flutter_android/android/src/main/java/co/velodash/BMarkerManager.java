package io.flutter.plugins.googlemaps;

import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.model.Marker;
import com.google.maps.android.collections.MarkerManager;

public class BMarkerManager extends MarkerManager {

    private MarkersController controller;

    public BMarkerManager(GoogleMap map, MarkersController controller) {
        super(map);
        this.controller = controller;
    }

    @Override
    public boolean onMarkerClick(Marker marker) {
        final boolean isHandled = super.onMarkerClick(marker);
        if (!isHandled) {
            controller.onMarkerTap(marker.getId());
        }
        return true;
    }

    @Override
    public void onInfoWindowClick(Marker marker) {
        super.onInfoWindowClick(marker);
        controller.onInfoWindowTap(marker.getId());
    }

    @Override
    public void onMarkerDragEnd(Marker marker) {
        super.onMarkerDragEnd(marker);
        controller.onMarkerDragEnd(marker.getId(), marker.getPosition());
    }
}
