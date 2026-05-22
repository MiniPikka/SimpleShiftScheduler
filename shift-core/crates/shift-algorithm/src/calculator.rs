//! Core shift calculation functions.
//!
//! All functions are **pure**: given the same inputs, always produce the same outputs.
//! No platform dependencies, no I/O, no state.
//!
//! ## The algorithm
//!
//! ```text
//! date → calculate_day_offset(date, reference_date)
//!      → normalize_cycle_index(offset, cycle_length)
//!      → cycle[index]  →  ShiftType
//! ```
//!
//! Team phase offset is added to the day offset before normalization:
//!
//! ```text
//! offset = (date - reference_date) + team_phase_offset
//! ```

use crate::types::{ShiftCycleConfig, ShiftInfo, ShiftType};
use chrono::NaiveDate;

/// Number of days between `date` and `reference_date`.
///
/// Positive means `date` is after the reference. Negative means before.
///
/// ```rust
/// use shift_algorithm::calculate_day_offset;
/// use chrono::NaiveDate;
///
/// let ref_date = NaiveDate::from_ymd_opt(2025, 12, 15).unwrap();
/// let target = NaiveDate::from_ymd_opt(2025, 12, 20).unwrap();
/// assert_eq!(calculate_day_offset(target, ref_date), 5);
/// assert_eq!(calculate_day_offset(ref_date, target), -5);
/// ```
pub fn calculate_day_offset(date: NaiveDate, reference_date: NaiveDate) -> i64 {
    (date - reference_date).num_days()
}

/// Normalize any offset into the range `0..cycle_length`.
///
/// Handles negative values correctly (wraps around).
///
/// ```rust
/// use shift_algorithm::normalize_cycle_index;
///
/// assert_eq!(normalize_cycle_index(0, 42), 0);
/// assert_eq!(normalize_cycle_index(42, 42), 0);
/// assert_eq!(normalize_cycle_index(-1, 42), 41);
/// assert_eq!(normalize_cycle_index(100, 42), 16);
/// ```
///
/// # Panics
///
/// Panics if `cycle_length == 0`.
pub fn normalize_cycle_index(offset_days: i64, cycle_length: u32) -> u32 {
    assert!(cycle_length >= 1, "cycle_length must be >= 1, got 0");
    let len = cycle_length as i64;
    let normalized = offset_days % len;
    if normalized < 0 {
        (normalized + len) as u32
    } else {
        normalized as u32
    }
}

/// Team phase offset in days.
///
/// For a 42-day, 6-team cycle, each team is offset by 7 days:
///
/// ```rust
/// use shift_algorithm::team_phase_offset_for;
///
/// assert_eq!(team_phase_offset_for(1, 42, 6), 0);
/// assert_eq!(team_phase_offset_for(2, 42, 6), 7);
/// assert_eq!(team_phase_offset_for(6, 42, 6), 35);
/// ```
///
/// # Panics
///
/// Panics if `total_teams == 0` or `team_id == 0`.
pub fn team_phase_offset_for(team_id: u32, cycle_length: u32, total_teams: u32) -> u32 {
    assert!(total_teams >= 1, "total_teams must be >= 1, got 0");
    assert!(team_id >= 1, "team_id must be >= 1, got 0");
    (team_id - 1) * (cycle_length / total_teams)
}

/// Get the shift type for a given date.
///
/// This is the core function. Everything else — monthly stats, calendar generation,
/// leave optimization, colleague mode — ultimately calls this.
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_algorithm::get_shift_type_for_date;
///
/// let config = default_config();
/// // 2025-12-15 is day 1 = Morning
/// assert_eq!(
///     get_shift_type_for_date(config.reference_date, &config, 0),
///     shift_algorithm::ShiftType::Morning,
/// );
/// ```
pub fn get_shift_type_for_date(
    date: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> ShiftType {
    let offset = calculate_day_offset(date, config.reference_date) + team_phase_offset as i64;
    let index = normalize_cycle_index(offset, config.cycle_length);
    config.cycle[index as usize]
}

/// Get full shift info (date, day of cycle, cycle index, shift type) in one call.
///
/// Returns [`ShiftInfo`] which includes everything you typically need:
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_algorithm::get_shift_info;
/// use chrono::NaiveDate;
///
/// let config = default_config();
/// let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
/// let info = get_shift_info(today, &config, 0);
///
/// println!("{} · 第 {}/{} 天",
///     info.shift_type.full_label(),
///     info.day_of_cycle,
///     config.cycle_length,
/// );
///
/// assert_eq!(info.date, today);
/// assert!(info.day_of_cycle >= 1);
/// assert!(info.day_of_cycle <= 42);
/// assert_eq!(info.cycle_index + 1, info.day_of_cycle);
/// ```
pub fn get_shift_info(
    date: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
) -> ShiftInfo {
    let offset = calculate_day_offset(date, config.reference_date) + team_phase_offset as i64;
    let index = normalize_cycle_index(offset, config.cycle_length);
    ShiftInfo {
        date,
        day_of_cycle: index + 1,
        shift_type: config.cycle[index as usize],
        cycle_index: index,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::cycle::default_config;

    // ── calculate_day_offset ──

    #[test]
    fn offset_zero_for_reference_date() {
        let ref_date = crate::cycle::default_reference_date();
        assert_eq!(calculate_day_offset(ref_date, ref_date), 0);
    }

    #[test]
    fn offset_positive_one_day_after() {
        let ref_date = crate::cycle::default_reference_date();
        let target = ref_date + chrono::Duration::days(5);
        assert_eq!(calculate_day_offset(target, ref_date), 5);
    }

    #[test]
    fn offset_negative_one_day_before() {
        let ref_date = crate::cycle::default_reference_date();
        let target = ref_date - chrono::Duration::days(1);
        assert_eq!(calculate_day_offset(target, ref_date), -1);
    }

    // ── normalize_cycle_index ──

    #[test]
    fn normalize_zero_is_zero() {
        assert_eq!(normalize_cycle_index(0, 42), 0);
    }

    #[test]
    fn normalize_one_is_one() {
        assert_eq!(normalize_cycle_index(1, 42), 1);
    }

    #[test]
    fn normalize_42_wraps_to_0() {
        assert_eq!(normalize_cycle_index(42, 42), 0);
    }

    #[test]
    fn normalize_43_wraps_to_1() {
        assert_eq!(normalize_cycle_index(43, 42), 1);
    }

    #[test]
    fn normalize_negative_one_is_41() {
        assert_eq!(normalize_cycle_index(-1, 42), 41);
    }

    #[test]
    fn normalize_negative_42_is_0() {
        assert_eq!(normalize_cycle_index(-42, 42), 0);
    }

    #[test]
    fn normalize_custom_cycle_length_7() {
        assert_eq!(normalize_cycle_index(7, 7), 0);
        assert_eq!(normalize_cycle_index(8, 7), 1);
        assert_eq!(normalize_cycle_index(-1, 7), 6);
    }

    // ── get_shift_info ──

    #[test]
    fn reference_date_is_day_1_morning() {
        let config = default_config();
        let info = get_shift_info(config.reference_date, &config, 0);
        assert_eq!(info.day_of_cycle, 1);
        assert_eq!(info.shift_type, ShiftType::Morning);
    }

    #[test]
    fn reference_date_plus_41_is_day_42_rest() {
        let config = default_config();
        let date = config.reference_date + chrono::Duration::days(41);
        let info = get_shift_info(date, &config, 0);
        assert_eq!(info.day_of_cycle, 42);
        assert_eq!(info.shift_type, ShiftType::Rest);
    }

    #[test]
    fn reference_date_plus_4_is_day_5_rest() {
        let config = default_config();
        let date = config.reference_date + chrono::Duration::days(4);
        let info = get_shift_info(date, &config, 0);
        assert_eq!(info.day_of_cycle, 5);
        assert_eq!(info.shift_type, ShiftType::Rest);
    }

    #[test]
    fn team_phase_offset_changes_shift() {
        let config = default_config();
        assert_eq!(
            get_shift_type_for_date(config.reference_date, &config, 0),
            ShiftType::Morning
        );
        assert_eq!(
            get_shift_type_for_date(config.reference_date, &config, 7),
            ShiftType::Rest
        );
    }

    #[test]
    fn custom_cycle_7_days() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning, Afternoon, Rest, Night, Rest, Morning, Afternoon],
            cycle_length: 7,
            reference_date: crate::cycle::default_reference_date(),
            total_teams: 2,
        };
        let info = get_shift_info(config.reference_date, &config, 0);
        assert_eq!(info.day_of_cycle, 1);
        assert_eq!(info.shift_type, Morning);

        let d7 = config.reference_date + chrono::Duration::days(6);
        let info7 = get_shift_info(d7, &config, 0);
        assert_eq!(info7.day_of_cycle, 7);
        assert_eq!(info7.shift_type, Afternoon);

        let d8 = config.reference_date + chrono::Duration::days(7);
        let info8 = get_shift_info(d8, &config, 0);
        assert_eq!(info8.day_of_cycle, 1);
        assert_eq!(info8.shift_type, Morning);
    }

    #[test]
    fn known_date_cross_check_with_android() {
        let config = default_config();
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let info = get_shift_info(date, &config, 0);
        assert_eq!(info.day_of_cycle, 33);
        assert_eq!(info.shift_type, config.cycle[32]);
    }

    // ── Edge cases ──

    #[test]
    fn normalize_cycle_length_1() {
        assert_eq!(normalize_cycle_index(0, 1), 0);
        assert_eq!(normalize_cycle_index(1, 1), 0);
        assert_eq!(normalize_cycle_index(100, 1), 0);
        assert_eq!(normalize_cycle_index(-1, 1), 0);
    }

    #[test]
    #[should_panic(expected = "cycle_length must be >= 1")]
    fn normalize_cycle_length_zero_panics() {
        normalize_cycle_index(0, 0);
    }

    #[test]
    fn team_phase_offset_large_values() {
        let config = default_config();
        let idx = normalize_cycle_index(i64::MAX, config.cycle_length);
        assert!(idx < 42);
    }

    #[test]
    #[should_panic(expected = "total_teams must be >= 1")]
    fn team_phase_offset_zero_teams_panics() {
        team_phase_offset_for(1, 42, 0);
    }

    #[test]
    fn shift_info_day_of_cycle_range() {
        let config = default_config();
        let mut date = config.reference_date;
        for _ in 0..1000 {
            let info = get_shift_info(date, &config, 0);
            assert!(info.day_of_cycle >= 1);
            assert!(info.day_of_cycle <= 42);
            assert_eq!(info.cycle_index + 1, info.day_of_cycle);
            date += chrono::Duration::days(1);
        }
    }

    #[test]
    fn all_same_shift_type_cycle() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Night; 5],
            cycle_length: 5,
            reference_date: crate::cycle::default_reference_date(),
            total_teams: 1,
        };
        let info = get_shift_info(config.reference_date, &config, 0);
        assert_eq!(info.shift_type, Night);
        assert_eq!(info.day_of_cycle, 1);

        let d5 = config.reference_date + chrono::Duration::days(4);
        let info5 = get_shift_info(d5, &config, 0);
        assert_eq!(info5.day_of_cycle, 5);
        assert_eq!(info5.shift_type, Night);
    }
}
