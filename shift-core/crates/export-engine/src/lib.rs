//! # export-engine
//!
//! **ICS (RFC 5545) calendar export** for shift schedules.
//!
//! Generates standard `.ics` files that can be imported into any calendar
//! application: Thunderbird, GNOME Calendar, Nextcloud, Apple Calendar,
//! Google Calendar, Outlook.
//!
//! ## Planned features (Phase 2)
//!
//! - `generate_shift_ics()` — Full ICS file with VEVENT + RRULE + VALARM
//! - RRULE compression: 365 events → ~6 repeating events
//! - VTIMEZONE (Asia/Shanghai UTC+8)
//! - Night shift cross-midnight handling
//! - Holiday EXDATE overrides
//! - CalDAV sync (Phase 2+)
//!
//! ## Crate dependencies
//!
//! This crate sits at the top of the dependency chain:
//!
//! ```text
//! export-engine
//!   ├── shift-algorithm (cycle config, shift type query)
//!   ├── chrono (date/time handling)
//!   └── icalendar (RFC 5545 ICS generation) — coming
//! ```

/// Placeholder for ICS export. Full implementation in Phase 2.
pub fn export() -> &'static str {
    "export-engine: coming in Phase 2"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn placeholder() {
        assert_eq!(export(), "export-engine: coming in Phase 2");
    }
}
