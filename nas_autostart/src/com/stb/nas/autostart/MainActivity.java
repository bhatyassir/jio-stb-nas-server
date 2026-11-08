package com.stb.nas.autostart;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

public class MainActivity extends Activity {
    private static final String TAG = "JioNasAutoBoot";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i(TAG, "MainActivity onCreate");

        launchNas(this);

        // After 4 seconds, return to Home screen and finish
        new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
            @Override
            public void run() {
                try {
                    Intent homeIntent = new Intent(Intent.ACTION_MAIN);
                    homeIntent.addCategory(Intent.CATEGORY_HOME);
                    homeIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(homeIntent);
                    Log.i(TAG, "Returned to TV Home screen");
                } catch (Exception e) {
                    Log.e(TAG, "Error returning home: " + e.getMessage());
                }
                finish();
            }
        }, 4000);
    }

    public static void launchNas(Context context) {
        // 1. Send RunCommandService
        try {
            Intent runCmd = new Intent();
            runCmd.setClassName("com.termux", "com.termux.app.RunCommandService");
            runCmd.setAction("com.termux.RUN_COMMAND");
            runCmd.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/home/start_nas_services.sh");
            runCmd.putExtra("com.termux.RUN_COMMAND_IN_BACKGROUND", true);
            runCmd.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0");
            context.startService(runCmd);
            Log.i(TAG, "Sent RUN_COMMAND to RunCommandService");
        } catch (Exception e) {
            Log.e(TAG, "Error sending RUN_COMMAND: " + e.getMessage());
        }

        // 2. Launch Termux Activity
        try {
            Intent termuxIntent = context.getPackageManager().getLaunchIntentForPackage("com.termux");
            if (termuxIntent != null) {
                termuxIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(termuxIntent);
                Log.i(TAG, "Started TermuxActivity");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error starting TermuxActivity: " + e.getMessage());
        }
    }
}
