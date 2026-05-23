//! C-compatible FFI bridge between Flutter (Dart) and shift-core (Rust).
//!
//! All functions use `extern "C"`, take simple C types or JSON strings,
//! and return JSON strings allocated with `CString::into_raw`.
//! Every returned pointer must be freed by the caller via `shift_free_string`.

use chrono::NaiveDate;
use holiday_engine::get_china_holidays;
use leave_optimizer::find_best_leave_plans;
use shift_algorithm::cycle::default_config;
use shift_algorithm::{get_shift_info, get_shift_type_for_date, ShiftCycleConfig};
use shift_export::generate_shift_ics;
use shift_statistics::colleague::find_common_rest_days;
use shift_statistics::metrics::{
    consecutive_work_days, count_shift_type_in_month, count_work_days_in_month,
    days_until_next_rest,
};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

// ── Memory management ──

/// Free a string returned by any shift_* function.
#[no_mangle]
pub unsafe extern "C" fn shift_free_string(ptr: *mut c_char) {
    if ptr.is_null() { return; }
    unsafe { let _ = CString::from_raw(ptr); }
}

// ── Helpers ──

fn parse_date(s: &str, fallback: NaiveDate) -> NaiveDate {
    NaiveDate::parse_from_str(s, "%Y-%m-%d").unwrap_or(fallback)
}

fn build_config(cycle_length: u32, ref_date: NaiveDate) -> ShiftCycleConfig {
    let default = default_config();
    if cycle_length == 0 || cycle_length == default.cycle_length {
        return default;
    }
    let cycle = default.cycle[..cycle_length as usize].to_vec();
    ShiftCycleConfig { cycle_length, cycle, reference_date: ref_date, total_teams: 6 }
}

fn to_json_or_error(result: Result<String, String>) -> *mut c_char {
    match result {
        Ok(json) => CString::new(json).unwrap().into_raw(),
        Err(e) => CString::new(format!(r#"{{"error":"{}"}}"#, e)).unwrap().into_raw(),
    }
}

macro_rules! c_str {
    ($ptr:expr) => { unsafe { CStr::from_ptr($ptr) }.to_str().unwrap_or("") };
}

// ── Shift info ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_shift_info(
    date_iso: *const c_char,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        let date = parse_date(c_str!(date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let offset = config.team_phase_offset(team_id.max(1));
        let info = get_shift_info(date, &config, offset);

        serde_json::json!({
            "date": info.date.format("%Y-%m-%d").to_string(),
            "shift_type": format!("{:?}", info.shift_type).to_lowercase(),
            "shift_label": info.shift_type.full_label(),
            "day_of_cycle": info.day_of_cycle,
            "total_days": config.cycle_length,
            "cycle_index": info.cycle_index,
        }).to_string()
    });
    let json = result.unwrap_or_else(|_| r#"{"error":"panic"}"#.to_string());
    CString::new(json).unwrap().into_raw()
}

// ── Shift type for date (single lookup, no full ShiftInfo) ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_shift_type_for_date(
    date_iso: *const c_char,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let date = parse_date(c_str!(date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let st = get_shift_type_for_date(date, &config, config.team_phase_offset(team_id.max(1)));
        Ok(serde_json::json!({
            "shift_type": format!("{:?}", st).to_lowercase(),
            "shift_label": st.full_label(),
        }).to_string())
    })
}

// ── Batch shift info for date range ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_shift_info_range(
    start_date_iso: *const c_char,
    end_date_iso: *const c_char,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let start = parse_date(c_str!(start_date_iso), default_config().reference_date);
        let end = parse_date(c_str!(end_date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let offset = config.team_phase_offset(team_id.max(1));
        let days: Vec<serde_json::Value> = (0..=(end - start).num_days()).map(|d| {
            let date = start + chrono::Duration::days(d);
            let info = get_shift_info(date, &config, offset);
            serde_json::json!({
                "date": info.date.format("%Y-%m-%d").to_string(),
                "shift_type": format!("{:?}", info.shift_type).to_lowercase(),
                "shift_label": info.shift_type.full_label(),
                "day_of_cycle": info.day_of_cycle,
                "total_days": config.cycle_length,
            })
        }).collect();
        Ok(serde_json::json!({"days": days}).to_string())
    })
}

// ── Rest/work tracking ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_days_until_rest(
    date_iso: *const c_char,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let date = parse_date(c_str!(date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let info = get_shift_info(date, &config, config.team_phase_offset(team_id.max(1)));
        let days = days_until_next_rest(date, &config, config.team_phase_offset(team_id.max(1)));
        let today_is_rest = info.shift_type.is_rest();
        Ok(serde_json::json!({
            "days_until": days,
            "today_is_rest": today_is_rest,
        }).to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn shift_get_consecutive_work_days(
    date_iso: *const c_char,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let date = parse_date(c_str!(date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let days = consecutive_work_days(date, &config, config.team_phase_offset(team_id.max(1)));
        Ok(serde_json::json!({"consecutive_work_days": days}).to_string())
    })
}

// ── Monthly stats ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_monthly_stats(
    year: i32,
    month: u32,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let offset = config.team_phase_offset(team_id.max(1));
        Ok(serde_json::json!({
            "morning": count_shift_type_in_month(year, month, shift_algorithm::ShiftType::Morning, &config, offset),
            "afternoon": count_shift_type_in_month(year, month, shift_algorithm::ShiftType::Afternoon, &config, offset),
            "rest": count_shift_type_in_month(year, month, shift_algorithm::ShiftType::Rest, &config, offset),
            "night": count_shift_type_in_month(year, month, shift_algorithm::ShiftType::Night, &config, offset),
            "study": count_shift_type_in_month(year, month, shift_algorithm::ShiftType::Study, &config, offset),
            "work_days": count_work_days_in_month(year, month, &config, offset),
        }).to_string())
    })
}

// ── Colleague mode ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_common_rest_days(
    team_a: u32,
    team_b: u32,
    date_iso: *const c_char,
    days_to_analyze: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let today = parse_date(c_str!(date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let result = find_common_rest_days(team_a.max(1), team_b.max(1), today, days_to_analyze, &config);
        Ok(serde_json::json!({
            "next_common_rest": result.next_common_rest_date.map(|d| d.format("%Y-%m-%d").to_string()),
            "days_until_next": result.days_until_next,
            "common_rest_dates": result.common_rest_dates.iter().take(60).map(|d| d.format("%Y-%m-%d").to_string()).collect::<Vec<_>>(),
            "count_30_days": result.count_in_30_days,
            "count_60_days": result.count_in_60_days,
        }).to_string())
    })
}

// ── Holiday data ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_holidays() -> *mut c_char {
    to_json_or_error({
        let holidays = get_china_holidays();
        let list: Vec<serde_json::Value> = holidays.iter().map(|(date, info)| {
            serde_json::json!({
                "date": date.format("%Y-%m-%d").to_string(),
                "name": info.name,
                "is_holiday": info.is_holiday,
                "is_confirmed": info.is_confirmed,
            })
        }).collect();
        Ok(serde_json::json!({"holidays": list}).to_string())
    })
}

// ── ICS export ──

#[no_mangle]
pub unsafe extern "C" fn shift_generate_ics(
    start_date_iso: *const c_char,
    end_date_iso: *const c_char,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
    timezone_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let start = parse_date(c_str!(start_date_iso), default_config().reference_date);
        let end = parse_date(c_str!(end_date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let tz = unsafe { CStr::from_ptr(timezone_iso) }.to_str().unwrap_or("Asia/Shanghai");
        let ics = generate_shift_ics(start, end, &config, config.team_phase_offset(team_id.max(1)), team_id.max(1), None, tz);
        Ok(serde_json::json!({"ics": ics}).to_string())
    })
}

// ── Leave optimizer ──

#[no_mangle]
pub unsafe extern "C" fn shift_get_best_leave_plans(
    date_iso: *const c_char,
    days_to_analyze: u32,
    team_id: u32,
    max_leave_days: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    to_json_or_error({
        let today = parse_date(c_str!(date_iso), default_config().reference_date);
        let ref_date = parse_date(c_str!(reference_date_iso), default_config().reference_date);
        let config = build_config(cycle_length, ref_date);
        let holidays = get_china_holidays();
        let plans = find_best_leave_plans(
            today, days_to_analyze, &config,
            config.team_phase_offset(team_id.max(1)),
            Some(&holidays), max_leave_days,
        );
        let list: Vec<serde_json::Value> = plans.iter().take(10).map(|s| {
            serde_json::json!({
                "leave_days": s.leave_days,
                "total_break_days": s.total_break_days,
                "leave_dates": s.leave_dates.iter().map(|d| d.format("%Y-%m-%d").to_string()).collect::<Vec<_>>(),
                "break_start": s.break_start.format("%Y-%m-%d").to_string(),
                "break_end": s.break_end.format("%Y-%m-%d").to_string(),
                "efficiency": (s.efficiency * 10.0).round() / 10.0,
                "score": (s.score * 100.0).round() / 100.0,
                "holiday_overlap": s.holiday_overlap,
                "weekend_overlap": s.weekend_overlap,
                "holiday_names": s.overlapping_holiday_names,
            })
        }).collect();
        Ok(serde_json::json!({"strategies": list}).to_string())
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    fn c(s: &str) -> CString { CString::new(s).unwrap() }

    #[test]
    fn test_get_shift_info() {
        let ptr = unsafe { shift_get_shift_info(c("2026-05-22").as_ptr(), 1, 0, c("2025-12-15").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(v["shift_type"], "night");
        assert_eq!(v["day_of_cycle"], 33);
    }

    #[test]
    fn test_get_shift_type_for_date() {
        let ptr = unsafe { shift_get_shift_type_for_date(c("2026-05-22").as_ptr(), 1, 0, c("2025-12-15").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(v["shift_type"], "night");
        assert_eq!(v["shift_label"], "夜班");
    }

    #[test]
    #[test]
    fn test_get_shift_info_range() {
        let ptr = unsafe { shift_get_shift_info_range(c("2026-05-22").as_ptr(), c("2026-05-24").as_ptr(), 1, 0, c("2025-12-15").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        let days = v["days"].as_array().unwrap();
        assert_eq!(days.len(), 3); // May 22, 23, 24
        assert_eq!(days[0]["date"], "2026-05-22");
        assert_eq!(days[0]["shift_type"], "night");
        assert_eq!(days[2]["date"], "2026-05-24");
    }

    fn test_days_until_rest() {
        let ptr = unsafe { shift_get_days_until_rest(c("2026-05-22").as_ptr(), 1, 0, c("2025-12-15").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(v["days_until"], 0); // tomorrow is rest
        assert_eq!(v["today_is_rest"], false);
    }

    #[test]
    fn test_get_monthly_stats() {
        let ptr = unsafe { shift_get_monthly_stats(2026, 5, 1, 0, c("2025-12-15").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        let total = v["morning"].as_u64().unwrap()
            + v["afternoon"].as_u64().unwrap()
            + v["rest"].as_u64().unwrap()
            + v["night"].as_u64().unwrap()
            + v["study"].as_u64().unwrap();
        assert_eq!(total, 31);
    }

    #[test]
    fn test_common_rest_days() {
        let ptr = unsafe { shift_get_common_rest_days(1, 3, c("2026-05-22").as_ptr(), 90, 0, c("2025-12-15").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert!(v["count_30_days"].as_u64().unwrap() > 0);
        assert!(v["next_common_rest"].is_string());
    }

    #[test]
    fn test_get_holidays() {
        let ptr = unsafe { shift_get_holidays() };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        let holidays = v["holidays"].as_array().unwrap();
        assert!(holidays.len() > 50);
        // At least one confirmed holiday and one adjusted work day
        let has_holiday = holidays.iter().any(|h| h["is_holiday"] == true);
        let has_workday = holidays.iter().any(|h| h["is_holiday"] == false);
        assert!(has_holiday);
        assert!(has_workday);
        // 2026 New Year should be present
        let new_year = holidays.iter().find(|h| h["date"] == "2026-01-01");
        assert!(new_year.is_some());
        assert_eq!(new_year.unwrap()["name"], "元旦");
    }

    #[test]
    fn test_generate_ics() {
        let ptr = unsafe { shift_generate_ics(c("2026-06-01").as_ptr(), c("2026-06-07").as_ptr(), 1, 0, c("2025-12-15").as_ptr(), c("Asia/Shanghai").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        let ics = v["ics"].as_str().unwrap();
        assert!(ics.starts_with("BEGIN:VCALENDAR\r\n"));
        assert!(ics.contains("VERSION:2.0\r\n"));
        assert!(ics.ends_with("END:VCALENDAR\r\n"));
        // 7 days → 7 VEVENTs
        assert_eq!(ics.matches("BEGIN:VEVENT\r\n").count(), 7);
    }

    #[test]
    fn test_leave_plans() {
        let ptr = unsafe { shift_get_best_leave_plans(c("2026-09-01").as_ptr(), 60, 1, 5, 0, c("2025-12-15").as_ptr()) };
        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert!(!v["strategies"].as_array().unwrap().is_empty());
    }
}
