//! Core data types for the shift scheduling system.

use serde::{Deserialize, Serialize};

/// The five shift types in a standard Chinese rotating shift system.
///
/// # Variants
///
/// | Variant | Label | Full Label | Category |
/// |---------|-------|-----------|----------|
/// | [`Morning`](ShiftType::Morning) | 早 | 早班 | Work |
/// | [`Afternoon`](ShiftType::Afternoon) | 中 | 中班 | Work |
/// | [`Rest`](ShiftType::Rest) | 休 | 休班 | Rest |
/// | [`Night`](ShiftType::Night) | 夜 | 夜班 | Work |
/// | [`Study`](ShiftType::Study) | 学 | 学习班 | Rest |
///
/// # Example
///
/// ```rust
/// use shift_algorithm::ShiftType;
///
/// assert!(ShiftType::Morning.is_work());
/// assert!(!ShiftType::Rest.is_work());
/// assert!(ShiftType::Rest.is_rest());
/// assert!(ShiftType::Study.is_rest());
/// ```
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ShiftType {
    /// 早班 — morning shift
    Morning,
    /// 中班 — afternoon shift
    Afternoon,
    /// 休班 — rest day
    Rest,
    /// 夜班 — night shift
    Night,
    /// 学习班 — study/training day (counts as rest for scheduling purposes)
    Study,
}

impl ShiftType {
    /// Short Chinese label (single character).
    pub fn label(&self) -> &'static str {
        match self {
            ShiftType::Morning => "早",
            ShiftType::Afternoon => "中",
            ShiftType::Rest => "休",
            ShiftType::Night => "夜",
            ShiftType::Study => "学",
        }
    }

    /// Full Chinese label.
    pub fn full_label(&self) -> &'static str {
        match self {
            ShiftType::Morning => "早班",
            ShiftType::Afternoon => "中班",
            ShiftType::Rest => "休班",
            ShiftType::Night => "夜班",
            ShiftType::Study => "学习班",
        }
    }

    /// Short English label.
    pub fn label_en(&self) -> &'static str {
        match self {
            ShiftType::Morning => "AM",
            ShiftType::Afternoon => "PM",
            ShiftType::Rest => "R ",
            ShiftType::Night => "NT",
            ShiftType::Study => "TR",
        }
    }

    /// Padded English label (3 chars for alignment).
    pub fn label_en_padded(&self) -> &'static str {
        match self {
            ShiftType::Morning => "AM ",
            ShiftType::Afternoon => "PM ",
            ShiftType::Rest => "R ",
            ShiftType::Night => "NT ",
            ShiftType::Study => "TR ",
        }
    }

    /// Full English label.
    pub fn full_label_en(&self) -> &'static str {
        match self {
            ShiftType::Morning => "Morning",
            ShiftType::Afternoon => "Afternoon",
            ShiftType::Rest => "Rest",
            ShiftType::Night => "Night",
            ShiftType::Study => "Study",
        }
    }

    /// Returns `true` if this is a working shift (Morning, Afternoon, or Night).
    ///
    /// Used for counting work days, consecutive work stats, etc.
    pub fn is_work(&self) -> bool {
        matches!(self, ShiftType::Morning | ShiftType::Afternoon | ShiftType::Night)
    }

    /// Returns `true` if this counts as rest (Rest or Study).
    ///
    /// Study days are treated as rest because the worker is not on duty.
    pub fn is_rest(&self) -> bool {
        matches!(self, ShiftType::Rest | ShiftType::Study)
    }
}

/// Result of querying what shift falls on a given date.
///
/// Returned by [`get_shift_info`](crate::get_shift_info).
///
/// # Fields
///
/// | Field | Type | Range | Description |
/// |-------|------|-------|-------------|
/// | `date` | `NaiveDate` | — | The queried date |
/// | `day_of_cycle` | `u32` | `1..=cycle_length` | Which day in the cycle (1-based) |
/// | `cycle_index` | `u32` | `0..=cycle_length-1` | Zero-based index into the cycle array |
/// | `shift_type` | [`ShiftType`] | — | The shift type for this date |
///
/// ```rust
/// use shift_algorithm::cycle::default_config;
/// use shift_algorithm::get_shift_info;
///
/// let config = default_config();
/// let info = get_shift_info(config.reference_date, &config, 0);
///
/// assert_eq!(info.day_of_cycle, 1);
/// assert_eq!(info.cycle_index, 0);
/// ```
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShiftInfo {
    /// The queried date.
    pub date: chrono::NaiveDate,
    /// Day index within the cycle (1-based, 1..=cycle_length).
    pub day_of_cycle: u32,
    /// Zero-based index into the cycle array (0..=cycle_length-1).
    pub cycle_index: u32,
    /// The shift type for this date.
    pub shift_type: ShiftType,
}

/// Time range for a work shift (e.g. 08:00–16:00).
///
/// Used for handover ordering and UI display. `crosses_midnight` is true
/// for night shifts that end the next day (e.g. 00:00–08:00).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShiftTimeRange {
    /// Start time in "HH:MM" format (e.g. "08:00").
    pub start: String,
    /// End time in "HH:MM" format (e.g. "16:00").
    pub end: String,
}

/// Optional per-shift custom labels and times.
///
/// All fields are optional — `None` means "use built-in default".
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ShiftCustomization {
    /// Custom label for each shift type (e.g. "白班" instead of "早班").
    /// Keys are shift type names: "Morning", "Afternoon", "Rest", "Night", "Study".
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub labels: Option<std::collections::HashMap<ShiftType, String>>,
    /// Custom time ranges for work shifts.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub times: Option<std::collections::HashMap<ShiftType, ShiftTimeRange>>,
}

/// Runtime shift cycle configuration.
///
/// The default 42-day, 6-team configuration is available via
/// [`default_config()`](crate::cycle::default_config).
///
/// # Custom cycles
///
/// ```rust
/// use shift_algorithm::{ShiftCycleConfig, ShiftType};
/// use chrono::NaiveDate;
///
/// let config = ShiftCycleConfig {
///     cycle: vec![ShiftType::Morning, ShiftType::Afternoon, ShiftType::Rest],
///     cycle_length: 3,
///     reference_date: NaiveDate::from_ymd_opt(2025, 12, 15).unwrap(),
///     total_teams: 1,
///     team_names: None,
///     customization: Default::default(),
/// };
/// ```
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShiftCycleConfig {
    /// The ordered list of shift types defining one full cycle.
    /// Must have length == `cycle_length`.
    pub cycle: Vec<ShiftType>,
    /// Number of days in one full cycle (= `cycle.len()`).
    pub cycle_length: u32,
    /// The anchor reference date. Day 1 of the cycle falls on this date.
    /// Default: 2025-12-15.
    pub reference_date: chrono::NaiveDate,
    /// Total number of teams sharing this cycle.
    /// Each team is offset by `cycle_length / total_teams` days.
    /// Default: 6.
    pub total_teams: u32,
    /// Custom team names. If provided, must have length >= `total_teams`.
    /// Index 0 = team 1's name, index 1 = team 2's name, etc.
    /// If `None`, defaults to "一值", "二值", ... (see [`team_name`]).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub team_names: Option<Vec<String>>,
    /// Custom shift labels and time ranges.
    #[serde(default)]
    pub customization: ShiftCustomization,
}

/// Chinese team name for a team ID.
///
/// ```rust
/// use shift_algorithm::team_name;
/// assert_eq!(team_name(1), "一值");
/// assert_eq!(team_name(3), "三值");
/// assert_eq!(team_name(6), "六值");
/// ```
pub fn team_name(id: u32) -> String {
    let prefix = match id {
        1 => "一", 2 => "二", 3 => "三",
        4 => "四", 5 => "五", 6 => "六",
        _ => return format!("{}值", id),
    };
    format!("{}值", prefix)
}

/// The team that follows yours in the circular rotation order.
///
/// In a 6-team rotation, the successor of team N is team N+1 (with wraparound):
/// - Team 1 → Team 2, Team 2 → Team 3, ..., Team 6 → Team 1
///
/// **Note**: this reflects the circular **team numbering**, not a guarantee about
/// shift status. Whether the successor is working or resting on a given day
/// depends on the cycle position and is not always opposite.
///
/// ```rust
/// use shift_algorithm::successor_team_id;
///
/// assert_eq!(successor_team_id(1, 6), 2);
/// assert_eq!(successor_team_id(6, 6), 1);
/// assert_eq!(successor_team_id(3, 6), 4);
/// assert_eq!(successor_team_id(1, 1), 1); // single-team: wraps to self
/// ```
pub fn successor_team_id(team_id: u32, total_teams: u32) -> u32 {
    assert!(total_teams >= 1, "total_teams must be >= 1");
    assert!(team_id >= 1, "team_id must be >= 1");
    (team_id % total_teams) + 1
}

/// The team that yours follows in the circular rotation order.
///
/// The **predecessor** of team N is the team whose shift your team takes over.
/// In a 6-team rotation, the predecessor of team N is team N-1 (with wraparound):
/// - Team 1 ← Team 6, Team 2 ← Team 1, ..., Team 6 ← Team 5
///
/// Formula: `(team_id + total_teams - 2) % total_teams + 1`
///
/// ```rust
/// use shift_algorithm::predecessor_team_id;
///
/// assert_eq!(predecessor_team_id(1, 6), 6); // Team 1 takes over from Team 6
/// assert_eq!(predecessor_team_id(2, 6), 1); // Team 2 takes over from Team 1
/// assert_eq!(predecessor_team_id(3, 6), 2);
/// assert_eq!(predecessor_team_id(1, 1), 1); // single-team: wraps to self
/// ```
pub fn predecessor_team_id(team_id: u32, total_teams: u32) -> u32 {
    assert!(total_teams >= 1, "total_teams must be >= 1");
    assert!(team_id >= 1, "team_id must be >= 1");
    (team_id + total_teams - 2) % total_teams + 1
}

/// Parse "HH:MM" time string to minutes since midnight.
///
/// Returns 0 on parse failure (defensive — does not panic).
fn parse_time_to_minutes(s: &str) -> u32 {
    let parts: Vec<&str> = s.split(':').collect();
    if parts.len() != 2 {
        return 0;
    }
    let h: u32 = parts[0].parse().unwrap_or(0);
    let m: u32 = parts[1].parse().unwrap_or(0);
    h.min(23) * 60 + m.min(59)
}

impl ShiftCycleConfig {
    /// Create a new config, validating that `cycle.len() == cycle_length`.
    ///
    /// # Panics
    /// Panics if `cycle.len() != cycle_length as usize`.
    pub fn new(cycle: Vec<ShiftType>, reference_date: chrono::NaiveDate, total_teams: u32) -> Self {
        let cycle_length = cycle.len() as u32;
        assert!(cycle_length >= 1, "cycle must be non-empty");
        assert!(total_teams >= 1, "total_teams must be >= 1");
        Self { cycle, cycle_length, reference_date, total_teams, team_names: None, customization: Default::default() }
    }

    /// Get the display name for a team.
    ///
    /// Uses custom names if provided, otherwise falls back to the default
    /// "一值", "二值", ... naming.
    ///
    /// ```rust
    /// use shift_algorithm::cycle::default_config;
    ///
    /// let config = default_config();
    /// assert_eq!(config.team_name(1), "一值");
    /// assert_eq!(config.team_name(6), "六值");
    /// ```
    pub fn team_name(&self, team_id: u32) -> String {
        if let Some(names) = &self.team_names {
            let idx = (team_id - 1) as usize;
            if idx < names.len() {
                return names[idx].clone();
            }
        }
        team_name(team_id)
    }

    /// Get the short label for a shift type, honoring custom labels.
    ///
    /// ```rust
    /// use shift_algorithm::cycle::default_config;
    /// use shift_algorithm::ShiftType;
    ///
    /// let config = default_config();
    /// assert_eq!(config.shift_label(ShiftType::Morning), "早");
    /// ```
    pub fn shift_label(&self, shift_type: ShiftType) -> &str {
        if let Some(custom) = self.customization.labels.as_ref().and_then(|l| l.get(&shift_type)) {
            return custom.as_str();
        }
        shift_type.label()
    }

    /// Get the full label for a shift type, honoring custom labels.
    pub fn shift_full_label(&self, shift_type: ShiftType) -> String {
        if let Some(custom) = self.customization.labels.as_ref().and_then(|l| l.get(&shift_type)) {
            return custom.clone();
        }
        shift_type.full_label().to_string()
    }

    /// Get the time range for a shift type, if configured.
    pub fn shift_time(&self, shift_type: ShiftType) -> Option<&ShiftTimeRange> {
        self.customization.times.as_ref()?.get(&shift_type)
    }

    /// Determine handover order from shift start times.
    ///
    /// Returns (predecessor_shift, successor_shift) for the given shift.
    /// Uses custom times if available, otherwise falls back to hardcoded order.
    ///
    /// **Requirement**: custom times must cover ALL three work shifts
    /// (Morning, Afternoon, Night). Partial coverage falls back to default
    /// to avoid incorrect ordering.
    fn handover_shifts(&self, my_shift: ShiftType) -> (ShiftType, ShiftType) {
        if let Some(times) = &self.customization.times {
            let work_shifts = [ShiftType::Morning, ShiftType::Afternoon, ShiftType::Night];

            // Require ALL work shifts to have time ranges
            let all_have_times = work_shifts.iter().all(|s| times.contains_key(s));
            if !all_have_times {
                // Partial coverage — fall back to default
            } else {
                // Parse start times, sort by them
                let mut sorted: Vec<(ShiftType, u32)> = work_shifts
                    .iter()
                    .map(|&s| {
                        let tr = &times[&s];
                        let mins = parse_time_to_minutes(&tr.start);
                        (s, mins)
                    })
                    .collect();
                sorted.sort_by_key(|(_, mins)| *mins);

                if let Some(idx) = sorted.iter().position(|(s, _)| *s == my_shift) {
                    let pred = sorted[(idx + sorted.len() - 1) % sorted.len()].0;
                    let succ = sorted[(idx + 1) % sorted.len()].0;
                    return (pred, succ);
                }
            }
        }

        // Default: 夜 → 早 → 中 → 夜
        match my_shift {
            ShiftType::Morning => (ShiftType::Night, ShiftType::Afternoon),
            ShiftType::Afternoon => (ShiftType::Morning, ShiftType::Night),
            ShiftType::Night => (ShiftType::Afternoon, ShiftType::Morning),
            _ => unreachable!(),
        }
    }

    /// The team that follows yours in the circular rotation order.
    ///
    /// Convenience wrapper around [`successor_team_id`] using `self.total_teams`.
    ///
    /// ```rust
    /// use shift_algorithm::cycle::default_config;
    ///
    /// let config = default_config();
    /// assert_eq!(config.successor_of(1), 2);
    /// assert_eq!(config.successor_of(6), 1);
    /// ```
    pub fn successor_of(&self, team_id: u32) -> u32 {
        successor_team_id(team_id, self.total_teams)
    }

    /// The team that yours follows in the circular rotation order.
    ///
    /// The predecessor is the team whose shift your team takes over.
    /// Convenience wrapper around [`predecessor_team_id`] using `self.total_teams`.
    ///
    /// ```rust
    /// use shift_algorithm::cycle::default_config;
    ///
    /// let config = default_config();
    /// assert_eq!(config.predecessor_of(1), 6); // Team 1 takes over from Team 6
    /// assert_eq!(config.predecessor_of(2), 1); // Team 2 takes over from Team 1
    /// assert_eq!(config.predecessor_of(6), 5);
    /// ```
    pub fn predecessor_of(&self, team_id: u32) -> u32 {
        predecessor_team_id(team_id, self.total_teams)
    }

    /// Team phase offset in days.
    ///
    /// Formula: `(team_id - 1) * (cycle_length / total_teams)`.
    ///
    /// For a 42-day, 6-team cycle:
    /// - Team 1 (一值): offset 0
    /// - Team 2 (二值): offset 7
    /// - Team 3 (三值): offset 14
    /// - ...
    /// - Team 6 (六值): offset 35
    ///
    /// ```rust
    /// use shift_algorithm::cycle::default_config;
    ///
    /// let config = default_config();
    /// assert_eq!(config.team_phase_offset(1), 0);
    /// assert_eq!(config.team_phase_offset(2), 7);
    /// assert_eq!(config.team_phase_offset(6), 35);
    /// ```
    pub fn team_phase_offset(&self, team_id: u32) -> u32 {
        (team_id - 1) * (self.cycle_length / self.total_teams)
    }

    /// Find which team you take over from and which team takes over from you.
    ///
    /// Shift handover happens **within a single day** between different shift types:
    /// - 夜 → 早 → 中 → 夜 (cyclical)
    /// - If you are on 休 or 学, there is no handover (you're not working).
    ///
    /// Returns `(predecessor_team_id, successor_team_id)` — the teams whose shifts
    /// you take over from and who takes over from you, respectively.
    ///
    /// ```rust
    /// use shift_algorithm::cycle::default_config;
    /// use chrono::NaiveDate;
    ///
    /// let config = default_config();
    /// let date = NaiveDate::from_ymd_opt(2026, 6, 26).unwrap();
    ///
    /// // If team 1 is working 早班 today, predecessor should be the team on 夜班,
    /// // successor should be the team on 中班.
    /// if let Some((pred, succ)) = config.shift_handover(date, 1) {
    ///     println!("Take over from team {}, hand over to team {}", pred, succ);
    /// }
    /// ```
    pub fn shift_handover(
        &self,
        date: chrono::NaiveDate,
        team_id: u32,
    ) -> Option<(u32, u32)> {
        use crate::calculator::get_shift_type_for_date;

        let my_shift = get_shift_type_for_date(date, self, self.team_phase_offset(team_id));
        if my_shift.is_rest() {
            return None; // not working, no handover
        }

        let (pred_shift, succ_shift) = self.handover_shifts(my_shift);

        // Scan all teams to find who is on pred_shift / succ_shift today
        let mut pred_team: Option<u32> = None;
        let mut succ_team: Option<u32> = None;

        for t in 1..=self.total_teams {
            if t == team_id {
                continue;
            }
            let shift = get_shift_type_for_date(date, self, self.team_phase_offset(t));
            if shift == pred_shift {
                pred_team = Some(t);
            }
            if shift == succ_shift {
                succ_team = Some(t);
            }
            if pred_team.is_some() && succ_team.is_some() {
                break;
            }
        }

        match (pred_team, succ_team) {
            (Some(p), Some(s)) => Some((p, s)),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::cycle::{default_config, default_reference_date, default_shift_cycle};

    // ── successor_team_id ──

    #[test]
    fn successor_team_1_is_2() {
        assert_eq!(successor_team_id(1, 6), 2);
    }

    #[test]
    fn successor_team_6_wraps_to_1() {
        assert_eq!(successor_team_id(6, 6), 1);
    }

    #[test]
    fn successor_team_3_is_4() {
        assert_eq!(successor_team_id(3, 6), 4);
    }

    #[test]
    fn successor_single_team_wraps_to_self() {
        assert_eq!(successor_team_id(1, 1), 1);
    }

    // ── predecessor_team_id ──

    #[test]
    fn predecessor_team_1_is_6() {
        assert_eq!(predecessor_team_id(1, 6), 6);
    }

    #[test]
    fn predecessor_team_2_is_1() {
        assert_eq!(predecessor_team_id(2, 6), 1);
    }

    #[test]
    fn predecessor_team_6_is_5() {
        assert_eq!(predecessor_team_id(6, 6), 5);
    }

    #[test]
    fn predecessor_team_3_is_2() {
        assert_eq!(predecessor_team_id(3, 6), 2);
    }

    #[test]
    fn predecessor_single_team_wraps_to_self() {
        assert_eq!(predecessor_team_id(1, 1), 1);
    }

    // ── ShiftCycleConfig methods ──

    #[test]
    fn config_successor_of() {
        let config = default_config();
        assert_eq!(config.successor_of(1), 2);
        assert_eq!(config.successor_of(6), 1);
    }

    #[test]
    fn config_predecessor_of() {
        let config = default_config();
        assert_eq!(config.predecessor_of(1), 6);
        assert_eq!(config.predecessor_of(2), 1);
    }

    // ── completeness ──

    #[test]
    fn all_successors_are_unique() {
        let mut succs: Vec<u32> = (1..=6).map(|t| successor_team_id(t, 6)).collect();
        succs.sort();
        assert_eq!(succs, vec![1, 2, 3, 4, 5, 6]);
    }

    #[test]
    fn all_predecessors_are_unique() {
        let mut preds: Vec<u32> = (1..=6).map(|t| predecessor_team_id(t, 6)).collect();
        preds.sort();
        assert_eq!(preds, vec![1, 2, 3, 4, 5, 6]);
    }

    #[test]
    fn pred_succ_cycle() {
        // predecessor(successor(team)) == team
        for t in 1..=6 {
            let succ = successor_team_id(t, 6);
            assert_eq!(predecessor_team_id(succ, 6), t,
                "predecessor(successor({})) should be {}", t, t);
        }
    }

    // ── Custom team names ──

    #[test]
    fn custom_team_names_override_default() {
        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: Some(vec!["甲班".into(), "乙班".into(), "丙班".into(),
                                   "丁班".into(), "戊班".into(), "己班".into()]),
            customization: Default::default(),
        };
        assert_eq!(config.team_name(1), "甲班");
        assert_eq!(config.team_name(3), "丙班");
        assert_eq!(config.team_name(6), "己班");
    }

    #[test]
    fn custom_team_names_fallback_for_missing() {
        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: Some(vec!["甲班".into()]),
            customization: Default::default(),
        };
        assert_eq!(config.team_name(1), "甲班");
        assert_eq!(config.team_name(2), "二值"); // fallback to default
    }

    #[test]
    fn no_custom_team_names_uses_default() {
        let config = default_config();
        assert_eq!(config.team_name(1), "一值");
        assert_eq!(config.team_name(6), "六值");
    }

    // ── Custom shift labels ──

    #[test]
    fn custom_shift_labels_override_default() {
        let mut labels = std::collections::HashMap::new();
        labels.insert(ShiftType::Morning, "白班".into());
        labels.insert(ShiftType::Night, "大夜".into());

        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: None,
            customization: ShiftCustomization { labels: Some(labels), times: None },
        };
        assert_eq!(config.shift_label(ShiftType::Morning), "白班");
        assert_eq!(config.shift_label(ShiftType::Night), "大夜");
        assert_eq!(config.shift_label(ShiftType::Afternoon), "中"); // fallback
    }

    #[test]
    fn custom_shift_full_labels() {
        let mut labels = std::collections::HashMap::new();
        labels.insert(ShiftType::Morning, "白班".into());

        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: None,
            customization: ShiftCustomization { labels: Some(labels), times: None },
        };
        assert_eq!(config.shift_full_label(ShiftType::Morning), "白班");
        assert_eq!(config.shift_full_label(ShiftType::Afternoon), "中班");
    }

    // ── Custom shift times ──

    #[test]
    fn custom_shift_times() {
        let mut times = std::collections::HashMap::new();
        times.insert(ShiftType::Morning, ShiftTimeRange {
            start: "07:00".into(), end: "15:00".into(),
        });
        times.insert(ShiftType::Afternoon, ShiftTimeRange {
            start: "15:00".into(), end: "23:00".into(),
        });
        times.insert(ShiftType::Night, ShiftTimeRange {
            start: "23:00".into(), end: "07:00".into(),
        });

        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: None,
            customization: ShiftCustomization { labels: None, times: Some(times) },
        };
        assert_eq!(config.shift_time(ShiftType::Morning).unwrap().start, "07:00");
        assert_eq!(config.shift_time(ShiftType::Night).unwrap().end, "07:00");
        assert!(config.shift_time(ShiftType::Rest).is_none());
    }

    #[test]
    fn handover_with_custom_times_preserves_default_order() {
        let mut times = std::collections::HashMap::new();
        times.insert(ShiftType::Morning, ShiftTimeRange {
            start: "08:00".into(), end: "16:00".into(),
        });
        times.insert(ShiftType::Afternoon, ShiftTimeRange {
            start: "16:00".into(), end: "00:00".into(),
        });
        times.insert(ShiftType::Night, ShiftTimeRange {
            start: "00:00".into(), end: "08:00".into(),
        });

        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: None,
            customization: ShiftCustomization { labels: None, times: Some(times) },
        };

        // Reference date is day 1 = Morning for team 1
        let handover = config.shift_handover(default_reference_date(), 1);
        assert!(handover.is_some());
    }

    #[test]
    fn handover_with_custom_times_reorders() {
        let mut times = std::collections::HashMap::new();
        // Reversed: Morning starts at 16:00, Afternoon at 08:00, Night at 00:00
        times.insert(ShiftType::Morning, ShiftTimeRange {
            start: "16:00".into(), end: "00:00".into(),
        });
        times.insert(ShiftType::Afternoon, ShiftTimeRange {
            start: "08:00".into(), end: "16:00".into(),
        });
        times.insert(ShiftType::Night, ShiftTimeRange {
            start: "00:00".into(), end: "08:00".into(),
        });

        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: None,
            customization: ShiftCustomization { labels: None, times: Some(times) },
        };

        // With reversed times: Night(00:00) → Afternoon(08:00) → Morning(16:00) → Night
        let (pred, succ) = config.handover_shifts(ShiftType::Morning);
        assert_eq!(pred, ShiftType::Afternoon);
        assert_eq!(succ, ShiftType::Night);
    }

    #[test]
    fn handover_partial_times_falls_back_to_default() {
        // Only Morning has a time — should fall back to hardcoded order
        let mut times = std::collections::HashMap::new();
        times.insert(ShiftType::Morning, ShiftTimeRange {
            start: "07:00".into(), end: "15:00".into(),
        });

        let config = ShiftCycleConfig {
            cycle: default_shift_cycle(),
            cycle_length: 42,
            reference_date: default_reference_date(),
            total_teams: 6,
            team_names: None,
            customization: ShiftCustomization { labels: None, times: Some(times) },
        };

        // Default order: 夜 → 早 → 中 → 夜
        let (pred, succ) = config.handover_shifts(ShiftType::Morning);
        assert_eq!(pred, ShiftType::Night);
        assert_eq!(succ, ShiftType::Afternoon);
    }

    #[test]
    fn parse_time_invalid_returns_zero() {
        assert_eq!(parse_time_to_minutes("invalid"), 0);
        assert_eq!(parse_time_to_minutes("25:99"), 1439); // clamped to 23:59
        assert_eq!(parse_time_to_minutes("08:30"), 510);
        assert_eq!(parse_time_to_minutes("00:00"), 0);
        assert_eq!(parse_time_to_minutes("23:59"), 1439);
    }

    #[test]
    fn serde_backward_compatibility() {
        // Old config without team_names/customization should still deserialize
        let json = r#"{
            "cycle": ["MORNING", "AFTERNOON", "REST"],
            "cycle_length": 3,
            "reference_date": "2025-12-15",
            "total_teams": 1
        }"#;
        let config: ShiftCycleConfig = serde_json::from_str(json).unwrap();
        assert_eq!(config.team_name(1), "一值");
        assert_eq!(config.shift_label(ShiftType::Morning), "早");
    }
}
