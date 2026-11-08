package com.wallpaper.setter;

import android.app.Activity;
import android.app.WallpaperManager;
import android.os.Bundle;
import java.io.File;
import java.io.FileInputStream;

public class SetWallpaperActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            WallpaperManager wm = WallpaperManager.getInstance(getApplicationContext());
            File f = new File("/sdcard/wallpaper.jpg");
            if (f.exists()) {
                FileInputStream fis = new FileInputStream(f);
                wm.setStream(fis);
                fis.close();
                android.util.Log.i("WallpaperSetter", "Wallpaper set successfully!");
            } else {
                android.util.Log.e("WallpaperSetter", "File /sdcard/wallpaper.jpg not found!");
            }
        } catch (Exception e) {
            android.util.Log.e("WallpaperSetter", "Error setting wallpaper: " + e.getMessage(), e);
        }
        finish();
    }
}
