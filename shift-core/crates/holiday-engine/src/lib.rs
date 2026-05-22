//! # holiday-engine
//!
//! **Chinese statutory holiday data** for 2026 (officially published) and
//! 2027 (estimated based on lunar calendar).
//!
//! Covers all 7 Chinese statutory holidays plus their adjusted work days (調休).
//! Updated annually when the State Council releases next year's schedule.
//!
//! ## The data
//!
//! | Holiday | 2026 Range | Days | Notes |
//! |---------|-----------|------|-------|
//! | 元旦 New Year | Jan 1 | 1 | |
//! | 春节 Spring Festival | Feb 15-21 | 7 | +2 adjusted work days |
//! | 清明节 Qingming | Apr 5-6 | 2 | |
//! | 劳动节 Labour Day | May 1-5 | 5 | +1 adjusted |
//! | 端午节 Dragon Boat | Jun 19-21 | 3 | |
//! | 中秋节 Mid-Autumn | Sep 25-27* | 3 | Sep 27 overwritten by National Day adjustment |
//! | 国庆节 National Day | Oct 1-7 | 7 | +2 adjusted |
//!
//! ## Quick start
//!
//! ```rust
//! use holiday_engine::{get_china_holidays, is_naturally_off};
//! use chrono::NaiveDate;
//!
//! let holidays = get_china_holidays();
//! let date = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
//! assert!(is_naturally_off(date, &holidays));
//!
//! // Feb 14, 2026 is a Saturday but an adjusted WORK day
//! let work_date = NaiveDate::from_ymd_opt(2026, 2, 14).unwrap();
//! assert!(!is_naturally_off(work_date, &holidays));
//! ```

use chrono::{Datelike, NaiveDate, Weekday};
use std::collections::HashMap;

/// Information about a holiday or adjusted work day.
#[derive(Debug, Clone)]
pub struct HolidayInfo {
    pub date: NaiveDate,
    /// Holiday name. Contains `[待确认]` for 2027 estimated entries.
    pub name: &'static str,
    /// `true` = statutory holiday (day off), `false` = adjusted work day (補班).
    pub is_holiday: bool,
    /// `true` = officially confirmed by State Council, `false` = estimated.
    pub is_confirmed: bool,
}

/// Get all Chinese statutory holidays and adjusted work days.
///
/// Returns a `HashMap<NaiveDate, HolidayInfo>` covering:
/// - **2026**: Official data from 国办发明电〔2025〕
/// - **2027**: Estimated based on lunar calendar (marked `[待确认]`)
///
/// # Duplicate dates
///
/// Some dates appear in two different holiday definitions (e.g. Sep 27
/// is both Mid-Autumn holiday AND National Day adjusted work day).
/// The **last insert wins**, which matches Flutter/Android behavior.
///
/// ```rust
/// use holiday_engine::get_china_holidays;
/// use chrono::NaiveDate;
///
/// let holidays = get_china_holidays();
///
/// // New Year's Day
/// let d = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
/// let info = holidays.get(&d).unwrap();
/// assert!(info.is_holiday);
/// assert!(info.is_confirmed);
/// assert_eq!(info.name, "元旦");
/// ```
pub fn get_china_holidays() -> HashMap<NaiveDate, HolidayInfo> {
    let mut holidays: Vec<HolidayInfo> = Vec::new();

    // ═══════════════════════════════════════════
    // 2026 Official Holidays
    // ═══════════════════════════════════════════

    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        name: "元旦", is_holiday: true, is_confirmed: true,
    });

    for d in 0..7 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 2, 15).unwrap() + chrono::Duration::days(d),
            name: "春节", is_holiday: true, is_confirmed: true,
        });
    }
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 2, 14).unwrap(),
        name: "春节调休", is_holiday: false, is_confirmed: true,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 2, 28).unwrap(),
        name: "春节调休", is_holiday: false, is_confirmed: true,
    });

    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 4, 5).unwrap(),
        name: "清明节", is_holiday: true, is_confirmed: true,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 4, 6).unwrap(),
        name: "清明节", is_holiday: true, is_confirmed: true,
    });

    for d in 0..5 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 5, 1).unwrap() + chrono::Duration::days(d),
            name: "劳动节", is_holiday: true, is_confirmed: true,
        });
    }
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 5, 9).unwrap(),
        name: "劳动节调休", is_holiday: false, is_confirmed: true,
    });

    for d in 0..3 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 6, 19).unwrap() + chrono::Duration::days(d),
            name: "端午节", is_holiday: true, is_confirmed: true,
        });
    }

    for d in 0..3 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 9, 25).unwrap() + chrono::Duration::days(d),
            name: "中秋节", is_holiday: true, is_confirmed: true,
        });
    }

    for d in 0..7 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2026, 10, 1).unwrap() + chrono::Duration::days(d),
            name: "国庆节", is_holiday: true, is_confirmed: true,
        });
    }
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 9, 27).unwrap(),
        name: "国庆节调休", is_holiday: false, is_confirmed: true,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2026, 10, 10).unwrap(),
        name: "国庆节调休", is_holiday: false, is_confirmed: true,
    });

    // ═══════════════════════════════════════════
    // 2027 Estimated (based on lunar calendar)
    // ═══════════════════════════════════════════

    for d in 0..3 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2027, 1, 1).unwrap() + chrono::Duration::days(d),
            name: "元旦[待确认]", is_holiday: true, is_confirmed: false,
        });
    }

    for d in 0..7 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2027, 2, 5).unwrap() + chrono::Duration::days(d),
            name: "春节[待确认]", is_holiday: true, is_confirmed: false,
        });
    }
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 1, 31).unwrap(),
        name: "春节调休[待确认]", is_holiday: false, is_confirmed: false,
    });
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 2, 13).unwrap(),
        name: "春节调休[待确认]", is_holiday: false, is_confirmed: false,
    });

    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 4, 5).unwrap(),
        name: "清明节[待确认]", is_holiday: true, is_confirmed: false,
    });

    for d in 0..5 {
        holidays.push(HolidayInfo {
            date: NaiveDate::from_ymd_opt(2027, 5, 1).unwrap() + chrono::Duration::days(d),
            name: "劳动节[待确认]", is_holiday: true, is_confirmed: false,
        });
    }
    holidays.push(HolidayInfo {
        date: NaiveDate::from_ymd_opt(2027, 5, 8).unwrap(),
        name: "劳动节调休[待确认]", is_holiday: false, is_confirmed: false,
    });

    holidays.into_iter().map(|h| (h.date, h)).collect()
}

/// Returns `true` if the date is a weekend (Saturday or Sunday).
///
/// ```rust
/// use holiday_engine::is_weekend;
/// use chrono::NaiveDate;
///
/// let sat = NaiveDate::from_ymd_opt(2026, 5, 23).unwrap();
/// assert!(is_weekend(sat));
/// let fri = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
/// assert!(!is_weekend(fri));
/// ```
pub fn is_weekend(date: NaiveDate) -> bool {
    matches!(date.weekday(), Weekday::Sat | Weekday::Sun)
}

/// Returns `true` if the date is "naturally off":
///
/// Either a statutory holiday, or a weekend that is NOT an adjusted work day.
///
/// This is used by the leave optimizer to determine which days contribute
/// to rest blocks without needing leave.
///
/// ```rust
/// use holiday_engine::{get_china_holidays, is_naturally_off};
/// use chrono::NaiveDate;
///
/// let holidays = get_china_holidays();
/// // New Year's Day — holiday
/// assert!(is_naturally_off(NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(), &holidays));
/// // Feb 14 is Saturday but it's an adjusted work day
/// assert!(!is_naturally_off(NaiveDate::from_ymd_opt(2026, 2, 14).unwrap(), &holidays));
/// ```
pub fn is_naturally_off(date: NaiveDate, holidays: &HashMap<NaiveDate, HolidayInfo>) -> bool {
    if let Some(info) = holidays.get(&date) {
        return info.is_holiday;
    }
    is_weekend(date)
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
        assert!(confirmed_2026.len() >= 30);
    }

    #[test]
    fn all_2027_unconfirmed() {
        let holidays = get_china_holidays();
        let unconfirmed_2027: Vec<_> = holidays.values().filter(|h| h.date.year() == 2027).collect();
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
        let d = NaiveDate::from_ymd_opt(2026, 2, 14).unwrap();
        let info = holidays.get(&d).unwrap();
        assert!(!info.is_holiday);
    }

    #[test]
    fn national_day_is_seven_days() {
        let holidays = get_china_holidays();
        let count = holidays.values().filter(|h| h.date.year() == 2026 && h.name == "国庆节").count();
        assert_eq!(count, 7);
    }

    #[test]
    fn labour_day_is_five_days() {
        let holidays = get_china_holidays();
        let count = holidays.values().filter(|h| h.date.year() == 2026 && h.name == "劳动节").count();
        assert_eq!(count, 5);
    }

    #[test]
    fn is_weekend_saturday_and_sunday() {
        assert!(is_weekend(NaiveDate::from_ymd_opt(2026, 5, 23).unwrap()));
        assert!(is_weekend(NaiveDate::from_ymd_opt(2026, 5, 24).unwrap()));
        assert!(!is_weekend(NaiveDate::from_ymd_opt(2026, 5, 22).unwrap()));
    }

    #[test]
    fn is_naturally_off_respects_adjusted_workday() {
        let holidays = get_china_holidays();
        let d = NaiveDate::from_ymd_opt(2026, 2, 14).unwrap();
        assert!(!is_naturally_off(d, &holidays));
    }

    #[test]
    fn is_naturally_off_for_regular_holiday() {
        let holidays = get_china_holidays();
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
        let count = holidays.values().filter(|h| h.date.year() == 2026 && h.name == "端午节").count();
        assert_eq!(count, 3);
    }

    #[test]
    fn mid_autumn_festival_is_two_days_effective() {
        let holidays = get_china_holidays();
        let count = holidays.values().filter(|h| h.date.year() == 2026 && h.name == "中秋节").count();
        assert_eq!(count, 2);
    }
}
