//! Monthly shift statistics.
//!
//! Ported from Flutter `shift_metrics.dart` and Android `shift_metrics.kt`.

use chrono::NaiveDate;
use shift_algorithm::{get_shift_type_for_date, ShiftCycleConfig, ShiftType};

/// Count how many days of a given shift type occur in a given month.
pub fn count_shift_type_in_month(
    year: i32,
    month: u32,
    shift_type: ShiftType,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> u32 {
    let start = NaiveDate::from_ymd_opt(year, month, 1).unwrap();
    let end = if month == 12 {
        NaiveDate::from_ymd_opt(year + 1, 1, 1).unwrap()
    } else {
        NaiveDate::from_ymd_opt(year, month + 1, 1).unwrap()
    };

    let mut count = 0u32;
    let mut current = start;
    while current < end {
        if get_shift_type_for_date(current, config, team_phase_offset) == shift_type {
            count += 1;
        }
        current += chrono::Duration::days(1);
    }
    count
}

/// Count working days (non-rest, non-study) in a given month.
pub fn count_work_days_in_month(
    year: i32,
    month: u32,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> u32 {
    let start = NaiveDate::from_ymd_opt(year, month, 1).unwrap();
    let end = if month == 12 {
        NaiveDate::from_ymd_opt(year + 1, 1, 1).unwrap()
    } else {
        NaiveDate::from_ymd_opt(year, month + 1, 1).unwrap()
    };

    let mut count = 0u32;
    let mut current = start;
    while current < end {
        let st = get_shift_type_for_date(current, config, team_phase_offset);
        if st.is_work() {
            count += 1;
        }
        current += chrono::Duration::days(1);
    }
    count
}

/// Count consecutive work days looking backward from `today` (inclusive).
pub fn consecutive_work_days(
    today: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> u32 {
    let mut count = 0u32;
    let mut current = today;
    loop {
        let st = get_shift_type_for_date(current, config, team_phase_offset);
        if st.is_work() {
            count += 1;
        } else {
            break;
        }
        current -= chrono::Duration::days(1);
    }
    count
}

/// Days until the next rest day, starting from tomorrow (excludes today).
pub fn days_until_next_rest(
    today: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> u32 {
    let mut count = 0u32;
    let mut current = today + chrono::Duration::days(1);
    loop {
        let st = get_shift_type_for_date(current, config, team_phase_offset);
        if st.is_rest() {
            return count;
        }
        count += 1;
        current += chrono::Duration::days(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use shift_algorithm::cycle::default_config;

    #[test]
    fn count_morning_in_may_2026() {
        let config = default_config();
        let count = count_shift_type_in_month(2026, 5, ShiftType::Morning, &config, 0);
        // May 2026 has ~8 morning shifts for team 1 (offset 0)
        assert!(count > 0);
        assert!(count <= 31);
    }

    #[test]
    fn count_work_days_in_31_day_month() {
        let config = default_config();
        let work = count_work_days_in_month(2026, 5, &config, 0);
        let total = count_shift_type_in_month(2026, 5, ShiftType::Morning, &config, 0)
            + count_shift_type_in_month(2026, 5, ShiftType::Afternoon, &config, 0)
            + count_shift_type_in_month(2026, 5, ShiftType::Night, &config, 0);
        assert_eq!(work, total);
    }

    #[test]
    fn consecutive_work_days_non_negative() {
        let config = default_config();
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let c = consecutive_work_days(date, &config, 0);
        // Could be 0 or more, but never panics
        assert!(c < 365);
    }

    #[test]
    fn days_until_rest_positive() {
        let config = default_config();
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let d = days_until_next_rest(date, &config, 0);
        // Must find a rest within 42 days max
        assert!(d < 42);
    }
}
