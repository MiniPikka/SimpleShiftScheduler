package com.simpleshift.scheduler_cp

import android.content.Context
import android.content.SharedPreferences
import androidx.annotation.NonNull
import com.simpleshift.scheduler_cp.widget.ShiftWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.simpleshift.scheduler_cp/widget"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidget") {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
                    val prefs = getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putString("shift_label", args["shift_label"] as? String ?: "")
                        putString("team_name", args["team_name"] as? String ?: "")
                        putString("date_label", args["date_label"] as? String ?: "")
                        putString("progress_text", args["progress_text"] as? String ?: "")
                        putString("rest_text", args["rest_text"] as? String ?: "")
                        putString("tomorrow_shift_label", args["tomorrow_shift_label"] as? String ?: "")
                        putString("shift_badge_color", args["shift_badge_color"] as? String ?: "#7C5CFF")
                        putString("tomorrow_dot_color", args["tomorrow_dot_color"] as? String ?: "#7C5CFF")
                        apply()
                    }
                    ShiftWidgetProvider.updateWidgets(this)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
