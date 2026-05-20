package com.simpleshift.scheduler.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColors = lightColorScheme(
    primary = V2Accent,
    onPrimary = Color.White,
    background = Color(0xFFF8F9FA),
    onBackground = Color(0xFF1A1C1E),
    surface = Color.White,
    onSurface = Color(0xFF1A1C1E),
    surfaceVariant = Color(0xFFF0F1F3),
    onSurfaceVariant = Color(0xFF6B7280),
    error = V2Danger,
    onError = Color.White,
    outline = Color(0xFF9CA3AF)
)

private val DarkColors = darkColorScheme(
    primary = V2Accent,
    onPrimary = V2PrimaryBackground,
    background = V2PrimaryBackground,
    onBackground = V2PrimaryText,
    surface = V2CardSurface,
    onSurface = V2PrimaryText,
    surfaceVariant = V2SecondaryBackground,
    onSurfaceVariant = V2SecondaryText,
    error = V2Danger,
    onError = V2PrimaryText,
    outline = V2HintText
)

@Composable
fun ShiftSchedulerTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = ShiftSchedulerTypography,
        content = content
    )
}
