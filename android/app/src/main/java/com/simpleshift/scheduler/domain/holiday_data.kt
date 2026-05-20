package com.simpleshift.scheduler.domain

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.Month

/**
 * Represents a single day in the Chinese public holiday calendar.
 *
 * @param date The calendar date
 * @param name Holiday name (e.g. "春节", "国庆节"), null for ordinary days
 * @param isHoliday true = day off, false = adjusted work day (调休上班)
 */
data class HolidayInfo(
    val date: LocalDate,
    val name: String?,
    val isHoliday: Boolean
)

/**
 * Returns China's official public holidays for 2026-2027.
 *
 * 2026 holidays are based on the State Council announcement (国办发明电).
 * 2027 holidays are estimated from lunar calendar and historical patterns,
 * marked with "[待确认]" suffix.
 *
 * Update this file each year after the State Council releases the next year's schedule
 * (typically late November / early December).
 */
fun getChinaHolidays(): Map<LocalDate, HolidayInfo> {
    val holidays = mutableListOf<HolidayInfo>()

    // === 2026 Official Holidays (国办发明电〔2025〕) ===

    // 元旦: Jan 1 (Thu)
    holidays.add(HolidayInfo(LocalDate.of(2026, 1, 1), "元旦", true))

    // 春节: Spring Festival
    // 除夕 Feb 16 (Mon), 初一 Feb 17 (Tue)
    // Holiday: Feb 15 (Sun) – Feb 21 (Sat)
    for (d in 0..6) {
        holidays.add(HolidayInfo(LocalDate.of(2026, 2, 15).plusDays(d.toLong()), "春节", true))
    }
    // 调休: Feb 14 (Sat) work, Feb 28 (Sat) work
    holidays.add(HolidayInfo(LocalDate.of(2026, 2, 14), "春节调休", false))
    holidays.add(HolidayInfo(LocalDate.of(2026, 2, 28), "春节调休", false))

    // 清明节: Apr 5 (Sun), compensatory Apr 6 (Mon)
    holidays.add(HolidayInfo(LocalDate.of(2026, 4, 5), "清明节", true))
    holidays.add(HolidayInfo(LocalDate.of(2026, 4, 6), "清明节", true))

    // 劳动节: May 1 (Fri) – May 5 (Tue)
    for (d in 0..4) {
        holidays.add(HolidayInfo(LocalDate.of(2026, 5, 1).plusDays(d.toLong()), "劳动节", true))
    }
    // 调休: May 9 (Sat) work
    holidays.add(HolidayInfo(LocalDate.of(2026, 5, 9), "劳动节调休", false))

    // 端午节: Jun 19 (Fri) – Jun 21 (Sun)
    for (d in 0..2) {
        holidays.add(HolidayInfo(LocalDate.of(2026, 6, 19).plusDays(d.toLong()), "端午节", true))
    }

    // 中秋节: Sep 25 (Fri) – Sep 27 (Sun)
    for (d in 0..2) {
        holidays.add(HolidayInfo(LocalDate.of(2026, 9, 25).plusDays(d.toLong()), "中秋节", true))
    }

    // 国庆节: Oct 1 (Thu) – Oct 7 (Wed)
    for (d in 0..6) {
        holidays.add(HolidayInfo(LocalDate.of(2026, 10, 1).plusDays(d.toLong()), "国庆节", true))
    }
    // 调休: Sep 27 (Sun) work, Oct 10 (Sat) work
    holidays.add(HolidayInfo(LocalDate.of(2026, 9, 27), "国庆节调休", false))
    holidays.add(HolidayInfo(LocalDate.of(2026, 10, 10), "国庆节调休", false))

    // === 2027 Estimated Holidays (农历推算，待国务院确认) ===

    // 元旦: Jan 1 (Fri) – Jan 3 (Sun)
    for (d in 0..2) {
        holidays.add(HolidayInfo(LocalDate.of(2027, 1, 1).plusDays(d.toLong()), "元旦[待确认]", true))
    }

    // 春节: estimated 初一 Feb 6 (Sat), 除夕 Feb 5 (Fri)
    // Holiday: Feb 5 (Fri) – Feb 11 (Thu)
    for (d in 0..6) {
        holidays.add(HolidayInfo(LocalDate.of(2027, 2, 5).plusDays(d.toLong()), "春节[待确认]", true))
    }
    // 调休: Jan 31 (Sun) work, Feb 13 (Sat) work
    holidays.add(HolidayInfo(LocalDate.of(2027, 1, 31), "春节调休[待确认]", false))
    holidays.add(HolidayInfo(LocalDate.of(2027, 2, 13), "春节调休[待确认]", false))

    // 清明节: Apr 5 (Mon)
    holidays.add(HolidayInfo(LocalDate.of(2027, 4, 5), "清明节[待确认]", true))

    // 劳动节: May 1 (Sat) – May 5 (Wed)
    for (d in 0..4) {
        holidays.add(HolidayInfo(LocalDate.of(2027, 5, 1).plusDays(d.toLong()), "劳动节[待确认]", true))
    }
    // 调休: May 8 (Sat) work
    holidays.add(HolidayInfo(LocalDate.of(2027, 5, 8), "劳动节调休[待确认]", false))

    return holidays.associateBy { it.date }
}

fun isWeekend(date: LocalDate): Boolean {
    val dow = date.dayOfWeek
    return dow == DayOfWeek.SATURDAY || dow == DayOfWeek.SUNDAY
}

/**
 * Checks whether a given date is "naturally off" considering holidays and weekends.
 * Used to determine family availability.
 *
 * A day is naturally off (family at home) if:
 * - It is a public holiday OR a weekend day
 * - AND it is NOT an adjusted work day (调休上班)
 */
fun isNaturallyOff(date: LocalDate, holidays: Map<LocalDate, HolidayInfo>): Boolean {
    val info = holidays[date]
    if (info != null) return info.isHoliday
    return isWeekend(date)
}
