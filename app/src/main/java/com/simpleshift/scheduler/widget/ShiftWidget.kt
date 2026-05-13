package com.simpleshift.scheduler.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalContext
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.simpleshift.scheduler.MainActivity
import com.simpleshift.scheduler.data.repository.SettingsRepository
import com.simpleshift.scheduler.domain.WidgetShiftData
import com.simpleshift.scheduler.domain.computeWidgetShiftData
import com.simpleshift.scheduler.domain.model.ShiftType
import kotlinx.coroutines.flow.first

class ShiftWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: androidx.glance.GlanceId) {
        val settingsRepository = SettingsRepository(context)
        val settings = settingsRepository.settingsFlow.first()
        val data = computeWidgetShiftData(settings = settings)

        provideContent {
            GlanceTheme {
                ShiftWidgetContent(data = data)
            }
        }
    }
}

@Composable
private fun ShiftWidgetContent(data: WidgetShiftData) {
    val context = LocalContext.current
    Column(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(shiftBackgroundRes(data.shiftType))
            .padding(12.dp)
            .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
    ) {
        // Row 1: Team name + date
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = data.teamName,
                style = TextStyle(
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                text = data.dateLabel,
                style = TextStyle(fontSize = 10.sp)
            )
        }

        Spacer(modifier = GlanceModifier.height(6.dp))

        // Row 2: Shift label (large) + progress
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = data.shiftLabel,
                style = TextStyle(
                    fontSize = 30.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Spacer(modifier = GlanceModifier.width(12.dp))
            Text(
                text = "进度: ${data.dayOfCycle}/${data.totalDays}",
                style = TextStyle(fontSize = 12.sp)
            )
        }
    }
}

private fun shiftBackgroundRes(shiftType: ShiftType): Int = when (shiftType) {
    ShiftType.MORNING   -> com.simpleshift.scheduler.R.color.shift_widget_morning
    ShiftType.AFTERNOON -> com.simpleshift.scheduler.R.color.shift_widget_afternoon
    ShiftType.REST      -> com.simpleshift.scheduler.R.color.shift_widget_rest
    ShiftType.NIGHT     -> com.simpleshift.scheduler.R.color.shift_widget_night
    ShiftType.STUDY     -> com.simpleshift.scheduler.R.color.shift_widget_study
}
