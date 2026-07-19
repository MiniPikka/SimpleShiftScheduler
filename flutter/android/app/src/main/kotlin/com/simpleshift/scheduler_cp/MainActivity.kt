package com.simpleshift.scheduler_cp

import android.content.Context
import android.content.SharedPreferences
import androidx.annotation.NonNull
import com.simpleshift.scheduler_cp.calendar.CalendarEventIds
import com.simpleshift.scheduler_cp.calendar.CalendarEventManager
import com.simpleshift.scheduler_cp.calendar.EventIdStorage
import com.simpleshift.scheduler_cp.widget.ShiftWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.simpleshift.scheduler_cp/widget"
    private val CALENDAR_CHANNEL = "com.simpleshift.scheduler_cp/calendar"
    private val calendarEventManager by lazy { CalendarEventManager(this) }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Widget update channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
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
                        putString("handover_text", args["handover_text"] as? String ?: "")
                        apply()
                    }
                    // Notify widget to refresh
                    try {
                        ShiftWidgetProvider.updateWidgets(this)
                    } catch (_: Exception) {}
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }

        // Calendar event channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALENDAR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncShiftEvents" -> {
                        try {
                            val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
                            @Suppress("UNCHECKED_CAST")
                            val events = (args["events"] as? List<Map<String, Any>>) ?: emptyList()

                            // Load existing event IDs for dedup
                            val existingIds = EventIdStorage.load(this)

                            val (count, updatedIds) = calendarEventManager.syncShiftEvents(
                                events = events,
                                existingEventIds = existingIds
                            )

                            // Persist updated event IDs
                            EventIdStorage.save(this, updatedIds)

                            result.success(count)
                        } catch (e: Exception) {
                            result.error("CALENDAR_ERROR", e.localizedMessage, null)
                        }
                    }
                    "deleteAllEvents" -> {
                        try {
                            calendarEventManager.deleteAllEvents()
                            EventIdStorage.save(this, CalendarEventIds())
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CALENDAR_ERROR", e.localizedMessage, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
