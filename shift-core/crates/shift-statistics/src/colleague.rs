//! Colleague mode: find common rest days between two teams.
//!
//! Ported from Flutter `colleague_mode.dart` and Android `colleague_mode.kt`.

use chrono::NaiveDate;
use serde::Serialize;
use shift_algorithm::{get_shift_type_for_date, ShiftCycleConfig};

#[derive(Debug, Clone, Serialize)]
pub struct CommonRestResult {
    pub team_a_id: u32,
    pub team_b_id: u32,
    pub next_common_rest_date: Option<NaiveDate>,
    pub days_until_next: Option<u32>,
    pub common_rest_dates: Vec<NaiveDate>,
    pub total_count: u32,
    pub count_in_30_days: u32,
    pub count_in_60_days: u32,
}

/// Find common rest days between two teams over a given analysis window.
pub fn find_common_rest_days(
    team_a_id: u32,
    team_b_id: u32,
    today: NaiveDate,
    days_to_analyze: u32,
    config: &ShiftCycleConfig,
) -> CommonRestResult {
    let offset_a = config.team_phase_offset(team_a_id);
    let offset_b = config.team_phase_offset(team_b_id);

    let mut common_dates: Vec<NaiveDate> = Vec::new();
    let today_plus_30 = today + chrono::Duration::days(30);
    let today_plus_60 = today + chrono::Duration::days(60);

    for d in 0..days_to_analyze {
        let date = today + chrono::Duration::days(d as i64);
        let shift_a = get_shift_type_for_date(date, config, offset_a);
        let shift_b = get_shift_type_for_date(date, config, offset_b);

        if shift_a.is_rest() && shift_b.is_rest() {
            common_dates.push(date);
        }
    }

    let next = common_dates.first().copied();
    let days_until = next.map(|d| {
        let diff = (d - today).num_days();
        diff.max(0) as u32
    });

    let count_30 = common_dates
        .iter()
        .filter(|d| **d <= today_plus_30)
        .count() as u32;
    let count_60 = common_dates
        .iter()
        .filter(|d| **d <= today_plus_60)
        .count() as u32;

    CommonRestResult {
        team_a_id,
        team_b_id,
        next_common_rest_date: next,
        days_until_next: days_until,
        common_rest_dates: common_dates,
        total_count: count_60,
        count_in_30_days: count_30,
        count_in_60_days: count_60,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use shift_algorithm::cycle::default_config;

    #[test]
    fn same_team_finds_all_rest_days() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let result = find_common_rest_days(1, 1, today, 42, &config);
        // Same team → common rests = all its own rests
        assert!(result.common_rest_dates.len() >= 1);
        assert_eq!(result.team_a_id, result.team_b_id);
    }

    #[test]
    fn different_teams_produces_result() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let result = find_common_rest_days(1, 3, today, 90, &config);
        // Teams 1 and 3 have their offset difference → some common rests
        assert!(result.total_count <= 90);
        assert!(result.count_in_30_days <= result.count_in_60_days);
    }

    #[test]
    fn next_common_rest_is_in_future_or_none() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let result = find_common_rest_days(1, 4, today, 180, &config);
        if let Some(days) = result.days_until_next {
            assert!(days < 180);
        }
    }

    #[test]
    fn all_common_dates_are_within_window() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let window = 60u32;
        let result = find_common_rest_days(2, 5, today, window, &config);
        for date in &result.common_rest_dates {
            let diff = (*date - today).num_days();
            assert!(diff >= 0);
            assert!(diff < window as i64);
        }
        assert_eq!(result.total_count, result.common_rest_dates.len() as u32);
    }

    // ── Edge cases ──

    #[test]
    fn zero_day_window_returns_empty() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let result = find_common_rest_days(1, 2, today, 0, &config);
        assert!(result.common_rest_dates.is_empty());
        assert_eq!(result.total_count, 0);
        assert!(result.next_common_rest_date.is_none());
    }

    #[test]
    fn both_teams_all_rest_cycle_finds_every_day() {
        use shift_algorithm::ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Rest; 7],
            cycle_length: 7,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 2,
        };
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let result = find_common_rest_days(1, 2, today, 10, &config);
        assert_eq!(result.total_count, 10);
        assert_eq!(result.common_rest_dates.len(), 10);
    }

    #[test]
    fn both_teams_all_work_cycle_finds_nothing() {
        use shift_algorithm::ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning; 7],
            cycle_length: 7,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 2,
        };
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let result = find_common_rest_days(1, 2, today, 30, &config);
        assert_eq!(result.total_count, 0);
        assert!(result.common_rest_dates.is_empty());
    }

    #[test]
    fn counts_do_not_exceed_window() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let result = find_common_rest_days(1, 2, today, 20, &config);
        assert!(result.count_in_30_days <= result.common_rest_dates.len() as u32);
        assert!(result.count_in_60_days <= result.common_rest_dates.len() as u32);
    }
}
