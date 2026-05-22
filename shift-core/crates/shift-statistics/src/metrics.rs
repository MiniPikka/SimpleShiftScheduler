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
///
/// Bounded to 10,000 iterations to prevent infinite loop on all-work cycles.
/// Returns 0 if `today` itself is a rest day.
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
/// Bounded to 10,000 iterations to prevent infinite loop on all-work cycles.
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

    // ── Edge cases ──

    #[test]
    fn all_work_cycle_consecutive_is_bounded() {
        // Cycle with no rest days → consecutive_work_days caps at MAX_ITERATIONS
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning; 3],
            cycle_length: 3,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 1,
        };
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let c = consecutive_work_days(date, &config, 0);
        // With all-work cycle, the loop will hit MAX_ITERATIONS (10000)
        assert_eq!(c, 10000);
    }

    #[test]
    fn all_work_cycle_days_until_rest_bounded() {
        // Cycle with no rest days at all → caps at MAX_ITERATIONS
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning; 3],
            cycle_length: 3,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 1,
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
        // December 2026 has 31 days, next month is January 2027
        let total = count_shift_type_in_month(2026, 12, ShiftType::Morning, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Afternoon, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Rest, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Night, &config, 0)
            + count_shift_type_in_month(2026, 12, ShiftType::Study, &config, 0);
        assert_eq!(total, 31);
    }
}
