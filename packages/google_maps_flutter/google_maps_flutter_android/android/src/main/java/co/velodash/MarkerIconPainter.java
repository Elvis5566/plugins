package io.flutter.plugins.googlemaps;

import android.graphics.*;
import android.graphics.Bitmap.Config;
import android.graphics.PorterDuff.Mode;
import android.os.Environment;
import android.util.Log;
import android.content.res.AssetManager;
import android.util.LruCache;

import com.google.android.gms.maps.model.BitmapDescriptorFactory;

import java.io.File;
import java.util.List;
import java.io.InputStream;
import java.io.IOException;

import io.flutter.view.FlutterMain;

class MarkerIconPainter {
    private AssetManager mgr;
    private float density;

    private int avatarWidth = 48;
    private int avatarHeight = 48;

    private Bitmap riderLeftStatus;
    private Bitmap riderLostStatus;
    private Bitmap riderPauseStatus;

    private final LruCache<String, Bitmap> bitmapLruCache;
    private int clusterBackgroundColor = Color.rgb(8, 27, 51);
    private int clusterFontColor = Color.rgb(255, 255, 255);
    private float clusterBackgroundAlpha = 0.6f;
    private float clusterFontAlpha = 1.0f;

    MarkerIconPainter(AssetManager mgr, float density) {
        this.mgr = mgr;
        this.riderLeftStatus = getBitmapFromAsset(mgr, "common_app/assets/rider_left_png.png", density);
        this.riderLostStatus = getBitmapFromAsset(mgr, "common_app/assets/rider_disconnected_png.png", density);
        this.riderPauseStatus = getBitmapFromAsset(mgr, "common_app/assets/rider_pause_png.png", density);
        int cacheSize = 4 * 1024 * 1024;
        this.bitmapLruCache = new LruCache<String, Bitmap>(cacheSize) {
            @Override
            protected int sizeOf(String key, Bitmap value) {
                return value.getByteCount();
            }
        };
    }

    public void setClusterBackgroundColor(int r, int g, int b, float a) {
        this.clusterBackgroundColor = Color.rgb(r, g, b);
        this.clusterBackgroundAlpha = a;
    }

    public void setClusterFontColor(int r, int g, int b, float a) {
        this.clusterFontColor = Color.rgb(r, g, b);
        this.clusterFontAlpha = a;
    }

    public Bitmap getRiderAvatar(String path, String name, int status, float density, float ratio, boolean highlight) {
        Bitmap bitmap = null;
        if (path != null && !path.isEmpty()) {
            bitmap = getBitmapFromPath(path, density * ratio);
        }

        if (bitmap == null) {
            bitmap = getBitmapFromText(name, density * ratio);
        }

        Bitmap bitmapWithStatus;

        switch (status) {
            case 1:
                bitmapWithStatus = combineAvatarAndStatus(bitmap, riderPauseStatus, density);
                if (highlight) {
                    bitmapWithStatus = withHighlight(bitmapWithStatus, density * ratio);
                }
                break;
            case 2:
                bitmapWithStatus = combineAvatarAndStatus(bitmap, riderLostStatus, density);
                if (highlight) {
                    bitmapWithStatus = withHighlight(bitmapWithStatus, density * ratio);
                }
                break;
            case 3:
                bitmapWithStatus = combineAvatarAndStatus(bitmap, riderLeftStatus, density);
                if (highlight) {
                    bitmapWithStatus = withHighlight(bitmapWithStatus, density * ratio);
                }
                break;
            case 5:
                bitmapWithStatus = withSos(bitmap, density * ratio);
                break;
            default:
                if (highlight) {
                    bitmapWithStatus = withHighlight(bitmap, density * ratio);
                } else {
                    bitmapWithStatus = bitmap;
                }
                break;
        }

        return bitmapWithStatus;
    }

    private Bitmap getBitmapFromPath(String path, float density) {
        try {
            return toAvatar(fromPathToBitmap(path, density), density);
        } catch (Exception e) {
            // TODO: should pass exception to flutter, improve later.
            Log.e("MarkerIconPainter", e.toString());
            e.printStackTrace();
            return null;
        }
    }

    private Bitmap getBitmapFromAsset(AssetManager mgr, String assetName, float density) {
        InputStream is = null;
        Bitmap bitmap = null;

        try {
            Log.d("getBitmapFromAsset", FlutterMain.getLookupKeyForAsset(assetName));
            is = mgr.open(FlutterMain.getLookupKeyForAsset(assetName));
            bitmap = BitmapFactory.decodeStream(is);

            final float widthRatio = (float) Math.ceil(24 * density) / bitmap.getWidth();
            final float heightRatio = (float) Math.ceil(24 * density) / bitmap.getHeight();

            final float ratio = Math.max(widthRatio, heightRatio);
            bitmap = scaleBitmap(bitmap, ratio);

        } catch (final Exception e) {
            // ignore error
        } finally {
            if (is != null) {
                try {
                    is.close();
                } catch (IOException ignored) {
                }
            }
        }

        return bitmap;
    }

    private Bitmap getBitmapFromText(String text, float density) {
        int iconSize = (int) Math.ceil(avatarWidth * density);
        int borderSize = (int) Math.ceil(4 * density);
        int targetSize = iconSize + borderSize * 2;
        int fontSize = 18;

        Bitmap output = Bitmap.createBitmap(targetSize, targetSize, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        RectF rectF = new RectF(new Rect(borderSize, borderSize, iconSize + borderSize, iconSize + borderSize));
        Paint clipOvalPaint = new Paint();
        clipOvalPaint.setFlags(Paint.ANTI_ALIAS_FLAG);
        clipOvalPaint.setColor(Color.parseColor("#959595"));
        canvas.drawRoundRect(rectF, targetSize, targetSize, clipOvalPaint);

        Paint borderPaint = new Paint();
        borderPaint.setStrokeWidth(borderSize);
        borderPaint.setStyle(Paint.Style.STROKE);
        borderPaint.setFlags(Paint.ANTI_ALIAS_FLAG);
        borderPaint.setColor(Color.WHITE);
        canvas.drawCircle(targetSize / 2, targetSize / 2, iconSize / 2, borderPaint);

        final Rect textBoxRect = new Rect();
        Paint textPaint = new Paint();
        final Typeface typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD);
        textPaint.setColor(Color.WHITE);
        textPaint.setTextAlign(Paint.Align.CENTER);
        textPaint.setTextSize(fontSize * density);
        textPaint.getTextBounds(text, 0, text.length(), textBoxRect);
        textPaint.setTypeface(typeface);
        float y = targetSize / 2f + textBoxRect.height() / 2f - textBoxRect.bottom;
        canvas.drawText(text, rectF.centerX(), y, textPaint);

        return output;
    }

    public Bitmap getBitmapFromCluster(int index, float density) {
        final String key = "cluster-" + String.valueOf(index) + "background" + String.valueOf(clusterBackgroundColor) + String.valueOf(clusterBackgroundAlpha) + "font" + String.valueOf(clusterFontColor) + String.valueOf(clusterFontAlpha);
        if (bitmapLruCache.get(key) != null) {
            return bitmapLruCache.get(key);
        }

        int iconSize = (int) Math.ceil(getClusterSize(index) * density);
        final String text = (index >= 10) ? String.valueOf(index) + "+" : String.valueOf(index);
        final int fontSize = (index >= 100) ? 18 : 16;

        Bitmap output = Bitmap.createBitmap(iconSize, iconSize, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        RectF rectF = new RectF(new Rect(0, 0, iconSize, iconSize));
        Paint clipOvalPaint = new Paint();
        clipOvalPaint.setFlags(Paint.ANTI_ALIAS_FLAG);
        clipOvalPaint.setColor(clusterBackgroundColor);
        clipOvalPaint.setAlpha((int) (255.0 * clusterBackgroundAlpha));
        canvas.drawRoundRect(rectF, iconSize, iconSize, clipOvalPaint);

        final Rect textBoxRect = new Rect();
        Paint textPaint = new Paint();
        final Typeface typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD);
        textPaint.setColor(clusterFontColor);
        textPaint.setAlpha((int) (255.0 * clusterFontAlpha));
        textPaint.setTextAlign(Paint.Align.CENTER);
        textPaint.setTextSize(fontSize * density);
        textPaint.getTextBounds(text, 0, text.length(), textBoxRect);
        textPaint.setTypeface(typeface);
        float y = iconSize / 2f + textBoxRect.height() / 2f - textBoxRect.bottom;
        canvas.drawText(text, rectF.centerX(), y, textPaint);

        synchronized (bitmapLruCache) {
            if (bitmapLruCache.get(key) == null) {
                bitmapLruCache.put(key, output);
            }
        }

        return output;
    }

    private Bitmap combineAvatarAndStatus(Bitmap avatar, Bitmap status, float density) {
        if (status == null) {
            return avatar;
        }
        int paddingSize = (int) Math.ceil(3 * density);
        int widthLight = avatar.getWidth() + paddingSize * 2;
        int heightLight = avatar.getHeight() + paddingSize * 2;

        Bitmap output = Bitmap.createBitmap(widthLight, heightLight, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        canvas.drawBitmap(avatar, paddingSize, paddingSize, null);
        canvas.drawBitmap(status, widthLight - status.getWidth() - paddingSize, 0, null);

        return output;
    }

    private Bitmap withSos(Bitmap avatar, float density) {
        int shadowSize = (int) Math.ceil(8 * density);
        int offset = (int) Math.ceil(2 * density);
        int widthLight = avatar.getWidth() + shadowSize * 2;
        int heightLight = avatar.getHeight() + shadowSize * 2;

        Bitmap output = Bitmap.createBitmap(widthLight, heightLight, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        Paint shadowPaint = new Paint();
        shadowPaint.setShadowLayer(20.0f, 0.f, 0.f, Color.RED);
        shadowPaint.setColor(Color.RED);
        RectF rectF = new RectF(new Rect(shadowSize + offset, shadowSize + offset, avatar.getWidth() + shadowSize - offset, avatar.getWidth() + shadowSize - offset));
        canvas.drawOval(rectF, shadowPaint);

        Paint paintImage = new Paint();
        paintImage.setXfermode(new PorterDuffXfermode(Mode.SRC_ATOP));
        canvas.drawBitmap(avatar, shadowSize, shadowSize, paintImage);

        return output;
    }

    private Bitmap withHighlight(Bitmap avatar, float density) {
        int shadowSize = (int) Math.ceil(10 * density);
        int offset = (int) Math.ceil(2 * density);
        int widthLight = avatar.getWidth() + shadowSize * 2;
        int heightLight = avatar.getHeight() + shadowSize * 2;

        Bitmap output = Bitmap.createBitmap(widthLight, heightLight, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        Paint shadowPaint = new Paint();
        shadowPaint.setShadowLayer(10, 0.f, 0.f, Color.GREEN);
        shadowPaint.setColor(Color.GREEN);
        shadowPaint.setMaskFilter(new BlurMaskFilter(40, BlurMaskFilter.Blur.OUTER));
        RectF rectF = new RectF(new Rect(shadowSize + offset, shadowSize + offset, avatar.getWidth() + shadowSize - offset, avatar.getWidth() + shadowSize - offset));
        canvas.drawOval(rectF, shadowPaint);

        canvas.drawBitmap(avatar, shadowSize, shadowSize, null);

        return output;
    }

    private int getClusterSize(int index) {
        if (index >= 1000) {
            return 80;
        } else if (index >= 500 && index < 1000) {
            return 72;
        } else if (index >= 100 && index < 500) {
            return 64;
        } else if (index >= 50 && index < 100) {
            return 56;
        } else {
            return 48;
        }
    }

    private Bitmap toAvatar(Bitmap avatar, double density) {
        final int targetAvatarWidth = (int) Math.ceil(avatarWidth * density);
        final int targetAvatarHeight = (int) Math.ceil(avatarHeight * density);

        int borderSize = (int) Math.ceil(4 * density);
        int widthLight = targetAvatarWidth + borderSize * 2;
        int heightLight = targetAvatarHeight + borderSize * 2;

        Bitmap output = Bitmap.createBitmap(widthLight, heightLight, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        RectF rectF = new RectF(new Rect(borderSize, borderSize, targetAvatarWidth + borderSize, targetAvatarHeight + borderSize));
        Paint clipOvalPaint = new Paint();
        clipOvalPaint.setFlags(Paint.ANTI_ALIAS_FLAG);
        canvas.drawRoundRect(rectF, targetAvatarWidth, targetAvatarHeight, clipOvalPaint);

        Paint paintImage = new Paint();
        paintImage.setXfermode(new PorterDuffXfermode(Mode.SRC_ATOP));
        canvas.drawBitmap(avatar, borderSize, borderSize, paintImage);

        Paint borderPaint = new Paint();
        borderPaint.setStrokeWidth(borderSize);
        borderPaint.setStyle(Paint.Style.STROKE);
        borderPaint.setFlags(Paint.ANTI_ALIAS_FLAG);
        borderPaint.setColor(Color.WHITE);
        canvas.drawCircle(widthLight / 2.0f, heightLight / 2.0f, targetAvatarHeight / 2.0f, borderPaint);

        return output;
    }

    private Bitmap fromPathToBitmap(String path, float density) {
        // Convert path to bitmap
        File image = new File(path);
        BitmapFactory.Options bmOptions = new BitmapFactory.Options();
        Bitmap avatar = BitmapFactory.decodeFile(image.getAbsolutePath(), bmOptions);

        final int targetAvatarWidth = (int) Math.ceil(avatarWidth * density);
        final int targetAvatarHeight = (int) Math.ceil(avatarHeight * density);

        final float widthRatio = (float) targetAvatarWidth / avatar.getWidth();
        final float heightRatio = (float) targetAvatarHeight / avatar.getHeight();

        final float ratio = Math.max(widthRatio, heightRatio);
        return scaleBitmap(avatar, ratio);
    }

    private Bitmap scaleBitmap(Bitmap src, float ratio) {
        Matrix matrix = new Matrix();
        matrix.postScale(ratio, ratio);
        return Bitmap.createBitmap(src, 0, 0, src.getWidth(), src.getHeight(), matrix, false);
    }
}