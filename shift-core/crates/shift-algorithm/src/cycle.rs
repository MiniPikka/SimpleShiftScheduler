use crate::types::ShiftType;
use chrono::NaiveDate;
#[cfg(test)]
use chrono::Datelike;

/// Default cycle length: 42 days, 6 teams.
pub const DEFAULT_CYCLE_LENGTH: u32 = 42;

/// Total number of teams.
pub const DEFAULT_TOTAL_TEAMS: u32 = 6;

/// Reference date: 2025-12-15 is day 1 of the default cycle.
/// This constant is shared with Android `ShiftCycleConfig.REFERENCE_DATE`
/// and Flutter `shift_cycle_config.dart`.
pub fn default_reference_date() -> NaiveDate {
    NaiveDate::from_ymd_opt(2025, 12, 15).unwrap()
}

/// Default 42-day shift cycle.
///
/// Must match Android `ShiftCycleConfig.SHIFT_CYCLE` exactly:
/// 早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
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

/// Create a ShiftCycleConfig with default values.
pub fn default_config() -> crate::types::ShiftCycleConfig {
    crate::types::ShiftCycleConfig {
        cycle: default_shift_cycle(),
        cycle_length: DEFAULT_CYCLE_LENGTH,
        reference_date: default_reference_date(),
        total_teams: DEFAULT_TOTAL_TEAMS,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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
        // Android REFERENCE_DATE = LocalDate.of(2025, 12, 15)
        let d = default_reference_date();
        assert_eq!(d.year(), 2025);
        assert_eq!(d.month(), 12);
        assert_eq!(d.day(), 15);
    }

    #[test]
    fn team_phase_offset_formula() {
        let config = default_config();
        // team 1: offset 0, team 2: offset 7, team 6: offset 35
        assert_eq!(config.team_phase_offset(1), 0);
        assert_eq!(config.team_phase_offset(2), 7);
        assert_eq!(config.team_phase_offset(6), 35);
    }
}
