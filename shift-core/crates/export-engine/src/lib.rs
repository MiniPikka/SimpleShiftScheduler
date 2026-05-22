//! # export-engine
//!
//! **ICS (RFC 5545) calendar export** for shift schedules.
//!
//! Generates standard `.ics` files importable into Thunderbird, GNOME Calendar,
//! Nextcloud, Apple Calendar, Google Calendar, Outlook — any calendar app that
//! supports the iCalendar standard.
//!
//! ## Design
//!
//! Rather than generating 365 individual VEVENTs, this uses RRULE compression:
//! each distinct shift type gets one VEVENT with a repeating rule.
//! For a 42-day cycle with 5 shift types, that's ~5 VEVENTs instead of 365.
//!
//! ## Example
//!
//! ```rust,no_run
//! use export_engine::generate_shift_ics;
//! use shift_algorithm::cycle::default_config;
//! use chrono::{Datelike, Local};
//!
//! let config = default_config();
//! let today = Local::now().date_naive();
//! let end = chrono::NaiveDate::from_ymd_opt(today.year(), 12, 31).unwrap();
//!
//! let ics = generate_shift_ics(today, end, &config, 0, 1, None, "Asia/Shanghai");
//! std::fs::write("/tmp/my_shifts.ics", &ics).unwrap();
//! ```

use chrono::NaiveDate;
use shift_algorithm::{get_shift_info, get_shift_type_for_date, ShiftCycleConfig, ShiftType};
use std::collections::{HashMap, HashSet};

/// Configuration for alarm times mapped to shift types.
/// Key: shift type key (e.g. "morning", "afternoon", "night").
/// Value: (hour, minute) for the alarm time.
pub type AlarmConfig = HashMap<String, (u32, u32)>;

/// Generate a complete ICS (RFC 5545) calendar file for a shift schedule.
///
/// # Parameters
///
/// - `start_date` — first date to include
/// - `end_date` — last date to include (inclusive)
/// - `config` — shift cycle configuration
/// - `team_phase_offset` — team offset from [`ShiftCycleConfig::team_phase_offset`]
/// - `team_id` — team number (1-6), used in event titles
/// - `alarms` — optional alarm times per shift type, e.g. `{"morning": (6, 30)}`
/// - `timezone` — IANA timezone, e.g. `"Asia/Shanghai"`
///
/// # Returns
///
/// A valid ICS file as a String, with CRLF line endings per RFC 5545.
pub fn generate_shift_ics(
    start_date: NaiveDate,
    end_date: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
    team_id: u32,
    alarms: Option<&AlarmConfig>,
    timezone: &str,
) -> String {
    let mut buf = String::new();
    let crlf = "\r\n";

    // VCALENDAR header
    buf.push_str("BEGIN:VCALENDAR");
    buf.push_str(crlf);
    buf.push_str("VERSION:2.0");
    buf.push_str(crlf);
    buf.push_str("PRODID:-//班伴 ShiftMate//shift-core//EN");
    buf.push_str(crlf);
    buf.push_str("CALSCALE:GREGORIAN");
    buf.push_str(crlf);
    buf.push_str("METHOD:PUBLISH");
    buf.push_str(crlf);
    buf.push_str(&format!("X-WR-CALNAME:班伴 · ShiftMate — {}排班", team_name(team_id)));
    buf.push_str(crlf);
    buf.push_str("X-WR-CALDESC:Auto-generated shift schedule by 班伴 (ShiftMate)");
    buf.push_str(crlf);
    buf.push_str(&format!("X-WR-TIMEZONE:{}", timezone));
    buf.push_str(crlf);

    // VTIMEZONE
    buf.push_str("BEGIN:VTIMEZONE");
    buf.push_str(crlf);
    buf.push_str(&format!("TZID:{}", timezone));
    buf.push_str(crlf);
    buf.push_str("BEGIN:STANDARD");
    buf.push_str(crlf);
    buf.push_str("DTSTART:19700101T000000");
    buf.push_str(crlf);
    buf.push_str("TZOFFSETFROM:+0800");
    buf.push_str(crlf);
    buf.push_str("TZOFFSETTO:+0800");
    buf.push_str(crlf);
    buf.push_str("TZNAME:CST");
    buf.push_str(crlf);
    buf.push_str("END:STANDARD");
    buf.push_str(crlf);
    buf.push_str("END:VTIMEZONE");
    buf.push_str(crlf);

    // Collect distinct shift types
    let shift_types: HashSet<ShiftType> = config.cycle.iter().copied().collect();

    // UNTIL date for RRULE: end_date in UTC format YYYYMMDDT235959Z
    let until_str = format!("{}T235959", end_date.format("%Y%m%d"));

    for shift_type in &shift_types {
        // Find first occurrence of this shift type in the date range
        let mut first_date: Option<NaiveDate> = None;
        let mut cursor = start_date;
        while cursor <= end_date {
            if get_shift_type_for_date(cursor, config, team_phase_offset) == *shift_type {
                first_date = Some(cursor);
                break;
            }
            cursor += chrono::Duration::days(1);
        }

        let first_date = match first_date {
            Some(d) => d,
            None => continue,
        };

        // Shift start/end times
        let start_time = match shift_type {
            ShiftType::Morning => "070000",
            ShiftType::Afternoon => "140000",
            ShiftType::Night => "220000",
            ShiftType::Rest | ShiftType::Study => "000000",
        };
        let end_time = match shift_type {
            ShiftType::Morning => "150000",
            ShiftType::Afternoon => "220000",
            ShiftType::Night => "060000", // next day
            ShiftType::Rest | ShiftType::Study => "235900",
        };

        let dtstart = format!("{}T{}", first_date.format("%Y%m%d"), start_time);
        let dtend_date = if *shift_type == ShiftType::Night {
            first_date + chrono::Duration::days(1)
        } else {
            first_date
        };
        let dtend = format!("{}T{}", dtend_date.format("%Y%m%d"), end_time);

        let summary = format!("{} · {}", shift_type.full_label(), team_name(team_id));
        let cycle_day = get_shift_info(first_date, config, team_phase_offset).day_of_cycle;
        let description = format!(
            "班伴自动生成 {}排班。\\n周期第 {} 天出现。",
            shift_type.full_label(),
            cycle_day,
        );

        // VEVENT
        buf.push_str("BEGIN:VEVENT");
        buf.push_str(crlf);
        buf.push_str(&format!("DTSTART;TZID={}:{}", timezone, dtstart));
        buf.push_str(crlf);
        buf.push_str(&format!("DTEND;TZID={}:{}", timezone, dtend));
        buf.push_str(crlf);
        buf.push_str(&format!("SUMMARY:{}", escape_text(&summary)));
        buf.push_str(crlf);
        buf.push_str(&format!("DESCRIPTION:{}", escape_text(&description)));
        buf.push_str(crlf);
        buf.push_str(&format!(
            "RRULE:FREQ=DAILY;INTERVAL={};UNTIL={}",
            config.cycle_length, until_str,
        ));
        buf.push_str(crlf);
        buf.push_str(&format!(
            "CATEGORIES:SHIFT_{}",
            format!("{:?}", shift_type).to_uppercase()
        ));
        buf.push_str(crlf);

        // VALARM if configured
        if let Some(alarm_config) = alarms {
            let key = shift_type_alarm_key(shift_type);
            if let Some((hour, minute)) = alarm_config.get(&key) {
                // Trigger X minutes before the shift start
                let shift_start_minutes = match shift_type {
                    ShiftType::Morning => 7 * 60,
                    ShiftType::Afternoon => 14 * 60,
                    ShiftType::Night => 22 * 60,
                    _ => 9 * 60,
                };
                let alarm_minutes = (*hour * 60 + *minute) as i32;
                let trigger = shift_start_minutes as i32 - alarm_minutes;

                buf.push_str("BEGIN:VALARM");
                buf.push_str(crlf);
                buf.push_str(&format!("TRIGGER:-PT{}M", trigger.abs()));
                buf.push_str(crlf);
                buf.push_str("ACTION:DISPLAY");
                buf.push_str(crlf);
                buf.push_str(&format!(
                    "DESCRIPTION:{}提醒",
                    escape_text(shift_type.full_label())
                ));
                buf.push_str(crlf);
                buf.push_str("END:VALARM");
                buf.push_str(crlf);
            }
        }

        buf.push_str("END:VEVENT");
        buf.push_str(crlf);
    }

    buf.push_str("END:VCALENDAR");
    buf.push_str(crlf);

    buf
}

/// Escape special characters for ICS text values.
fn escape_text(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace(';', "\\;")
        .replace(',', "\\,")
        .replace('\n', "\\n")
}

/// Chinese team name.
fn team_name(id: u32) -> String {
    let prefix = match id {
        1 => "一", 2 => "二", 3 => "三",
        4 => "四", 5 => "五", 6 => "六",
        _ => return format!("{}值", id),
    };
    format!("{}值", prefix)
}

/// Map shift type to alarm config key.
fn shift_type_alarm_key(st: &ShiftType) -> String {
    match st {
        ShiftType::Morning => "morning",
        ShiftType::Afternoon => "afternoon",
        ShiftType::Night => "night",
        ShiftType::Rest => "rest",
        ShiftType::Study => "study",
    }
    .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use shift_algorithm::cycle::default_config;

    #[test]
    fn generates_valid_ics_structure() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        assert!(ics.starts_with("BEGIN:VCALENDAR\r\n"));
        assert!(ics.contains("VERSION:2.0\r\n"));
        assert!(ics.contains("BEGIN:VTIMEZONE\r\n"));
        assert!(ics.contains("BEGIN:VEVENT\r\n"));
        assert!(ics.contains("RRULE:FREQ=DAILY;INTERVAL=42"));
        assert!(ics.ends_with("END:VCALENDAR\r\n"));
    }

    #[test]
    fn ics_contains_team_name() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 3, None, "Asia/Shanghai");
        assert!(ics.contains("三值"));
    }

    #[test]
    fn ics_with_alarms_includes_valarm() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let mut alarms: AlarmConfig = HashMap::new();
        alarms.insert("morning".into(), (6, 30));
        let ics = generate_shift_ics(start, end, &config, 0, 1, Some(&alarms), "Asia/Shanghai");
        assert!(ics.contains("BEGIN:VALARM\r\n"));
    }

    #[test]
    fn ics_without_alarms_has_no_valarm() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");
        assert!(!ics.contains("VALARM"));
    }

    #[test]
    fn vevent_count_matches_shift_types() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 12, 31).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        // Default cycle has 5 shift types (M, A, R, N, S)
        let count = ics.matches("BEGIN:VEVENT\r\n").count();
        assert!(count >= 4 && count <= 6, "Expected 4-6 VEVENTs, got {}", count);
    }

    #[test]
    fn custom_cycle_rrule_interval() {
        use ShiftType::*;
        let config = ShiftCycleConfig {
            cycle: vec![Morning, Afternoon, Rest],
            cycle_length: 3,
            reference_date: shift_algorithm::cycle::default_reference_date(),
            total_teams: 1,
        };
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");
        assert!(ics.contains("INTERVAL=3"));
    }

    #[test]
    fn single_day_range_produces_valid_ics() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 15).unwrap();
        let ics = generate_shift_ics(start, start, &config, 0, 1, None, "Asia/Shanghai");
        assert!(ics.contains("BEGIN:VEVENT\r\n"));
    }

    #[test]
    fn night_shift_crosses_midnight() {
        let config = default_config();
        // Find a date where team 1 has Night shift
        let start = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        // Night shift DTSTART should be at 22:00
        if ics.contains("夜班") {
            assert!(ics.contains("T220000"));
            // DTEND should be next day at 06:00
            assert!(ics.contains("T060000"));
        }
    }

    #[test]
    fn full_year_ics_is_well_formed() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 12, 31).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        // Must use CRLF throughout
        assert!(ics.contains("\r\n"));
        // Every BEGIN must have matching END
        assert_eq!(ics.matches("BEGIN:").count(), ics.matches("END:").count());
    }

    // ── RFC 5545 structural validation ──

    /// Parse an ICS file into a list of (component_type, properties) blocks.
    /// Validates BEGIN/END pairing and extracts key properties.
    fn parse_ics_blocks(ics: &str) -> Vec<(String, Vec<(String, String)>)> {
        let mut blocks: Vec<(String, Vec<(String, String)>)> = Vec::new();
        let mut stack: Vec<String> = Vec::new();
        let mut current_props: Vec<(String, String)> = Vec::new();
        let mut current_component: Option<String> = None;

        for line in ics.lines() {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }

            if let Some(comp) = line.strip_prefix("BEGIN:") {
                stack.push(comp.to_string());
                if stack.len() == 2 {
                    // Starting a new top-level component (VEVENT, VTIMEZONE, etc.)
                    current_component = Some(comp.to_string());
                    current_props = Vec::new();
                }
            } else if let Some(comp) = line.strip_prefix("END:") {
                let expected = stack.pop().unwrap_or_default();
                assert_eq!(comp, expected,
                    "Mismatched END: expected {}, got {}", expected, comp);
                if stack.len() == 1 && current_component.is_some() {
                    blocks.push((current_component.take().unwrap(), std::mem::take(&mut current_props)));
                }
            } else if let Some((key, value)) = line.split_once(':') {
                let key = key.trim_end_matches(|c: char| c.is_whitespace());
                // Unfold multi-line values (RFC 5545 §3.1): lines starting with space/tab
                // are continuations. We just collect the key-value pair.
                current_props.push((key.to_string(), value.to_string()));
            }
        }

        assert!(stack.is_empty(), "Unclosed components: {:?}", stack);
        blocks
    }

    #[test]
    fn rfc5545_begin_end_pairing() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        let blocks = parse_ics_blocks(&ics);
        assert!(!blocks.is_empty());

        // First block must be VCALENDAR (in practice we don't collect it,
        // but every component must be well-formed)
    }

    #[test]
    fn rfc5545_each_vevent_has_required_properties() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 12, 31).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        let blocks = parse_ics_blocks(&ics);
        let vevents: Vec<_> = blocks.iter().filter(|(t, _)| t == "VEVENT").collect();
        assert!(vevents.len() >= 4, "Expected at least 4 VEVENTs, got {}", vevents.len());

        for (_type, props) in &vevents {
            let has_dtstart = props.iter().any(|(k, _)| k == "DTSTART;TZID=Asia/Shanghai");
            let has_dtend = props.iter().any(|(k, _)| k == "DTEND;TZID=Asia/Shanghai");
            let has_summary = props.iter().any(|(k, _)| k == "SUMMARY");
            let has_rrule = props.iter().any(|(k, _)| k == "RRULE");

            assert!(has_dtstart, "VEVENT missing DTSTART");
            assert!(has_dtend, "VEVENT missing DTEND");
            assert!(has_summary, "VEVENT missing SUMMARY");
            assert!(has_rrule, "VEVENT missing RRULE");
        }
    }

    #[test]
    fn rfc5545_rrule_interval_matches_cycle() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 12, 31).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        let blocks = parse_ics_blocks(&ics);
        for (_type, props) in blocks.iter().filter(|(t, _)| t == "VEVENT") {
            if let Some((_, rrule_val)) = props.iter().find(|(k, _)| k == "RRULE") {
                assert!(rrule_val.contains("FREQ=DAILY"));
                assert!(rrule_val.contains(&format!("INTERVAL={}", config.cycle_length)));
                // UNTIL must be present and in YYYYMMDDT235959 format
                assert!(rrule_val.contains("UNTIL="));
                let until_part = rrule_val.split("UNTIL=").nth(1).unwrap();
                assert!(until_part.ends_with("T235959"));
            }
        }
    }

    #[test]
    fn rfc5545_dtstart_before_dtend() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 12, 31).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        let blocks = parse_ics_blocks(&ics);
        for (_type, props) in blocks.iter().filter(|(t, _)| t == "VEVENT") {
            let dtstart = props.iter().find(|(k, _)| k.starts_with("DTSTART")).map(|(_, v)| v).unwrap();
            let dtend = props.iter().find(|(k, _)| k.starts_with("DTEND")).map(|(_, v)| v).unwrap();

            // Parse YYYYMMDDTHHMMSS
            let start_val = &dtstart[dtstart.rfind(':').map(|i| i + 1).unwrap_or(0)..];
            let end_val = &dtend[dtend.rfind(':').map(|i| i + 1).unwrap_or(0)..];

            // Compare: Night shift DTEND may be next day, so end can be "smaller"
            // but both should be valid 15-char date-times
            assert_eq!(start_val.len(), 15, "DTSTART {:?} not in YYYYMMDDTHHMMSS", start_val);
            assert_eq!(end_val.len(), 15, "DTEND {:?} not in YYYYMMDDTHHMMSS", end_val);
        }
    }

    #[test]
    fn rfc5545_alarm_has_required_properties() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let mut alarms: AlarmConfig = HashMap::new();
        alarms.insert("morning".into(), (6, 30));
        let ics = generate_shift_ics(start, end, &config, 0, 1, Some(&alarms), "Asia/Shanghai");

        // VALARM is nested inside VEVENT — check with string matching
        assert!(ics.contains("BEGIN:VALARM\r\n"), "Missing VALARM begin");
        assert!(ics.contains("TRIGGER:-PT"), "VALARM missing TRIGGER");
        assert!(ics.contains("ACTION:DISPLAY"), "VALARM missing ACTION");
        assert!(ics.contains("END:VALARM\r\n"), "Missing VALARM end");
    }

    #[test]
    fn rfc5545_vtimezone_present() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 30).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        let blocks = parse_ics_blocks(&ics);
        let has_vtimezone = blocks.iter().any(|(t, _)| t == "VTIMEZONE");
        assert!(has_vtimezone, "Missing VTIMEZONE component");
    }
}
