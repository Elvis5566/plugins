package io.flutter.plugins.googlemaps;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.maps.model.LatLng;
import com.google.maps.android.clustering.ClusterItem;

import java.util.Objects;

public class BClusterItem implements ClusterItem {

    private final String markerId;
    private final LatLng position;
    private final String title;
    private final String path;
    private final int status;
    private final float ratio;
    private final float u;
    private final float v;
    private final float zIndex;

    public BClusterItem(String markerId, LatLng position, String title, String path, int status, float ratio, float u, float v, float zIndex) {
        this.markerId = markerId;
        this.position = position;
        this.title = title;
        this.path = path;
        this.status = status;
        this.ratio = ratio;
        this.u = u;
        this.v = v;
        this.zIndex = zIndex;
    }

    @NonNull
    @Override
    public LatLng getPosition() {
        return position;
    }

    @Nullable
    @Override
    public String getTitle() {
        return title;
    }

    @Nullable
    @Override
    public String getSnippet() {
        return null;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BClusterItem that = (BClusterItem) o;
        return Objects.equals(markerId, that.markerId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(markerId);
    }

    public String getMarkerId() {
        return markerId;
    }

    public String getPath() {
        return path;
    }

    public int getStatus() {
        return status;
    }

    public float getRatio() {
        return ratio;
    }

    public float getAnchorU() {
        return u;
    }

    public float getAnchorV() {
        return v;
    }

    public float getZIndex() {
        return zIndex;
    }
}
