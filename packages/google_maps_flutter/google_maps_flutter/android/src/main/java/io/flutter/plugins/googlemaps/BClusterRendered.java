package io.flutter.plugins.googlemaps;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.model.BitmapDescriptor;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.maps.android.clustering.Cluster;
import com.google.maps.android.clustering.ClusterManager;
import com.google.maps.android.clustering.view.DefaultClusterRenderer;
import com.google.maps.android.ui.IconGenerator;

public class BClusterRendered extends DefaultClusterRenderer<BClusterItem> {

    private float density;
    private final IconGenerator clusterIconGenerator;
    private final MarkerIconPainter markerIconPainter;

    public BClusterRendered(Context context, GoogleMap map, ClusterManager<BClusterItem> clusterManager, MarkerIconPainter markerIconPainter) {
        super(context, map, clusterManager);
        clusterIconGenerator = new IconGenerator(context);
        this.markerIconPainter = markerIconPainter;
    }

    public void setDensity(float density) {
        this.density = density;
    }

    @Override
    protected void onBeforeClusterItemRendered(@NonNull BClusterItem item, @NonNull MarkerOptions markerOptions) {
        super.onBeforeClusterItemRendered(item, markerOptions);
        markerOptions.icon(BitmapDescriptorFactory.fromBitmap(markerIconPainter.getRiderAvatar(item.getPath(), item.getTitle(), item.getStatus(), density, item.getRatio())));
        markerOptions.title(item.getTitle());
        markerOptions.anchor(item.getAnchorU(), item.getAnchorV());
        markerOptions.zIndex(item.getZIndex());
    }

    @Override
    protected void onClusterItemUpdated(@NonNull BClusterItem item, @NonNull Marker marker) {
        super.onClusterItemUpdated(item, marker);
        marker.setIcon(BitmapDescriptorFactory.fromBitmap(markerIconPainter.getRiderAvatar(item.getPath(), item.getTitle(), item.getStatus(), density, item.getRatio())));
        marker.setTitle(item.getTitle());
        marker.setAnchor(item.getAnchorU(), item.getAnchorV());
        marker.setZIndex(item.getZIndex());
    }

    @Override
    protected void onBeforeClusterRendered(@NonNull Cluster<BClusterItem> cluster, @NonNull MarkerOptions markerOptions) {
        super.onBeforeClusterRendered(cluster, markerOptions);
        clusterIconGenerator.setBackground(null);
        markerOptions.icon(clusterIcon(cluster));
    }

    @Override
    protected void onClusterUpdated(@NonNull Cluster<BClusterItem> cluster, @NonNull Marker marker) {
        super.onClusterUpdated(cluster, marker);
        clusterIconGenerator.setBackground(null);
        marker.setIcon(clusterIcon(cluster));
    }

    private BitmapDescriptor clusterIcon(Cluster<BClusterItem> cluster) {
        int clusterSize = cluster.getSize();
        int size;
        if (clusterSize >= 1000) {
            size = 1000;
        } else if (clusterSize >= 500) {
            size = 500;
        } else if (clusterSize >= 200) {
            size = 200;
        } else if (clusterSize >= 100) {
            size = 100;
        } else if (clusterSize >= 50) {
            size = 50;
        } else if (clusterSize >= 40) {
            size = 40;
        } else if (clusterSize >= 30) {
            size = 30;
        } else if (clusterSize >= 20) {
            size = 20;
        } else if (clusterSize >= 10) {
            size = 10;
        } else size = Math.min(clusterSize, 10);
        clusterIconGenerator.setBackground(null);
        return BitmapDescriptorFactory.fromBitmap(markerIconPainter.getBitmapFromCluster(size, density));
    }
}
