package com.simpleshift.scheduler_cp.widget

import com.simpleshift.scheduler_cp.R
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.widget.RemoteViews

class ShiftWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val PREFS_NAME = "widget_prefs"

        fun updateWidgets(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val shift = prefs.getString("shift_label", "") ?: ""
            val team = prefs.getString("team_name", "") ?: ""
            val date = prefs.getString("date_label", "") ?: ""
            val progress = prefs.getString("progress_text", "") ?: ""
            val rest = prefs.getString("rest_text", "") ?: ""
            val tomorrowLabel = prefs.getString("tomorrow_shift_label", "") ?: ""
            val badgeColorStr = prefs.getString("shift_badge_color", "#7C5CFF") ?: "#7C5CFF"
            val dotColorStr = prefs.getString("tomorrow_dot_color", "#7C5CFF") ?: "#7C5CFF"
            val badgeColor = try { Color.parseColor(badgeColorStr) } catch (_: Exception) { Color.parseColor("#7C5CFF") }
            val dotColor = try { Color.parseColor(dotColorStr) } catch (_: Exception) { Color.parseColor("#7C5CFF") }

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val provider = android.content.ComponentName(context, ShiftWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(provider)

            for (appWidgetId in ids) {
                val views = RemoteViews(context.packageName, R.layout.shift_widget_layout).apply {
                    if (shift.isEmpty() || shift == "未配置") {
                        // Unconfigured state
                        setTextViewText(R.id.widget_shift_badge, "?")
                        setTextViewText(R.id.widget_team_name, "倒班助手")
                        setTextViewText(R.id.widget_progress, "请先设置排班规则")
                        setTextViewText(R.id.widget_rest, "")
                        setTextViewText(R.id.widget_date, "")
                        setTextViewText(R.id.widget_tomorrow_label, "")
                        setInt(R.id.widget_shift_badge, "setBackgroundColor", Color.parseColor("#4B5563"))
                        setViewVisibility(R.id.widget_tomorrow, android.view.View.GONE)
                    } else {
                        setTextViewText(R.id.widget_shift_badge, shift)
                        setTextViewText(R.id.widget_team_name, team)
                        setTextViewText(R.id.widget_progress, "$date | $progress")
                        setTextViewText(R.id.widget_rest, rest)
                        setTextViewText(R.id.widget_date, date)
                        if (tomorrowLabel.isNotEmpty()) {
                            setTextViewText(R.id.widget_tomorrow_label, "明日: $tomorrowLabel")
                            setViewVisibility(R.id.widget_tomorrow, android.view.View.VISIBLE)
                        } else {
                            setViewVisibility(R.id.widget_tomorrow, android.view.View.GONE)
                        }

                        // Badge background color
                        setInt(R.id.widget_shift_badge, "setBackgroundColor", badgeColor)

                        // Tomorrow dot color
                        try {
                            val dotDrawable = GradientDrawable().apply {
                                setColor(dotColor)
                                cornerRadius = 12f
                            }
                            setInt(R.id.widget_tomorrow_dot, "setBackgroundColor", dotColor)
                        } catch (_: Exception) {}
                    }
                }

                // Click to open app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (intent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_shift_badge, pendingIntent)
                }
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context)
    }
}
