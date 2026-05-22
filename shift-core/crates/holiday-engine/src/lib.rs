//! # holiday-engine
//!
//! Chinese statutory holiday data.
//! Provides 2026 (officially published) and 2027 (estimated) holidays.
//!
//! Ported from Flutter `holiday_data.dart` and Android `holiday_data.kt`.
//!
//! TODO: Full 2026-2027 holiday data (Phase 1 Step 1.4)

use chrono::NaiveDate;

/// Information about a holiday or adjusted work day.
#[derive(Debug, Clone)]
pub struct HolidayInfo {
    pub date: NaiveDate,
    pub name: &'static str,
    /// true = statutory holiday (day off), false = adjusted work day (補班)
    pub is_holiday: bool,
    /// true = officially confirmed by State Council, false = estimated
    pub is_confirmed: bool,
}

/// Get all Chinese statutory holidays and adjusted work days.
/// Returns a Vec of HolidayInfo covering both 2026 and 2027.
pub fn get_china_holidays() -> Vec<HolidayInfo> {
    // TODO: Populate full 2026-2027 holiday data
    vec![]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn placeholder() {
        let holidays = get_china_holidays();
        // Will be non-empty once data is populated
        assert!(holidays.is_empty()); // placeholder assertion
    }
}
