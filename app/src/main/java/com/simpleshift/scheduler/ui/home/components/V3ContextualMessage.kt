package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import com.simpleshift.scheduler.domain.model.ShiftType
import java.time.LocalDate

private val restMessages = listOf(
    "好好休息，陪伴家人",
    "休息是为了更好的出发",
    "今天属于你自己"
)

private val nightMessages = listOf(
    "夜班辛苦了，注意安全",
    "夜深了，照顾好自己",
    "夜晚的坚守，值得尊敬"
)

private val hardWorkMessages = listOf(
    "连续上班，你辛苦了",
    "坚持住，休息日不远了"
)

private val almostRestMessages = listOf(
    "马上就要休息了，坚持一下",
    "休息日倒计时，加油"
)

private val defaultMessages = listOf(
    "今天也要元气满满",
    "安全第一，平安回家",
    "每一份付出都值得尊重"
)

fun getContextualMessage(
    shiftType: ShiftType,
    daysUntilRest: Int,
    consecutiveWorkDays: Int,
    daySeed: Int = LocalDate.now().dayOfYear
): String = when {
    shiftType == ShiftType.REST ->
        restMessages[daySeed % restMessages.size]

    shiftType == ShiftType.NIGHT ->
        nightMessages[daySeed % nightMessages.size]

    consecutiveWorkDays >= 5 ->
        hardWorkMessages[daySeed % hardWorkMessages.size]
            .replace("连续上班", "连续第 ${consecutiveWorkDays} 天上班")

    daysUntilRest <= 1 ->
        almostRestMessages[daySeed % almostRestMessages.size]

    else ->
        defaultMessages[daySeed % defaultMessages.size]
}

@Composable
fun V3ContextualMessage(
    shiftType: ShiftType,
    daysUntilRest: Int,
    consecutiveWorkDays: Int,
    modifier: Modifier = Modifier
) {
    val message = getContextualMessage(shiftType, daysUntilRest, consecutiveWorkDays)

    AnimatedVisibility(
        visible = true,
        enter = fadeIn(),
        modifier = modifier
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.outline,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
}
