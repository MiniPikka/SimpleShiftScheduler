//! # leave-optimizer
//!
//! **Leave strategy optimizer** using the *gap-merging algorithm*.
//!
//! Finds the best vacation strategies by bridging work gaps between rest blocks:
//! "If I take N days off, what's the longest continuous break I can get?"
//!
//! ## How it works
//!
//! 1. Build daily status for each day from today to Dec 31 (shift + holidays + weekends)
//! 2. Identify "rest blocks" (consecutive off days) and "work gaps" between them
//! 3. For each work gap ≤ max_leave_days: bridge it → merge adjacent rest blocks
//! 4. Score each strategy: 50% efficiency + 25% length + 25% family overlap
//! 5. Deduplicate (same break range → keep fewest leave days) and sort by score
//!
//! ## Example
//!
//! ```rust
//! use shift_algorithm::cycle::default_config;
//! use leave_optimizer::find_best_leave_plans;
//! use chrono::NaiveDate;
//!
//! let config = default_config();
//! let today = NaiveDate::from_ymd_opt(2026, 9, 1).unwrap();
//! let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
//!
//! for (i, s) in plans.iter().take(3).enumerate() {
//!     println!("{}: 请{}天 → 连休{}天 ({:.1}x)  {} – {}",
//!         i + 1, s.leave_days, s.total_break_days,
//!         s.efficiency, s.break_start, s.break_end);
//! }
//! ```

use chrono::NaiveDate;
use holiday_engine::{get_china_holidays, is_weekend, HolidayInfo};
use serde::Serialize;
use shift_algorithm::{get_shift_type_for_date, ShiftCycleConfig, ShiftType};
use std::collections::{HashMap, HashSet};

// ── Internal day status ──

#[derive(Debug, Clone)]
struct DayStatus {
    date: NaiveDate,
    is_rest: bool,
    is_holiday: bool,
    is_weekend: bool,
    is_adjusted_work_day: bool,
    holiday_name: Option<String>,
}

impl DayStatus {
    fn is_off(&self) -> bool {
        self.is_rest
            || (self.is_holiday && !self.is_adjusted_work_day)
            || (self.is_weekend && !self.is_adjusted_work_day)
    }
}

// ── Public types ──

/// A single leave strategy.
///
/// Returned by [`find_best_leave_plans`], sorted by score descending.
#[derive(Debug, Clone, Serialize)]
pub struct LeaveStrategy {
    /// Number of leave days needed.
    pub leave_days: u32,
    /// Total consecutive break days achieved (rest + weekend + holiday + leave).
    pub total_break_days: u32,
    /// The specific dates to request leave.
    pub leave_dates: Vec<NaiveDate>,
    /// First day of the continuous break.
    pub break_start: NaiveDate,
    /// Last day of the continuous break.
    pub break_end: NaiveDate,
    /// Number of statutory holiday days within the break.
    pub holiday_overlap: u32,
    /// Number of weekend days within the break.
    pub weekend_overlap: u32,
    /// Names of overlapping holidays (e.g. "国庆节", "春节").
    pub overlapping_holiday_names: Vec<String>,
    /// Efficiency ratio = total_break_days / leave_days (higher is better).
    pub efficiency: f64,
    /// Composite score 0..1 (50% efficiency + 25% length + 25% family).
    pub score: f64,
}

// ── Day status builder ──

fn build_daily_status(
    start_date: NaiveDate,
    days: u32,
    team_phase_offset: u32,
    config: &ShiftCycleConfig,
    holidays: &HashMap<NaiveDate, HolidayInfo>,
) -> Vec<DayStatus> {
    (0..days)
        .map(|offset| {
            let date = start_date + chrono::Duration::days(offset as i64);
            let shift_type = get_shift_type_for_date(date, config, team_phase_offset);
            let is_rest = matches!(shift_type, ShiftType::Rest | ShiftType::Study);
            let holiday_info = holidays.get(&date);
            let is_holiday = holiday_info.is_some_and(|h| h.is_holiday);
            let is_adjusted_work_day = holiday_info.is_some_and(|h| !h.is_holiday);
            let holiday_name = if is_holiday {
                holiday_info.map(|h| h.name.to_string())
            } else {
                None
            };
            DayStatus { date, is_rest, is_holiday, is_weekend: is_weekend(date), is_adjusted_work_day, holiday_name }
        })
        .collect()
}

// ── Main algorithm ──

/// Find the best leave strategies using gap-merging.
///
/// # Parameters
///
/// - `today` — analysis start date (typically `Local::now().date_naive()`)
/// - `days_to_analyze` — number of days to scan (e.g. days until Dec 31)
/// - `config` — shift cycle configuration
/// - `team_phase_offset` — team offset from [`ShiftCycleConfig::team_phase_offset`]
/// - `holidays` — holiday map; `None` uses built-in China holidays
/// - `max_leave_days` — max leave days to consider (typically 3-5)
///
/// # Returns
///
/// Strategies sorted by score descending. Empty if no valid strategies found.
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use leave_optimizer::find_best_leave_plans;
/// use chrono::NaiveDate;
///
/// let config = default_config();
/// let today = NaiveDate::from_ymd_opt(2026, 9, 1).unwrap();
/// let plans = find_best_leave_plans(today, 60, &config, 0, None, 5);
///
/// assert!(!plans.is_empty());
/// // Best strategy first
/// for w in plans.windows(2) {
///     assert!(w[0].score >= w[1].score);
/// }
/// ```
pub fn find_best_leave_plans(
    today: NaiveDate,
    days_to_analyze: u32,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
    holidays: Option<&HashMap<NaiveDate, HolidayInfo>>,
    max_leave_days: u32,
) -> Vec<LeaveStrategy> {
    if days_to_analyze < 1 || max_leave_days < 1 {
        return vec![];
    }

    let hols = holidays.cloned().unwrap_or_else(get_china_holidays);
    let status = build_daily_status(today, days_to_analyze, team_phase_offset, config, &hols);
    let n = status.len();

    let mut rest_before = vec![0u32; n];
    let mut rest_after = vec![0u32; n];

    for i in 1..n {
        rest_before[i] = if status[i - 1].is_off() { rest_before[i - 1] + 1 } else { 0 };
    }
    for i in (0..n - 1).rev() {
        rest_after[i] = if status[i + 1].is_off() { rest_after[i + 1] + 1 } else { 0 };
    }

    let mut strategies: Vec<LeaveStrategy> = Vec::new();
    let min_leave_days = if max_leave_days == 1 { 1 } else { 2 };

    for leave_days in min_leave_days..=max_leave_days {
        for start_idx in 0..=(n as i32 - leave_days as i32) {
            let start_idx = start_idx as usize;

            let has_shift_rest = (0..leave_days).any(|j| status[start_idx + j as usize].is_rest);
            if has_shift_rest { continue; }

            let left_rest = rest_before[start_idx];
            let right_rest = rest_after[start_idx + leave_days as usize - 1];
            let total_break = left_rest + leave_days + right_rest;
            if total_break <= leave_days { continue; }

            let gap_start = start_idx as i32 - left_rest as i32;
            let gap_end = start_idx as i32 + leave_days as i32 - 1 + right_rest as i32;
            let break_start_date = status[gap_start as usize].date;
            let break_end_date = status[gap_end as usize].date;

            let mut holiday_overlap = 0u32;
            let mut weekend_overlap = 0u32;
            let mut holiday_names: HashSet<String> = HashSet::new();

            for idx in gap_start..=gap_end {
                let ds = &status[idx as usize];
                if ds.is_holiday { holiday_overlap += 1; if let Some(ref name) = ds.holiday_name { holiday_names.insert(name.clone()); } }
                if ds.is_weekend && !ds.is_adjusted_work_day { weekend_overlap += 1; }
            }

            let leave_date_list: Vec<NaiveDate> = (0..leave_days)
                .map(|j| status[start_idx + j as usize].date)
                .collect();
            let efficiency = total_break as f64 / leave_days as f64;

            strategies.push(LeaveStrategy {
                leave_days, total_break_days: total_break,
                leave_dates: leave_date_list, break_start: break_start_date,
                break_end: break_end_date, holiday_overlap, weekend_overlap,
                overlapping_holiday_names: holiday_names.into_iter().collect(),
                efficiency, score: 0.0,
            });
        }
    }

    // Dedup: same (break_start, break_end) → keep fewest leave days
    let mut deduped: HashMap<String, LeaveStrategy> = HashMap::new();
    for s in strategies {
        let key = format!("{}_{}", s.break_start, s.break_end);
        match deduped.get(&key) {
            Some(existing) if existing.leave_days <= s.leave_days => {}
            _ => { deduped.insert(key, s); }
        }
    }
    if deduped.is_empty() { return vec![]; }

    let deduped_list: Vec<LeaveStrategy> = deduped.into_values().collect();

    let max_efficiency = deduped_list.iter().map(|s| s.efficiency).fold(0.0f64, f64::max);
    let max_break = deduped_list.iter().map(|s| s.total_break_days).max().unwrap_or(1);
    let max_family_bonus = deduped_list.iter().map(|s| s.holiday_overlap * 2 + s.weekend_overlap).max().unwrap_or(1).max(1);

    let mut scored: Vec<LeaveStrategy> = deduped_list.into_iter().map(|s| {
        let eff_score = if max_efficiency > 0.0 { s.efficiency / max_efficiency } else { 0.0 };
        let len_score = if max_break > 0 { s.total_break_days as f64 / max_break as f64 } else { 0.0 };
        let family_bonus = (s.holiday_overlap * 2 + s.weekend_overlap) as f64;
        let fam_score = family_bonus / max_family_bonus as f64;
        let score = 0.50 * eff_score + 0.25 * len_score + 0.25 * fam_score;
        LeaveStrategy { score, ..s }
    }).collect();

    // Stable sort: score desc, then break_start asc (earlier first)
    scored.sort_by(|a, b| {
        b.score.partial_cmp(&a.score)
            .unwrap_or(std::cmp::Ordering::Equal)
            .then_with(|| a.break_start.cmp(&b.break_start))
    });
    scored
}

#[cfg(test)]
mod tests {
    use super::*;
    use shift_algorithm::cycle::default_config;

    #[test]
    fn returns_empty_for_zero_analyze_days() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 0, &config, 0, None, 5);
        assert!(plans.is_empty());
    }

    #[test]
    fn returns_empty_for_zero_max_leave() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 0);
        assert!(plans.is_empty());
    }

    #[test]
    fn produces_strategies_with_default_config() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
        assert!(!plans.is_empty());
    }

    #[test]
    fn strategies_are_sorted_by_score_desc() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
        for w in plans.windows(2) {
            assert!(w[0].score >= w[1].score);
        }
    }

    #[test]
    fn total_break_exceeds_leave_days() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
        for s in &plans {
            assert!(s.total_break_days > s.leave_days);
        }
    }

    #[test]
    fn leave_dates_count_matches() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
        for s in &plans {
            assert_eq!(s.leave_dates.len() as u32, s.leave_days);
        }
    }

    #[test]
    fn no_duplicate_break_ranges() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 180, &config, 0, None, 5);
        let mut seen: HashSet<(NaiveDate, NaiveDate)> = HashSet::new();
        for s in &plans {
            let key = (s.break_start, s.break_end);
            assert!(seen.insert(key));
        }
    }

    #[test]
    fn respects_max_leave_days() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 3);
        for s in &plans {
            assert!(s.leave_days <= 3);
        }
    }

    #[test]
    fn dates_within_analysis_window() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let window = 60u32;
        let end = today + chrono::Duration::days(window as i64);
        let plans = find_best_leave_plans(today, window, &config, 0, None, 5);
        for s in &plans {
            assert!(s.break_start >= today);
            assert!(s.break_end < end);
        }
    }

    #[test]
    fn includes_national_day_strategies() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 9, 1).unwrap();
        let plans = find_best_leave_plans(today, 60, &config, 0, None, 5);
        let has_national_day = plans.iter().any(|s| {
            s.overlapping_holiday_names.iter().any(|n| n.contains("国庆"))
        });
        assert!(has_national_day);
    }

    #[test]
    fn different_team_produces_different_strategies() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans_team1 = find_best_leave_plans(today, 90, &config, 0, None, 5);
        let plans_team2 = find_best_leave_plans(today, 90, &config, 7, None, 5);
        let keys1: HashSet<String> = plans_team1.iter().map(|s| format!("{}_{}", s.break_start, s.break_end)).collect();
        let keys2: HashSet<String> = plans_team2.iter().map(|s| format!("{}_{}", s.break_start, s.break_end)).collect();
        assert_ne!(keys1, keys2);
    }

    #[test]
    fn custom_cycle_produces_strategies() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning, Afternoon, Rest, Night, Rest, Morning, Afternoon],
            cycle_length: 7,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 2,
            team_names: None,
            customization: Default::default(),
        };
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
        assert!(!plans.is_empty());
    }

    #[test]
    fn efficiency_is_at_least_one() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
        for s in &plans { assert!(s.efficiency >= 1.0); }
    }

    #[test]
    fn score_is_between_zero_and_one() {
        let config = default_config();
        let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let plans = find_best_leave_plans(today, 90, &config, 0, None, 5);
        for s in &plans { assert!((0.0..=1.01).contains(&s.score)); }
    }
}
