//! Monthly shift counts and work/rest tracking.
//!
//! All functions iterate day-by-day through the target range and call
//! [`get_shift_type_for_date`] for each day.
//!
//! Ported from Flutter `shift_metrics.dart` and Android `shift_metrics.kt`.

use chrono::NaiveDate;
use shift_algorithm::{get_shift_type_for_date, ShiftCycleConfig, ShiftType};

/// Count how many days of a given shift type occur in a month.
///
/// Works correctly for all month lengths (28, 29, 30, 31 days) and
/// handles December→January transition.
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_statistics::metrics::count_shift_type_in_month;
/// use shift_algorithm::ShiftType;
///
/// let config = default_config();
/// let morning_count = count_shift_type_in_month(2026, 5, ShiftType::Morning, &config, 0);
/// // May 2026 has several morning shifts for team 1
/// assert!(morning_count > 0);
/// assert!(morning_count <= 31);
/// ```
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

/// Count total working days (Morning + Afternoon + Night) in a month.
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_statistics::metrics::count_work_days_in_month;
///
/// let config = default_config();
/// let work = count_work_days_in_month(2026, 5, &config, 0);
/// // Sum of Morning, Afternoon, Night counts for the month
/// assert!(work <= 31);
/// ```
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
///
/// Stops at the first non-work day. Returns 0 if today is a rest day.
///
/// Bounded to 10,000 iterations to prevent infinite loops on all-work cycles.
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_statistics::metrics::consecutive_work_days;
/// use chrono::NaiveDate;
///
/// let config = default_config();
/// let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
/// let consec = consecutive_work_days(today, &config, 0);
/// println!("连续上班 {} 天", consec);
/// ```
pub fn consecutive_work_days(
    today: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> u32 {
    const MAX_ITERATIONS: u32 = 10000;
    let mut count = 0u32;
    let mut current = today;
    for _ in 0..MAX_ITERATIONS {
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
///
/// Returns 0 if tomorrow is already a rest day.
/// Does not consider whether today itself is rest — use
/// [`get_shift_info`](shift_algorithm::get_shift_info) to check that.
///
/// Bounded to 10,000 iterations.
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_statistics::metrics::days_until_next_rest;
/// use chrono::NaiveDate;
///
/// let config = default_config();
/// let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
/// let days = days_until_next_rest(today, &config, 0);
///
/// if days == 0 {
///     println!("明天休息！");
/// } else {
///     println!("距休 {} 天", days);
/// }
/// ```
pub fn days_until_next_rest(
    today: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> u32 {
    const MAX_ITERATIONS: u32 = 10000;
    let mut count = 0u32;
    let mut current = today + chrono::Duration::days(1);
    for _ in 0..MAX_ITERATIONS {
        let st = get_shift_type_for_date(current, config, team_phase_offset);
        if st.is_rest() {
            return count;
        }
        count += 1;
        current += chrono::Duration::days(1);
    }
    count
}

#[cfg(test)]
mod tests {
    use super::*;
    use shift_algorithm::cycle::default_config;

    #[test]
    fn count_morning_in_may_2026() {
        let config = default_config();
        let count = count_shift_type_in_month(2026, 5, ShiftType::Morning, &config, 0);
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
        assert!(c < 365);
    }

    #[test]
    fn days_until_rest_positive() {
        let config = default_config();
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let d = days_until_next_rest(date, &config, 0);
        assert!(d < 42);
    }

    // ── Edge cases ──

    #[test]
    fn all_work_cycle_consecutive_is_bounded() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning; 3],
            cycle_length: 3,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 1,
            team_names: None,
            customization: Default::default(),
        };
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let c = consecutive_work_days(date, &config, 0);
        assert_eq!(c, 10000);
    }

    #[test]
    fn all_work_cycle_days_until_rest_bounded() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning; 3],
            cycle_length: 3,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 1,
            team_names: None,
            customization: Default::default(),
        };
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let d = days_until_next_rest(date, &config, 0);
        assert_eq!(d, 10000);
    }

    #[test]
    fn all_rest_cycle_consecutive_is_zero() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Rest; 5],
            cycle_length: 5,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 1,
            team_names: None,
            customization: Default::default(),
        };
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        assert_eq!(consecutive_work_days(date, &config, 0), 0);
    }

    #[test]
    fn all_rest_cycle_count_work_is_zero() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Rest; 5],
            cycle_length: 5,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 1,
            team_names: None,
            customization: Default::default(),
        };
        let work = count_work_days_in_month(2026, 5, &config, 0);
        assert_eq!(work, 0);
    }

    #[test]
    fn february_2026_has_28_days() {
        let config = default_config();
        let morning = count_shift_type_in_month(2026, 2, ShiftType::Morning, &config, 0);
        let afternoon = count_shift_type_in_month(2026, 2, ShiftType::Afternoon, &config, 0);
        let rest = count_shift_type_in_month(2026, 2, ShiftType::Rest, &config, 0);
        let night = count_shift_type_in_month(2026, 2, ShiftType::Night, &config, 0);
        let study = count_shift_type_in_month(2026, 2, ShiftType::Study, &config, 0);
        assert_eq!(morning + afternoon + rest + night + study, 28);
    }

    #[test]
    fn december_2026_transition() {
        let config = default_config();
        let total = count_shift_type_in_month(2026, 12, ShiftType::Morning, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Afternoon, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Rest, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Night, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Study, &config, 0);
        assert_eq!(total, 31);
    }
}
