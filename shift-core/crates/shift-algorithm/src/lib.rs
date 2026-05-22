//! # shift-algorithm
//!
//! **Core shift scheduling algorithm.** The foundation of the entire 班伴 (ShiftMate) project.
//!
//! Given any date, this crate determines what shift a worker is on,
//! based on a repeating cycle shared across multiple teams.
//!
//! ## How it works
//!
//! The default cycle is 42 days, shared by 6 teams (一值～六值):
//!
//! ```text
//! 早 早 中 中 休 夜 夜  休 休 早 早 中 中 休  夜 休 休 休 早 早 中 休
//! 夜 夜 休 休 休 早 中 中  休 夜 夜 休 休 学 学 学 学 学 休 休
//! ```
//!
//! Each team is offset by 7 days (42 / 6). Reference date 2025-12-15 is day 1.
//! Team 1 starts at offset 0, team 2 at offset 7, etc.
//!
//! ## Quick start
//!
//! ```rust
//! use shift_algorithm::cycle::default_config;
//! use shift_algorithm::get_shift_info;
//! use chrono::NaiveDate;
//!
//! let config = default_config();
//! let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
//! let info = get_shift_info(today, &config, 0);
//!
//! println!("{:?} · day {}/{}",
//!     info.shift_type,
//!     info.day_of_cycle,
//!     config.cycle_length,
//! );
//! ```
//!
//! ## Crate structure
//!
//! - [`types`] — `ShiftType` enum, `ShiftInfo` struct, `ShiftCycleConfig`
//! - [`cycle`] — Default constants (42-day cycle, reference date, 6 teams)
//! - [`calculator`] — Pure functions: offset, normalize, get shift for date

pub mod calculator;
pub mod cycle;
pub mod types;

pub use calculator::*;
pub use cycle::*;
pub use types::*;
