package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import java.time.LocalDate

private val motivationPool = listOf(
    "休息是为了走更远的路",
    "坚持就是胜利",
    "注意身体，早点休息",
    "安全第一，平安回家",
    "今天的努力，明天的收获",
    "生活不止眼前的倒班，还有诗和远方",
    "每一份付出都值得尊重"
)

@Composable
fun V2MotivationFooter(modifier: Modifier = Modifier) {
    val text = motivationPool[LocalDate.now().dayOfYear % motivationPool.size]

    AnimatedVisibility(
        visible = true,
        enter = fadeIn(),
        modifier = modifier
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.outline,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
}
