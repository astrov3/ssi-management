package com.example.ssi_app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val lifecycleChannel = "ssi.app/lifecycle"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, lifecycleChannel).setMethodCallHandler { call, result ->
            if (call.method == "bringToForeground") {
                try {
                    bringTaskToFront()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("FOREGROUND_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun bringTaskToFront() {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager?
        val tasks = activityManager?.appTasks
        if (!tasks.isNullOrEmpty()) {
            tasks[0].moveToFront()
            return
        }

        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(intent)
    }
}
