package com.simpleshift.scheduler_cp.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
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

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val provider = android.content.ComponentName(context, ShiftWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(provider)

            for (appWidgetId in ids) {
                val views = RemoteViews(context.packageName, R.layout.shift_widget_layout).apply {
                    if (shift.isEmpty() || shift == "未配置") {
                        setTextViewText(R.id.widget_team_date, "倒班助手")
                        setTextViewText(R.id.widget_shift_progress, "请先设置排班规则")
                        setTextViewText(R.id.widget_rest, "")
                    } else {
                        setTextViewText(R.id.widget_team_date, "$team · $shift")
                        setTextViewText(R.id.widget_shift_progress, "$date | $progress")
                        setTextViewText(R.id.widget_rest, rest)
                    }
                }

                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (intent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_team_date, pendingIntent)
                }
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context)
    }
}
