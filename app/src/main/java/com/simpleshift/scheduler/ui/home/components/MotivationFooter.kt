package com.simpleshift.scheduler.ui.home.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import java.time.LocalDate

private val quotes = listOf(
    "休息是为了走更远的路",
    "坚持就是胜利",
    "注意身体，早点休息",
    "每一个夜班都值得被尊重",
    "安全第一，平安回家"
)

@Composable
fun MotivationFooter(modifier: Modifier = Modifier) {
    val dayOfYear = LocalDate.now().dayOfYear
    val quote = quotes[dayOfYear % quotes.size]

    Text(
        text = quote,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        textAlign = TextAlign.Center,
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    )
}

@Preview(showBackground = true)
@Composable
private fun MotivationFooterPreview() {
    MaterialTheme {
        MotivationFooter()
    }
}
