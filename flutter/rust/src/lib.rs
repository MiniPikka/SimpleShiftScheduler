//! C-compatible FFI bridge between Flutter (Dart) and shift-core (Rust).
//!
//! All public functions use `extern "C"` and return JSON strings
//! to avoid complex struct marshalling across the FFI boundary.
//!
//! Memory management: returned strings are allocated with `CString::into_raw`
//! and must be freed by the caller via `shift_free_string`.

use chrono::NaiveDate;
use shift_algorithm::cycle::default_config;
use shift_algorithm::{get_shift_info, ShiftCycleConfig};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Free a string previously returned by any shift_* function.
///
/// # Safety
/// `ptr` must be a valid pointer returned by a shift_* function in this library,
/// and must not have been freed already.
#[no_mangle]
pub unsafe extern "C" fn shift_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(ptr);
    }
}

/// Get shift info for a given date as a JSON string.
///
/// # Parameters
///
/// - `date_iso`: date in ISO format "YYYY-MM-DD"
/// - `team_id`: team number (1-6)
/// - `cycle_length`: cycle length (default 42). 0 means use default.
/// - `reference_date_iso`: reference date in ISO format. Empty string means use default.
///
/// # Returns
///
/// JSON string with keys: date, shift_type, shift_label, day_of_cycle, total_days, cycle_index.
/// Must be freed with `shift_free_string`.
///
/// # Safety
/// All string parameters must be valid null-terminated UTF-8 C strings.
/// The returned pointer must be freed with `shift_free_string`.
#[no_mangle]
pub unsafe extern "C" fn shift_get_shift_info(
    date_iso: *const c_char,
    team_id: u32,
    cycle_length: u32,
    reference_date_iso: *const c_char,
) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        let date_str = unsafe { CStr::from_ptr(date_iso) }.to_str().unwrap_or("2025-12-15");
        let ref_str = unsafe { CStr::from_ptr(reference_date_iso) }.to_str().unwrap_or("");

        let date = NaiveDate::parse_from_str(date_str, "%Y-%m-%d")
            .unwrap_or_else(|_| default_config().reference_date);

        let config = if cycle_length > 0 && cycle_length != 42 {
            let ref_date = if ref_str.is_empty() {
                default_config().reference_date
            } else {
                NaiveDate::parse_from_str(ref_str, "%Y-%m-%d")
                    .unwrap_or_else(|_| default_config().reference_date)
            };
            let cycle = default_config().cycle[..cycle_length as usize].to_vec();
            ShiftCycleConfig {
                cycle_length,
                cycle,
                reference_date: ref_date,
                total_teams: 6,
            }
        } else {
            default_config()
        };

        let offset = config.team_phase_offset(team_id.max(1));
        let info = get_shift_info(date, &config, offset);

        let json = serde_json::json!({
            "date": info.date.format("%Y-%m-%d").to_string(),
            "shift_type": format!("{:?}", info.shift_type).to_lowercase(),
            "shift_label": info.shift_type.full_label(),
            "day_of_cycle": info.day_of_cycle,
            "total_days": config.cycle_length,
            "cycle_index": info.cycle_index,
        });
        CString::new(json.to_string()).unwrap().into_raw()
    });

    match result {
        Ok(ptr) => ptr,
        Err(_) => {
            let error_json = r#"{"error":"internal panic in shift_get_shift_info"}"#;
            CString::new(error_json).unwrap().into_raw()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_get_shift_info_via_ffi() {
        let date = CString::new("2026-05-22").unwrap();
        let ref_date = CString::new("2025-12-15").unwrap();

        let ptr = unsafe {
            shift_get_shift_info(date.as_ptr(), 1, 0, ref_date.as_ptr())
        };
        assert!(!ptr.is_null());

        let json = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_string();
        unsafe { shift_free_string(ptr) };

        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["date"], "2026-05-22");
        assert_eq!(parsed["shift_type"], "night");
        assert_eq!(parsed["day_of_cycle"], 33);
    }
}
