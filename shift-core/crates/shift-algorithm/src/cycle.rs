//! Default constants and the standard 42-day shift cycle.
//!
//! These constants are shared with the Android (Kotlin) and Flutter (Dart)
//! reference implementations. Changing them here changes all platforms.

use crate::types::ShiftType;
use chrono::NaiveDate;

/// Default cycle length: 42 days.
///
/// This is the most common cycle length for Chinese 6-team rotating shifts.
pub const DEFAULT_CYCLE_LENGTH: u32 = 42;

/// Total number of teams sharing the cycle.
pub const DEFAULT_TOTAL_TEAMS: u32 = 6;

/// Returns the reference date: **2025-12-15**.
///
/// This is day 1 of the default cycle (早班/Morning shift).
/// Shared across all platforms — Android `ShiftCycleConfig.REFERENCE_DATE`
/// and Flutter `ShiftCycleConfig.referenceDate` use the same value.
///
/// ```rust
/// use shift_algorithm::cycle::default_reference_date;
/// use chrono::Datelike;
///
/// let d = default_reference_date();
/// assert_eq!(d.year(), 2025);
/// assert_eq!(d.month(), 12);
/// assert_eq!(d.day(), 15);
/// ```
pub fn default_reference_date() -> NaiveDate {
    NaiveDate::from_ymd_opt(2025, 12, 15).unwrap()
}

/// Returns the default 42-day shift cycle.
///
/// The sequence (in Chinese notation):
/// ```text
/// 早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
/// ```
///
/// Must match Android `ShiftCycleConfig.SHIFT_CYCLE` exactly.
///
/// ```rust
/// use shift_algorithm::cycle::default_shift_cycle;
/// use shift_algorithm::ShiftType;
///
/// let cycle = default_shift_cycle();
/// assert_eq!(cycle.len(), 42);
/// assert_eq!(cycle[0], ShiftType::Morning);
/// assert_eq!(cycle[41], ShiftType::Rest);
/// ```
pub fn default_shift_cycle() -> Vec<ShiftType> {
    use ShiftType::*;
    vec![
        Morning, Morning, Afternoon, Afternoon, Rest, Night, Night,
        Rest, Rest, Morning, Morning, Afternoon, Afternoon, Rest,
        Night, Rest, Rest, Rest, Morning, Morning, Afternoon, Rest,
        Night, Night, Rest, Rest, Rest, Morning, Afternoon, Afternoon,
        Rest, Night, Night, Rest, Rest, Study, Study, Study, Study,
        Study, Rest, Rest,
    ]
}

/// Creates a [`ShiftCycleConfig`](crate::ShiftCycleConfig) with all default values.
///
/// This is the starting point for most use cases:
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_algorithm::get_shift_info;
///
/// let config = default_config();
/// let info = get_shift_info(config.reference_date, &config, 0);
/// assert_eq!(info.day_of_cycle, 1);
/// ```
pub fn default_config() -> crate::types::ShiftCycleConfig {
    crate::types::ShiftCycleConfig {
        cycle: default_shift_cycle(),
        cycle_length: DEFAULT_CYCLE_LENGTH,
        reference_date: default_reference_date(),
        total_teams: DEFAULT_TOTAL_TEAMS,
        team_names: None,
        customization: Default::default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[cfg(test)]
    use chrono::Datelike;

    #[test]
    fn cycle_length_is_42() {
        assert_eq!(default_shift_cycle().len(), 42);
    }

    #[test]
    fn cycle_starts_with_morning() {
        assert_eq!(default_shift_cycle()[0], ShiftType::Morning);
    }

    #[test]
    fn cycle_ends_with_rest() {
        assert_eq!(default_shift_cycle()[41], ShiftType::Rest);
    }

    #[test]
    fn reference_date_equals_android() {
        let d = default_reference_date();
        assert_eq!(d.year(), 2025);
        assert_eq!(d.month(), 12);
        assert_eq!(d.day(), 15);
    }

    #[test]
    fn team_phase_offset_formula() {
        let config = default_config();
        assert_eq!(config.team_phase_offset(1), 0);
        assert_eq!(config.team_phase_offset(2), 7);
        assert_eq!(config.team_phase_offset(6), 35);
    }
}
