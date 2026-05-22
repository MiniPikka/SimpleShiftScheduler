use serde::{Deserialize, Serialize};

/// Shift type enum — matches Android `ShiftType.kt` and Flutter `shift_type.dart`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ShiftType {
    Morning,
    Afternoon,
    Rest,
    Night,
    Study,
}

impl ShiftType {
    /// Human-readable Chinese label for this shift type.
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

    /// Returns true if this shift type counts as a working day.
    pub fn is_work(&self) -> bool {
        matches!(self, ShiftType::Morning | ShiftType::Afternoon | ShiftType::Night)
    }

    /// Returns true if this shift type counts as a rest day.
    pub fn is_rest(&self) -> bool {
        matches!(self, ShiftType::Rest | ShiftType::Study)
    }
}

/// Result of querying shift info for a given date.
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
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShiftCycleConfig {
    /// The ordered list of shift types defining one full cycle.
    pub cycle: Vec<ShiftType>,
    /// Length of the cycle (= cycle.len()).
    pub cycle_length: u32,
    /// The anchor reference date (day 1 of the cycle).
    pub reference_date: chrono::NaiveDate,
    /// Total number of teams sharing this cycle.
    pub total_teams: u32,
}

impl ShiftCycleConfig {
    /// Team phase offset in days: (team_id - 1) * (cycle_length / total_teams).
    pub fn team_phase_offset(&self, team_id: u32) -> u32 {
        (team_id - 1) * (self.cycle_length / self.total_teams)
    }
}
