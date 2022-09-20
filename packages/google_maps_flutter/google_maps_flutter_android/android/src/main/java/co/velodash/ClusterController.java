package io.flutter.plugins.googlemaps;

import android.util.Log;

import com.google.android.gms.maps.GoogleMap;
import com.google.maps.android.clustering.ClusterManager;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class ClusterController {
    private final Map<String, BClusterItem> markerIdToClusterItem;
    private final MethodChannel methodChannel;
    private GoogleMap googleMap;
    private ClusterManager<BClusterItem> clusterManager;

    ClusterController(MethodChannel methodChannel) {
        this.markerIdToClusterItem = new HashMap<>();
        this.methodChannel = methodChannel;
    }

    void setGoogleMap(GoogleMap googleMap) {
        this.googleMap = googleMap;
    }

    void setClusterManager(ClusterManager<BClusterItem> clusterManager) {
        this.clusterManager = clusterManager;
    }

    void addOrUpdateMarkers(List<Object> markers) {
        if (markers != null) {
            for (Object marker : markers) {
                final String markerId = getMarkerId(marker);
                if (checkMarkerIsExist(markerId)) {
                    changeMarker(marker);
                } else {
                    addMarker(marker);
                }
            }
        }
    }

    void removeMarkers(List<Object> markerIdsToRemove) {
        if (markerIdsToRemove == null) {
            return;
        }
        for (Object rawMarkerId : markerIdsToRemove) {
            if (rawMarkerId == null) {
                continue;
            }
            String markerId = (String) rawMarkerId;
            final BClusterItem item = markerIdToClusterItem.remove(markerId);
            if (item != null) {
                clusterManager.removeItem(item);
            }
        }
    }

    private void addMarker(Object marker) {
        if (marker == null) {
            return;
        }
        final BClusterItem item = Convert.toClusterItem(marker);
        clusterManager.addItem(item);
        markerIdToClusterItem.put(item.getMarkerId(), item);
    }

    private void changeMarker(Object marker) {
        if (marker == null) {
            return;
        }
        String markerId = getMarkerId(marker);
        final BClusterItem oldItem = markerIdToClusterItem.get(markerId);
        clusterManager.removeItem(oldItem);
        final BClusterItem newItem = Convert.toClusterItem(marker);
        clusterManager.addItem(newItem);
    }

    @SuppressWarnings("unchecked")
    private static String getMarkerId(Object marker) {
        Map<String, Object> markerMap = (Map<String, Object>) marker;
        return (String) markerMap.get("markerId");
    }

    public boolean checkMarkerIsExist(String markerId) {
        return markerIdToClusterItem.get(markerId) != null;
    }

    public void onClusterItemClick(BClusterItem item) {
        if (item != null) {
            Log.d("ClusterController", "The item " + item.getMarkerId() + " is clicked");
            methodChannel.invokeMethod("marker#onTap", Convert.markerIdToJson(item.getMarkerId()));
        }
    }
}
