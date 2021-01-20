package io.flutter.plugins.googlemaps;

import android.graphics.*;
import android.graphics.Bitmap.Config;
import android.graphics.PorterDuff.Mode;
import android.os.Environment;
import android.util.Log;
import android.content.res.AssetManager;

import com.google.android.gms.maps.model.BitmapDescriptorFactory;

import java.io.File;
import java.util.List;
import java.io.InputStream;
import java.io.IOException;

import io.flutter.view.FlutterMain;

class MarkerIconPainter {

    private static int avatarWidth = 48;
    private static int avatarHeight = 48;

    public static Bitmap getBitmapFromPath(String path, float density) {
        try {
            return toAvatar(fromPathToBitmap(path, density), density);
        } catch (Exception e) {
            throw new IllegalArgumentException("Unable to interpret bytes as a valid image.", e);
        }
    }

    public static Bitmap getBitmapFromAsset(AssetManager mgr, String assetName) {
        InputStream is = null;
        Bitmap bitmap = null;

        try {
            Log.d("getBitmapFromAsset", FlutterMain.getLookupKeyForAsset(assetName));
            is = mgr.open(FlutterMain.getLookupKeyForAsset(assetName));
            bitmap = BitmapFactory.decodeStream(is);
        } catch (final IOException e) {
            bitmap = null;
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

    public static Bitmap getBitmapFromText(String text, float density) {
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
        float y = iconSize / 2f + textBoxRect.height() / 2f - textBoxRect.bottom;
        canvas.drawText(text, rectF.centerX(), y, textPaint);

        return output;
    }

    public static Bitmap getBitmapFromCluster(int index, float density) {
        int iconSize = (int) Math.ceil(getClusterSize(index) * density);
        final String text = (index >= 10) ? String.valueOf(index) + "+" : String.valueOf(index);
        final int fontSize = (index >= 100) ? 18 : 16;

        Bitmap output = Bitmap.createBitmap(iconSize, iconSize, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        RectF rectF = new RectF(new Rect(0, 0, iconSize, iconSize));
        Paint clipOvalPaint = new Paint();
        clipOvalPaint.setFlags(Paint.ANTI_ALIAS_FLAG);
        clipOvalPaint.setColor(Color.parseColor("#081B33"));
        clipOvalPaint.setAlpha(153);
        canvas.drawRoundRect(rectF, iconSize, iconSize, clipOvalPaint);

        final Rect textBoxRect = new Rect();
        Paint textPaint = new Paint();
        final Typeface typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD);
        textPaint.setColor(Color.WHITE);
        textPaint.setTextAlign(Paint.Align.CENTER);
        textPaint.setTextSize(fontSize * density);
        textPaint.getTextBounds(text, 0, text.length(), textBoxRect);
        textPaint.setTypeface(typeface);
        float y = iconSize / 2f + textBoxRect.height() / 2f - textBoxRect.bottom;
        canvas.drawText(text, rectF.centerX(), y, textPaint);
        return output;
    }

    private static int getClusterSize(int index) {
        if (index >= 1000) {
            return 60;
        } else if (index >= 500 && index < 1000) {
            return 56;
        } else if (index >= 200 && index < 500) {
            return 52;
        } else if (index >= 100 && index < 200) {
            return 48;
        } else if (index >= 50 && index < 100) {
            return 44;
        } else {
            return 40;
        }
    }

    public static Bitmap combineAvatarAndStatus(Bitmap avatar, Bitmap status, float density) {
        int paddingSize = (int) Math.ceil(2 * density);
        int widthLight = avatar.getWidth() + paddingSize * 2;
        int heightLight = avatar.getHeight() + paddingSize * 2;

        Bitmap output = Bitmap.createBitmap(widthLight, heightLight, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        canvas.drawBitmap(avatar, paddingSize, paddingSize, null);
        canvas.drawBitmap(status, widthLight - status.getWidth() - paddingSize, 0, null);

        return output;
    }

    private static Bitmap toAvatar(Bitmap avatar, double density) {
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
        canvas.drawCircle(widthLight / 2, heightLight / 2, targetAvatarHeight / 2, borderPaint);

        return output;
    }

    private static Bitmap fromPathToBitmap(String path, float density) {
        // Convert path to bitmap
        File image = new File(path);
        BitmapFactory.Options bmOptions = new BitmapFactory.Options();
        Bitmap avatar = BitmapFactory.decodeFile(image.getAbsolutePath(), bmOptions);

        final int targetAvatarWidth = (int) Math.ceil(avatarWidth * density);
        final int targetAvatarHeight = (int) Math.ceil(avatarHeight * density);
        final float widthRatio = targetAvatarWidth / avatar.getWidth();
        final float heightRatio = targetAvatarHeight / avatar.getHeight();

        final float ratio = Math.max(widthRatio, heightRatio);
        if (ratio > 1.0f) {
            return scaleBitmap(avatar, ratio);
        }

        return avatar;
    }

    private static Bitmap scaleBitmap(Bitmap src, float ratio) {
        Matrix matrix = new Matrix();
        matrix.postScale(ratio, ratio);
        return Bitmap.createBitmap(src, 0, 0, src.getWidth(), src.getHeight(), matrix, false);
    }
}