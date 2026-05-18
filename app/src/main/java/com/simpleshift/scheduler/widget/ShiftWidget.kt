package com.simpleshift.scheduler.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.unit.ColorProvider
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalContext
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
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

// ── V2 Dark Theme Colors (aligned with V2CardSurface + v2ShiftColor) ──

private val WidgetBackground = Color(0xFF1B1F26)
private val WidgetTextPrimary = Color(0xFFF5F7FA)
private val WidgetTextSecondary = Color(0xFF9CA3AF)

private fun shiftAccentColor(shiftType: ShiftType): Color = when (shiftType) {
    ShiftType.MORNING   -> Color(0xFFFFB347)
    ShiftType.AFTERNOON -> Color(0xFF4DA3FF)
    ShiftType.NIGHT     -> Color(0xFF7C5CFF)
    ShiftType.REST      -> Color(0xFF35D07F)
    ShiftType.STUDY     -> Color(0xFFF2D94E)
}

// ── Content ─────────────────────────────────────────────────

@Composable
private fun ShiftWidgetContent(data: WidgetShiftData) {
    val context = LocalContext.current

    if (data.totalDays == 0) {
        UnconfiguredWidget(data)
        return
    }

    val accent = shiftAccentColor(data.shiftType)

    Column(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetBackground)
            .padding(12.dp)
            .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
    ) {
        // Row 1: Badge + Info + Rest countdown
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Large shift badge
            Column(
                modifier = GlanceModifier
                    .background(accent)
                    .cornerRadius(10.dp)
                    .padding(horizontal = 10.dp, vertical = 5.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = data.shiftLabel,
                    style = TextStyle(
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(Color.White)
                    )
                )
            }

            Spacer(modifier = GlanceModifier.width(10.dp))

            // Center info
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = data.teamName,
                    style = TextStyle(
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = ColorProvider(WidgetTextPrimary)
                    )
                )
                Text(
                    text = "第${data.dayOfCycle}/${data.totalDays}天",
                    style = TextStyle(
                        fontSize = 11.sp,
                        color = ColorProvider(WidgetTextSecondary)
                    )
                )
            }

            // Rest countdown
            if (data.shiftType == ShiftType.REST) {
                Text(
                    text = "休息日",
                    style = TextStyle(
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(shiftAccentColor(ShiftType.REST))
                    )
                )
            } else if (data.daysUntilRest == 0) {
                Text(
                    text = "明天休息",
                    style = TextStyle(
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = ColorProvider(shiftAccentColor(ShiftType.REST))
                    )
                )
            } else {
                Text(
                    text = "距休${data.daysUntilRest}天",
                    style = TextStyle(
                        fontSize = 12.sp,
                        color = ColorProvider(WidgetTextSecondary)
                    )
                )
            }
        }

        Spacer(modifier = GlanceModifier.height(8.dp))

        // Row 2: Date + Tomorrow preview
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = data.dateLabel,
                style = TextStyle(
                    fontSize = 10.sp,
                    color = ColorProvider(WidgetTextSecondary)
                ),
                modifier = GlanceModifier.defaultWeight()
            )

            // Tomorrow preview
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Small colored dot
                Column(
                    modifier = GlanceModifier
                        .width(6.dp)
                        .height(6.dp)
                        .background(shiftAccentColor(data.tomorrowShiftType))
                        .cornerRadius(3.dp)
                ) {}

                Spacer(modifier = GlanceModifier.width(4.dp))

                Text(
                    text = "明日: ",
                    style = TextStyle(
                        fontSize = 10.sp,
                        color = ColorProvider(WidgetTextSecondary)
                    )
                )
                Text(
                    text = data.tomorrowShiftLabel,
                    style = TextStyle(
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = ColorProvider(WidgetTextPrimary)
                    )
                )
            }
        }
    }
}

// ── Unconfigured State ──────────────────────────────────────

@Composable
private fun UnconfiguredWidget(data: WidgetShiftData) {
    val context = LocalContext.current

    Column(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetBackground)
            .padding(12.dp)
            .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
    ) {
        Text(
            text = data.shiftLabel,
            style = TextStyle(
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = ColorProvider(WidgetTextPrimary)
            )
        )
        Spacer(modifier = GlanceModifier.height(4.dp))
        Text(
            text = data.teamName,
            style = TextStyle(
                fontSize = 11.sp,
                color = ColorProvider(WidgetTextSecondary)
            )
        )
    }
}
