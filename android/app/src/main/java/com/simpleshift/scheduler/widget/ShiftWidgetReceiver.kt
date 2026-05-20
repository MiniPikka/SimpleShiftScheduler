package com.simpleshift.scheduler.widget

import androidx.glance.appwidget.GlanceAppWidgetReceiver

class ShiftWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = ShiftWidget()
}
