package com.simpleshift.scheduler.ui.colleague_mode

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.wrapContentHeight

/** Pure data object for share card rendering — no ViewModel/Context dependencies. */
data class ShareCardData(
    val teamAName: String,
    val teamBName: String,
    val nextCommonRestDate: String,
    val nextCommonRestWeekday: String,
    val daysUntilNext: Int,
    val countIn30Days: Int,
    val countIn60Days: Int,
    val commonRestDateItems: List<String>,
    val dateRange: String,
    val qrCodeBitmap: Bitmap
)

/**
 * Off-screen share card layout.
 * Width: 1080px (fixed, pixel-level — intended for Bitmap rendering, not on-screen display).
 * Height: content-driven (~1920px at typical density, 9:16 ratio).
 */
@Composable
fun ShareCardLayout(data: ShareCardData) {
    val qrImageBitmap: ImageBitmap = data.qrCodeBitmap.asImageBitmap()

    Column(
        modifier = Modifier
            .width(1080.dp)
            .background(Color(0xFF0B0D10))
            .padding(48.dp)
    ) {
        // App name header
        Text(
            text = "倒班助手",
            style = MaterialTheme.typography.labelMedium.copy(fontSize = 20.sp),
            color = Color(0xFF9CA3AF),
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(40.dp))

        // Section title
        Text(
            text = "下次同时休息",
            style = MaterialTheme.typography.titleMedium.copy(fontSize = 24.sp),
            color = Color(0xFFD1D5DB),
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Main result card
        val gradientBrush = Brush.horizontalGradient(
            colors = listOf(
                Color(0xFF7C5CFF).copy(alpha = 0.4f),
                Color(0xFF4DA3FF).copy(alpha = 0.25f)
            )
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(28.dp),
            colors = CardDefaults.cardColors(containerColor = Color.Transparent)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(28.dp))
                    .background(gradientBrush)
                    .padding(36.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "${data.teamAName} × ${data.teamBName}",
                        style = MaterialTheme.typography.labelMedium.copy(fontSize = 18.sp),
                        color = Color(0xFFD1D5DB)
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = data.nextCommonRestDate,
                        style = MaterialTheme.typography.displaySmall.copy(
                            fontSize = 48.sp,
                            fontWeight = FontWeight.Bold
                        ),
                        color = Color.White
                    )
                    Text(
                        text = data.nextCommonRestWeekday,
                        style = MaterialTheme.typography.bodyLarge.copy(fontSize = 22.sp),
                        color = Color(0xFFD1D5DB)
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    val daysText = when {
                        data.daysUntilNext == 0 -> "就是今天！"
                        data.daysUntilNext == 1 -> "就在明天"
                        else -> "距今 ${data.daysUntilNext} 天"
                    }
                    Text(
                        text = daysText,
                        style = MaterialTheme.typography.bodyMedium.copy(fontSize = 20.sp),
                        color = Color(0xFFFACC15),
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Stats row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            ShareStatCard(
                title = "未来30天\n共同休息",
                count = "${data.countIn30Days} 次",
                modifier = Modifier.weight(1f)
            )
            ShareStatCard(
                title = "未来60天\n共同休息",
                count = "${data.countIn60Days} 次",
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(modifier = Modifier.height(28.dp))

        // Common rest date list
        Text(
            text = "共同休息日",
            style = MaterialTheme.typography.titleSmall.copy(fontSize = 20.sp),
            color = Color(0xFFD1D5DB),
            modifier = Modifier.padding(bottom = 12.dp)
        )

        // Show up to 12 items in 2 columns for space efficiency
        val items = data.commonRestDateItems.take(12)
        val half = (items.size + 1) / 2
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            Column(modifier = Modifier.weight(1f)) {
                items.take(half).forEach { item ->
                    Text(
                        text = "• $item",
                        style = MaterialTheme.typography.bodyMedium.copy(fontSize = 18.sp),
                        color = Color(0xFFE5E7EB),
                        modifier = Modifier.padding(vertical = 3.dp)
                    )
                }
            }
            Column(modifier = Modifier.weight(1f)) {
                items.drop(half).forEach { item ->
                    Text(
                        text = "• $item",
                        style = MaterialTheme.typography.bodyMedium.copy(fontSize = 18.sp),
                        color = Color(0xFFE5E7EB),
                        modifier = Modifier.padding(vertical = 3.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(36.dp))

        // QR code section
        Box(
            modifier = Modifier.fillMaxWidth(),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Image(
                    bitmap = qrImageBitmap,
                    contentDescription = "扫码下载倒班助手",
                    modifier = Modifier.size(200.dp),
                    contentScale = ContentScale.Fit
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "扫码下载倒班助手",
                    style = MaterialTheme.typography.labelMedium.copy(fontSize = 16.sp),
                    color = Color(0xFF9CA3AF)
                )
            }
        }

        Spacer(modifier = Modifier.height(36.dp))

        // Slogan + data range footer
        Text(
            text = "倒班助手 · 你的智能排班管家",
            style = MaterialTheme.typography.bodySmall.copy(fontSize = 18.sp),
            color = Color(0xFF6B7280),
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "分析范围：${data.dateRange}",
            style = MaterialTheme.typography.bodySmall.copy(fontSize = 16.sp),
            color = Color(0xFF4B5563),
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun ShareStatCard(title: String, count: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF1B1F26)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = count,
                style = MaterialTheme.typography.headlineMedium.copy(
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold
                ),
                color = Color.White
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.bodySmall.copy(fontSize = 16.sp),
                color = Color(0xFF9CA3AF),
                textAlign = TextAlign.Center
            )
        }
    }
}
