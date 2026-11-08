package com.stb.nas.autostart;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "JioNasAutoBoot";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent != null ? intent.getAction() : "null";
        Log.i(TAG, "BootReceiver triggered with action: " + action);

        // 1. Start foreground service
        try {
            Intent serviceIntent = new Intent(context, NasBootService.class);
            serviceIntent.setAction(action);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent);
            } else {
                context.startService(serviceIntent);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to start service: " + e.getMessage());
        }

        // 2. Launch MainActivity trampoline
        try {
            Intent actIntent = new Intent(context, MainActivity.class);
            actIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            actIntent.putExtra("from_boot", true);
            context.startActivity(actIntent);
            Log.i(TAG, "Launched MainActivity from BootReceiver");
        } catch (Exception e) {
            Log.e(TAG, "Failed to start MainActivity: " + e.getMessage());
        }
    }
}
