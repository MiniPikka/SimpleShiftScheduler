//! # export-engine
//!
//! **ICS (RFC 5545) calendar export** for shift schedules.
//!
//! Generates standard `.ics` files importable into Thunderbird, GNOME Calendar,
//! Nextcloud, Apple Calendar, Google Calendar, Outlook.
//!
//! ## Design
//!
//! One VEVENT per day — simple, correct, no RRULE complexity.
//! A full year produces ~365 VEVENTs (~50KB), well within ICS limits.
//!
//! The earlier RRULE approach was abandoned because shift types appear at
//! multiple irregular positions within a cycle (e.g. Morning appears 7 times
//! in 42 days), which can't be expressed as a single `FREQ=DAILY;INTERVAL=42`.

use chrono::NaiveDate;
use shift_algorithm::{get_shift_type_for_date, ShiftCycleConfig, ShiftType};
use std::collections::HashMap;

/// Configuration for alarm times. Key: shift type name ("morning", etc.), Value: (hour, minute).
pub type AlarmConfig = HashMap<String, (u32, u32)>;

/// Generate an ICS calendar file covering a date range.
///
/// One VEVENT per day. Night shifts cross midnight (DTSTART 22:00 → DTEND next day 06:00).
/// Rest/Study are all-day events. Morning/Afternoon have configurable start times.
pub fn generate_shift_ics(
    start_date: NaiveDate,
    end_date: NaiveDate,
    config: &ShiftCycleConfig,
    team_phase_offset: u32,
    team_id: u32,
    alarms: Option<&AlarmConfig>,
    timezone: &str,
) -> String {
    let crlf = "\r\n";
    let mut buf = String::new();

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
    buf.push_str(&format!("X-WR-CALNAME:班伴 · {}排班", config.team_name(team_id)));
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

    // One VEVENT per day
    let mut cursor = start_date;
    while cursor <= end_date {
        let shift_type = get_shift_type_for_date(cursor, config, team_phase_offset);

        let (start_hhmm, end_hhmm, end_date) = match shift_type {
            ShiftType::Morning => ("070000", "150000", cursor),
            ShiftType::Afternoon => ("140000", "220000", cursor),
            ShiftType::Night => ("220000", "060000", cursor + chrono::Duration::days(1)),
            ShiftType::Rest | ShiftType::Study => ("000000", "235900", cursor),
        };

        let dtstart = format!("{}T{}", cursor.format("%Y%m%d"), start_hhmm);
        let dtend = format!("{}T{}", end_date.format("%Y%m%d"), end_hhmm);

        let summary = format!("{} · {}", config.shift_full_label(shift_type), config.team_name(team_id));

        let day_info = shift_algorithm::get_shift_info(cursor, config, team_phase_offset);

        buf.push_str("BEGIN:VEVENT");
        buf.push_str(crlf);
        buf.push_str(&format!("DTSTART;TZID={}:{}", timezone, dtstart));
        buf.push_str(crlf);
        buf.push_str(&format!("DTEND;TZID={}:{}", timezone, dtend));
        buf.push_str(crlf);
        buf.push_str(&format!("SUMMARY:{}", ics_escape(&summary)));
        buf.push_str(crlf);
        buf.push_str(&format!(
            "DESCRIPTION:周期第 {}/{} 天",
            day_info.day_of_cycle, config.cycle_length,
        ));
        buf.push_str(crlf);
        buf.push_str(&format!(
            "CATEGORIES:SHIFT_{}",
            format!("{:?}", shift_type).to_uppercase()
        ));
        buf.push_str(crlf);

        // VALARM if this shift type has an alarm configured
        if let Some(alarm_cfg) = alarms {
            let key = shift_alarm_key(&shift_type);
            if let Some((hour, minute)) = alarm_cfg.get(&key) {
                let shift_start_min = match shift_type {
                    ShiftType::Morning => 7 * 60,
                    ShiftType::Afternoon => 14 * 60,
                    ShiftType::Night => 22 * 60,
                    _ => 9 * 60,
                };
                let alarm_min = (*hour * 60 + *minute) as i32;
                let trigger = (shift_start_min as i32 - alarm_min).abs();

                buf.push_str("BEGIN:VALARM");
                buf.push_str(crlf);
                buf.push_str(&format!("TRIGGER:-PT{}M", trigger));
                buf.push_str(crlf);
                buf.push_str("ACTION:DISPLAY");
                buf.push_str(crlf);
                buf.push_str(&format!(
                    "DESCRIPTION:{}提醒",
                    ics_escape(&config.shift_full_label(shift_type))
                ));
                buf.push_str(crlf);
                buf.push_str("END:VALARM");
                buf.push_str(crlf);
            }
        }

        buf.push_str("END:VEVENT");
        buf.push_str(crlf);

        cursor += chrono::Duration::days(1);
    }

    buf.push_str("END:VCALENDAR");
    buf.push_str(crlf);

    buf
}

/// Escape special characters in ICS text values.
fn ics_escape(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace(';', "\\;")
        .replace(',', "\\,")
        .replace('\n', "\\n")
}


fn shift_alarm_key(st: &ShiftType) -> String {
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
        assert!(ics.ends_with("END:VCALENDAR\r\n"));
        // 30 days → 30 VEVENTs
        let count = ics.matches("BEGIN:VEVENT\r\n").count();
        assert_eq!(count, 30);
    }

    #[test]
    fn every_begin_has_matching_end() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 6, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 6, 7).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        assert_eq!(ics.matches("BEGIN:").count(), ics.matches("END:").count());
    }

    #[test]
    fn each_vevent_has_required_properties() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let end = start;
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        assert!(ics.contains("DTSTART;TZID=Asia/Shanghai:"));
        assert!(ics.contains("DTEND;TZID=Asia/Shanghai:"));
        assert!(ics.contains("SUMMARY:"));
        // No RRULE — one VEVENT per day
        assert!(!ics.contains("RRULE"));
    }

    #[test]
    fn night_shift_crosses_midnight() {
        let config = default_config();
        // 2026-05-22 is Night for team 1
        let date = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let ics = generate_shift_ics(date, date, &config, 0, 1, None, "Asia/Shanghai");

        assert!(ics.contains("DTSTART;TZID=Asia/Shanghai:20260522T220000"));
        assert!(ics.contains("DTEND;TZID=Asia/Shanghai:20260523T060000"));
    }

    #[test]
    fn morning_shift_has_correct_times() {
        let config = default_config();
        // 2025-12-15 is Morning for team 1 (reference date, day 1)
        let date = NaiveDate::from_ymd_opt(2025, 12, 15).unwrap();
        let ics = generate_shift_ics(date, date, &config, 0, 1, None, "Asia/Shanghai");

        assert!(ics.contains("DTSTART;TZID=Asia/Shanghai:20251215T070000"));
        assert!(ics.contains("DTEND;TZID=Asia/Shanghai:20251215T150000"));
    }

    #[test]
    fn rest_day_is_all_day_event() {
        let config = default_config();
        // 2025-12-19 is Rest (day 5, index 4)
        let date = NaiveDate::from_ymd_opt(2025, 12, 19).unwrap();
        let ics = generate_shift_ics(date, date, &config, 0, 1, None, "Asia/Shanghai");

        assert!(ics.contains("DTSTART;TZID=Asia/Shanghai:20251219T000000"));
        assert!(ics.contains("DTEND;TZID=Asia/Shanghai:20251219T235900"));
    }

    #[test]
    fn full_year_produces_expected_count() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 1, 1).unwrap();
        let end = NaiveDate::from_ymd_opt(2026, 12, 31).unwrap();
        let ics = generate_shift_ics(start, end, &config, 0, 1, None, "Asia/Shanghai");

        // 2026 has 365 days → 365 VEVENTs
        assert_eq!(ics.matches("BEGIN:VEVENT\r\n").count(), 365);
        // Must use CRLF
        assert!(ics.contains("\r\n"));
    }

    #[test]
    fn alarms_produce_valarm() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let mut alarms: AlarmConfig = HashMap::new();
        alarms.insert("night".into(), (21, 30)); // 30 min before 22:00

        let ics = generate_shift_ics(start, start, &config, 0, 1, Some(&alarms), "Asia/Shanghai");
        assert!(ics.contains("BEGIN:VALARM\r\n"));
        assert!(ics.contains("TRIGGER:-PT30M"));
        assert!(ics.contains("ACTION:DISPLAY"));
    }

    #[test]
    fn no_alarms_for_unconfigured_shift() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let mut alarms: AlarmConfig = HashMap::new();
        alarms.insert("morning".into(), (6, 30)); // morning only, not night

        let ics = generate_shift_ics(start, start, &config, 0, 1, Some(&alarms), "Asia/Shanghai");
        // May 22 is Night — should NOT have VALARM since only morning is configured
        assert!(!ics.contains("VALARM"));
    }

    #[test]
    fn calendar_description_varies_by_team() {
        let config = default_config();
        let start = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
        let ics_team1 = generate_shift_ics(start, start, &config, 0, 1, None, "Asia/Shanghai");
        let ics_team3 = generate_shift_ics(start, start, &config,
            config.team_phase_offset(3), 3, None, "Asia/Shanghai");

        assert!(ics_team1.contains("一值"));
        assert!(ics_team3.contains("三值"));
    }

    #[test]
    fn single_day_range_works() {
        let config = default_config();
        let date = NaiveDate::from_ymd_opt(2026, 6, 15).unwrap();
        let ics = generate_shift_ics(date, date, &config, 0, 1, None, "Asia/Shanghai");
        assert_eq!(ics.matches("BEGIN:VEVENT\r\n").count(), 1);
    }
}
