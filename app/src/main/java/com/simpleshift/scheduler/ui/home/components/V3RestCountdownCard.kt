package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.ui.theme.V2CardShape
import com.simpleshift.scheduler.ui.theme.V2Rest
import com.simpleshift.scheduler.ui.theme.V2Success
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun V3RestCountdownCard(
    daysUntilRest: Int,
    shiftType: ShiftType,
    modifier: Modifier = Modifier
) {
    val onBg = MaterialTheme.colorScheme.onBackground
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant
    val surface = MaterialTheme.colorScheme.surface

    val isRestToday = shiftType == ShiftType.REST
    val isTomorrowRest = daysUntilRest == 0 && !isRestToday

    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically { it / 3 },
        modifier = modifier
    ) {
        Surface(
            shape = V2CardShape,
            color = if (isRestToday) V2Rest.copy(alpha = 0.08f) else surface
        ) {
            Row(modifier = Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
                if (isRestToday) {
                    Box(
                        modifier = Modifier
                            .width(4.dp)
                            .fillMaxHeight()
                            .background(V2Rest)
                    )
                }

                Column(
                    modifier = Modifier
                        .weight(1f)
                        .padding(20.dp)
                ) {
                    when {
                        isRestToday -> {
                            Text(
                                text = "今日休息",
                                style = MaterialTheme.typography.headlineMedium.copy(
                                    color = V2Success,
                                    fontWeight = FontWeight.Bold
                                )
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "享受你的休息日",
                                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                            )
                        }
                        isTomorrowRest -> {
                            Text(
                                text = "明天休息！",
                                style = MaterialTheme.typography.headlineMedium.copy(
                                    color = onBg,
                                    fontWeight = FontWeight.Bold
                                )
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "今天最后一天上班",
                                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                            )
                        }
                        else -> {
                            Text(
                                text = "距下次休息",
                                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                            )
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "$daysUntilRest",
                                    style = MaterialTheme.typography.headlineMedium.copy(
                                        color = onBg,
                                        fontWeight = FontWeight.Bold
                                    )
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "天",
                                    style = MaterialTheme.typography.bodyLarge.copy(color = onBg)
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            val restDate = LocalDate.now().plusDays(daysUntilRest.toLong())
                            val formatter = DateTimeFormatter.ofPattern("M月d日", Locale.CHINESE)
                            val weekday = when (restDate.dayOfWeek.value) {
                                1 -> "星期一"; 2 -> "星期二"; 3 -> "星期三"
                                4 -> "星期四"; 5 -> "星期五"; 6 -> "星期六"; 7 -> "星期日"
                                else -> ""
                            }
                            Text(
                                text = "预计 ${restDate.format(formatter)} $weekday",
                                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                            )
                        }
                    }
                }
            }
        }
    }
}
