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
            ShiftType::Rest => "Off",
            ShiftType::Night => "NT",
            ShiftType::Study => "TR",
        }
    }

    /// Padded English label (3 chars for alignment).
    pub fn label_en_padded(&self) -> &'static str {
        match self {
            ShiftType::Morning => "AM ",
            ShiftType::Afternoon => "PM ",
            ShiftType::Rest => "Off",
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

impl ShiftCycleConfig {
    /// Create a new config, validating that `cycle.len() == cycle_length`.
    ///
    /// # Panics
    /// Panics if `cycle.len() != cycle_length as usize`.
    pub fn new(cycle: Vec<ShiftType>, reference_date: chrono::NaiveDate, total_teams: u32) -> Self {
        let cycle_length = cycle.len() as u32;
        assert!(cycle_length >= 1, "cycle must be non-empty");
        assert!(total_teams >= 1, "total_teams must be >= 1");
        Self { cycle, cycle_length, reference_date, total_teams }
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
}
