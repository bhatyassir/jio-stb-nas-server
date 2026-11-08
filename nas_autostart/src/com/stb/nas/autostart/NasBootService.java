package com.stb.nas.autostart;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

public class NasBootService extends Service {
    private static final String TAG = "JioNasAutoBoot";
    private static final String CHANNEL_ID = "jio_nas_boot_channel";

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        Notification.Builder builder;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder = new Notification.Builder(this, CHANNEL_ID);
        } else {
            builder = new Notification.Builder(this);
        }
        builder.setContentTitle("Jio NAS AutoBoot")
               .setContentText("Initializing NAS services...")
               .setSmallIcon(android.R.drawable.stat_notify_sync);
        startForeground(1001, builder.build());
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Jio NAS Startup Channel",
                NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                nm.createNotificationChannel(channel);
            }
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "NasBootService onStartCommand executing...");

        // 1. Trigger Termux RunCommandService
        try {
            Intent runCmd = new Intent();
            runCmd.setClassName("com.termux", "com.termux.app.RunCommandService");
            runCmd.setAction("com.termux.RUN_COMMAND");
            runCmd.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/home/start_nas_services.sh");
            runCmd.putExtra("com.termux.RUN_COMMAND_IN_BACKGROUND", true);
            runCmd.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0");
            startService(runCmd);
            Log.i(TAG, "Dispatched RUN_COMMAND to Termux RunCommandService");
        } catch (Exception e) {
            Log.e(TAG, "Could not start RunCommandService: " + e.getMessage(), e);
        }

        // 2. Launch Termux Activity to guarantee full environment & wake-lock
        try {
            Intent termuxIntent = getPackageManager().getLaunchIntentForPackage("com.termux");
            if (termuxIntent != null) {
                termuxIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(termuxIntent);
                Log.i(TAG, "Started TermuxActivity directly");
            }
        } catch (Exception e) {
            Log.e(TAG, "Could not start TermuxActivity: " + e.getMessage(), e);
        }

        // 3. Gracefully return to TV Launcher after 4 seconds
        new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
            @Override
            public void run() {
                try {
                    Intent homeIntent = new Intent(Intent.ACTION_MAIN);
                    homeIntent.addCategory(Intent.CATEGORY_HOME);
                    homeIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(homeIntent);
                    Log.i(TAG, "Returned to TV Home launcher");
                } catch (Exception e) {
                    Log.e(TAG, "Could not return to home: " + e.getMessage(), e);
                }
                stopForeground(true);
                stopSelf();
            }
        }, 4000);

        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
