//! # shift-statistics
//!
//! **Monthly statistics and colleague mode** built on top of [`shift_algorithm`].
//!
//! Two modules:
//!
//! - [`metrics`] — Monthly shift counts, consecutive work days, days until rest
//! - [`colleague`] — Find common rest days between two teams (colleague mode)
//!
//! ## Example
//!
//! ```rust
//! use shift_algorithm::cycle::default_config;
//! use shift_statistics::metrics::{count_work_days_in_month, days_until_next_rest};
//! use chrono::NaiveDate;
//!
//! let config = default_config();
//! let today = NaiveDate::from_ymd_opt(2026, 5, 22).unwrap();
//!
//! let work_days = count_work_days_in_month(2026, 5, &config, 0);
//! let rest_in = days_until_next_rest(today, &config, 0);
//!
//! println!("本月上班 {} 天，距休 {} 天", work_days, rest_in);
//! ```

pub mod colleague;
pub mod metrics;

pub use colleague::*;
pub use metrics::*;
