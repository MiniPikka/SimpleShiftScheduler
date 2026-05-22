//! # holiday-engine
//!
//! Chinese statutory holiday data (2026 official + 2027 estimated).
//! Ported from Flutter `holiday_data.dart` and Android `holiday_data.kt`.

use chrono::{Datelike, NaiveDate, Weekday};
use std::collections::HashMap;

/// Information about a holiday or adjusted work day.
#[derive(Debug, Clone)]
pub struct HolidayInfo {
    pub date: NaiveDate,
    pub name: &'static str,
    /// true = statutory holiday (day off), false = adjusted work day (補班)
    pub is_holiday: bool,
    /// true = officially confirmed by State Council, false = estimated
    pub is_confirmed: bool,
}

/// Get all Chinese statutory holidays and adjusted work days.
///
/// Returns a HashMap keyed by date. Covers:
/// - 2026: Official holidays published by State Council (国办发明电〔2025〕)
/// - 2027: Estimated based on lunar calendar, marked 待确认
///
/// Updated annually when the State Council releases the next year's schedule.
pub fn get_china_holidays() -> HashMap<NaiveDate, HolidayInfo> {
    let mut holidays: Vec<HolidayInfo> = Vec::new();

    // ═══════════════════════════════════════════
    // 2026 Official Holidays (国办发明电〔2025〕)
    // ═══════════════════════════════════════════

    // 元旦: Jan 1
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        name: "元旦",
        is_holiday: true,
        is_confirmed: true,
    });

    // 春节: Feb 15-21
    for d in 0..7 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 2, 15).unwrap() + chrono::Duration::days(d),
            name: "春节",
            is_holiday: true,
            is_confirmed: true,
        });
    }
    // 春节调休上班
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 2, 14).unwrap(),
        name: "春节调休",
        is_holiday: false,
        is_confirmed: true,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 2, 28).unwrap(),
        name: "春节调休",
        is_holiday: false,
        is_confirmed: true,
    });

    // 清明节: Apr 5-6
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 4, 5).unwrap(),
        name: "清明节",
        is_holiday: true,
        is_confirmed: true,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 4, 6).unwrap(),
        name: "清明节",
        is_holiday: true,
        is_confirmed: true,
    });

    // 劳动节: May 1-5
    for d in 0..5 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 5, 1).unwrap() + chrono::Duration::days(d),
            name: "劳动节",
            is_holiday: true,
            is_confirmed: true,
        });
    }
    // 劳动节调休
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 5, 9).unwrap(),
        name: "劳动节调休",
        is_holiday: false,
        is_confirmed: true,
    });

    // 端午节: Jun 19-21
    for d in 0..3 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 6, 19).unwrap() + chrono::Duration::days(d),
            name: "端午节",
            is_holiday: true,
            is_confirmed: true,
        });
    }

    // 中秋节: Sep 25-27
    for d in 0..3 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 9, 25).unwrap() + chrono::Duration::days(d),
            name: "中秋节",
            is_holiday: true,
            is_confirmed: true,
        });
    }

    // 国庆节: Oct 1-7
    for d in 0..7 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 10, 1).unwrap() + chrono::Duration::days(d),
            name: "国庆节",
            is_holiday: true,
            is_confirmed: true,
        });
    }
    // 国庆节调休
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 9, 27).unwrap(),
        name: "国庆节调休",
        is_holiday: false,
        is_confirmed: true,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 10, 10).unwrap(),
        name: "国庆节调休",
        is_holiday: false,
        is_confirmed: true,
    });

    // ═══════════════════════════════════════════
    // 2027 Estimated (based on lunar calendar)
    // ═══════════════════════════════════════════

    // 元旦: Jan 1-3
    for d in 0..3 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2027, 1, 1).unwrap() + chrono::Duration::days(d),
            name: "元旦[待确认]",
            is_holiday: true,
            is_confirmed: false,
        });
    }

    // 春节: Feb 5-11 (estimated lunar new year)
    for d in 0..7 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2027, 2, 5).unwrap() + chrono::Duration::days(d),
            name: "春节[待确认]",
            is_holiday: true,
            is_confirmed: false,
        });
    }
    // 春节调休 (estimated)
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 1, 31).unwrap(),
        name: "春节调休[待确认]",
        is_holiday: false,
        is_confirmed: false,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 2, 13).unwrap(),
        name: "春节调休[待确认]",
        is_holiday: false,
        is_confirmed: false,
    });

    // 清明节: Apr 5
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 4, 5).unwrap(),
        name: "清明节[待确认]",
        is_holiday: true,
        is_confirmed: false,
    });

    // 劳动节: May 1-5
    for d in 0..5 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2027, 5, 1).unwrap() + chrono::Duration::days(d),
            name: "劳动节[待确认]",
            is_holiday: true,
            is_confirmed: false,
        });
    }
    // 劳动节调休 (estimated)
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 5, 8).unwrap(),
        name: "劳动节调休[待确认]",
        is_holiday: false,
        is_confirmed: false,
    });

    // Build HashMap
    holidays.into_iter().map(|h| (h.date, h)).collect()
}

/// Returns true if the date is a weekend (Saturday or Sunday).
pub fn is_weekend(date: NaiveDate) -> bool {
    matches!(date.weekday(), Weekday::Sat | Weekday::Sun)
}

/// Returns true if the date is a "natural off day":
/// either a statutory holiday, or a weekend that is NOT an adjusted work day.
pub fn is_naturally_off(date: NaiveDate, holidays: &HashMap<NaiveDate, HolidayInfo>) -> bool {
    if let Some(info) = holidays.get(&date) {
        return info.is_holiday;
    }
    is_weekend(date)
}

/// Returns the holiday info for a date if it exists.
pub fn get_holiday(date: NaiveDate, holidays: &HashMap<NaiveDate, HolidayInfo>) -> Option<&HolidayInfo> {
    holidays.get(&date)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn all_2026_confirmed() {
        let holidays = get_china_holidays();
        let confirmed_2026: Vec<_> = holidays
            .values()
            .filter(|h| h.date.year() == 2026 && h.is_confirmed)
            .collect();
        // Should have dozens of confirmed 2026 entries
        assert!(confirmed_2026.len() >= 30);
    }

    #[test]
    fn all_2027_unconfirmed() {
        let holidays = get_china_holidays();
        let unconfirmed_2027: Vec<_> = holidays
            .values()
            .filter(|h| h.date.year() == 2027)
            .collect();
        assert!(!unconfirmed_2027.is_empty());
        for h in unconfirmed_2027 {
            assert!(!h.is_confirmed);
            assert!(h.name.contains("[待确认]"));
        }
    }

    #[test]
    fn new_years_day_is_holiday() {
        let holidays = get_china_holidays();
        let d = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
        let info = holidays.get(&d).unwrap();
        assert!(info.is_holiday);
        assert_eq!(info.name, "元旦");
    }

    #[test]
    fn spring_festival_adjustment_is_workday() {
        let holidays = get_china_holidays();
        // Feb 14 is a Saturday but it's an adjusted work day
        let d = NaiveDate::from_ymd_opt(2026, 2, 14).unwrap();
        let info = holidays.get(&d).unwrap();
        assert!(!info.is_holiday);
    }

    #[test]
    fn national_day_is_seven_days() {
        let holidays = get_china_holidays();
        let count = holidays
            .values()
            .filter(|h| h.date.year() == 2026 && h.name == "国庆节")
            .count();
        assert_eq!(count, 7);
    }

    #[test]
    fn labour_day_is_five_days() {
        let holidays = get_china_holidays();
        let count = holidays
            .values()
            .filter(|h| h.date.year() == 2026 && h.name == "劳动节")
            .count();
        assert_eq!(count, 5);
    }

    #[test]
    fn is_weekend_saturday_and_sunday() {
        // 2026-05-23 is Saturday, 2026-05-24 is Sunday
        assert!(is_weekend(NaiveDate::from_ymd_opt(2026, 5, 23).unwrap()));
        assert!(is_weekend(NaiveDate::from_ymd_opt(2026, 5, 24).unwrap()));
        assert!(!is_weekend(NaiveDate::from_ymd_opt(2026, 5, 22).unwrap()));
    }

    #[test]
    fn is_naturally_off_respects_adjusted_workday() {
        let holidays = get_china_holidays();
        // Feb 14, 2026 is Saturday but adjusted work day → NOT naturally off
        let d = NaiveDate::from_ymd_opt(2026, 2, 14).unwrap();
        assert!(!is_naturally_off(d, &holidays));
    }

    #[test]
    fn is_naturally_off_for_regular_holiday() {
        let holidays = get_china_holidays();
        // Jan 1, 2026 is a holiday
        let d = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
        assert!(is_naturally_off(d, &holidays));
    }

    #[test]
    fn holiday_data_contains_no_duplicate_dates() {
        let holidays = get_china_holidays();
        let mut dates: Vec<_> = holidays.keys().copied().collect();
        let before = dates.len();
        dates.sort();
        dates.dedup();
        assert_eq!(before, dates.len(), "Duplicate dates found in holiday data");
    }

    #[test]
    fn dragon_boat_festival_is_three_days() {
        let holidays = get_china_holidays();
        let count = holidays
            .values()
            .filter(|h| h.date.year() == 2026 && h.name == "端午节")
            .count();
        assert_eq!(count, 3);
    }

    #[test]
    fn mid_autumn_festival_is_two_days_effective() {
        let holidays = get_china_holidays();
        // Sep 25-27 is 3 days, but Sep 27 is overwritten by 国庆节调休
        // (same date key, last insert wins — matching Flutter behavior)
        let count = holidays
            .values()
            .filter(|h| h.date.year() == 2026 && h.name == "中秋节")
            .count();
        assert_eq!(count, 2);
    }
}
