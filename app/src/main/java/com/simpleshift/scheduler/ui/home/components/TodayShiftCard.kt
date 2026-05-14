package com.simpleshift.scheduler.ui.home.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.ShiftType

@Composable
fun TodayShiftCard(
    shiftLabel: String,
    shiftType: ShiftType,
    dayOfCycle: Int,
    totalDays: Int,
    daysUntilRest: Int,
    modifier: Modifier = Modifier
) {
    val shiftColor = shiftTypeColor(shiftType)

    Card(
        shape = MaterialTheme.shapes.large,
        colors = CardDefaults.cardColors(
            containerColor = shiftColor.copy(alpha = 0.06f)
        ),
        modifier = modifier.height(IntrinsicSize.Min)
    ) {
        Row(modifier = Modifier.height(IntrinsicSize.Min)) {
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .fillMaxHeight()
                    .background(shiftColor)
            )

            Row(
                modifier = Modifier
                    .weight(1f)
                    .padding(20.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    modifier = Modifier.size(64.dp),
                    shape = CircleShape,
                    color = shiftColor
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = shiftLabel,
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }

                Spacer(Modifier.width(16.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "今日班次",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        RestBadge(daysUntilRest)
                    }

                    Spacer(Modifier.height(12.dp))

                    Text(
                        text = "周期进度",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(4.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        LinearProgressIndicator(
                            progress = dayOfCycle.toFloat() / totalDays.toFloat(),
                            modifier = Modifier
                                .weight(1f)
                                .height(8.dp),
                            color = shiftColor,
                            trackColor = shiftColor.copy(alpha = 0.15f)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = "$dayOfCycle / $totalDays",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RestBadge(daysUntilRest: Int) {
    val (text, containerColor, contentColor) = if (daysUntilRest == 0) {
        Triple(
            "休息日",
            Color(0xFF2ECC71).copy(alpha = 0.15f),
            Color(0xFF1B5E20)
        )
    } else {
        Triple(
            "距休 ${daysUntilRest}天",
            MaterialTheme.colorScheme.surfaceVariant,
            MaterialTheme.colorScheme.onSurfaceVariant
        )
    }

    Surface(
        shape = RoundedCornerShape(6.dp),
        color = containerColor
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = contentColor,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
        )
    }
}

private fun shiftTypeColor(shiftType: ShiftType): Color = when (shiftType) {
    ShiftType.MORNING -> Color(0xFFE67E22)
    ShiftType.AFTERNOON -> Color(0xFF3498DB)
    ShiftType.REST -> Color(0xFF2ECC71)
    ShiftType.NIGHT -> Color(0xFF9B59B6)
    ShiftType.STUDY -> Color(0xFFF1C40F)
}

@Preview(showBackground = true)
@Composable
private fun TodayShiftCardPreview() {
    MaterialTheme {
        TodayShiftCard(
            shiftLabel = "夜",
            shiftType = ShiftType.NIGHT,
            dayOfCycle = 10,
            totalDays = 42,
            daysUntilRest = 2
        )
    }
}
