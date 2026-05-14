package com.simpleshift.scheduler.ui.theme

import androidx.compose.ui.graphics.Color
import com.simpleshift.scheduler.domain.model.ShiftType

// Dark Productivity Design — Color Tokens

// Backgrounds
val V2PrimaryBackground = Color(0xFF0B0D10)
val V2SecondaryBackground = Color(0xFF15181D)
val V2CardSurface = Color(0xFF1B1F26)

// Text
val V2PrimaryText = Color(0xFFF5F7FA)
val V2SecondaryText = Color(0xFF9CA3AF)
val V2HintText = Color(0xFF6B7280)

// Shift colors
val V2Morning = Color(0xFFFFB347)
val V2Afternoon = Color(0xFF4DA3FF)
val V2Night = Color(0xFF7C5CFF)
val V2Rest = Color(0xFF35D07F)
val V2Study = Color(0xFFF2D94E)

// Semantic
val V2Success = Color(0xFF22C55E)
val V2Warning = Color(0xFFF59E0B)
val V2Danger = Color(0xFFEF4444)
val V2Accent = Color(0xFFFACC15)

fun v2ShiftColor(shiftType: ShiftType): Color = when (shiftType) {
    ShiftType.MORNING -> V2Morning
    ShiftType.AFTERNOON -> V2Afternoon
    ShiftType.NIGHT -> V2Night
    ShiftType.REST -> V2Rest
    ShiftType.STUDY -> V2Study
}
