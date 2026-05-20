package com.simpleshift.scheduler.util

import android.content.Context
import com.simpleshift.scheduler.R

object HolidayNameMapper {
    fun toLocalizedName(chineseName: String?, context: Context): String {
        if (chineseName == null) return ""
        return when {
            chineseName == "元旦" -> context.getString(R.string.holiday_new_year)
            chineseName == "春节" -> context.getString(R.string.holiday_spring_festival)
            chineseName == "春节调休" -> context.getString(R.string.holiday_spring_festival_adj)
            chineseName == "清明节" -> context.getString(R.string.holiday_qingming)
            chineseName == "劳动节" -> context.getString(R.string.holiday_labor_day)
            chineseName == "劳动节调休" -> context.getString(R.string.holiday_labor_day_adj)
            chineseName == "端午节" -> context.getString(R.string.holiday_dragon_boat)
            chineseName == "中秋节" -> context.getString(R.string.holiday_mid_autumn)
            chineseName == "国庆节" -> context.getString(R.string.holiday_national_day)
            chineseName == "国庆节调休" -> context.getString(R.string.holiday_national_day_adj)
            chineseName.contains("[待确认]") -> {
                val base = chineseName.replace("[待确认]", "").trim()
                "${toLocalizedName(base, context)}${context.getString(R.string.holiday_tbc)}"
            }
            else -> chineseName
        }
    }
}
