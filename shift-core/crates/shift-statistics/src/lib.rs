//! # shift-statistics
//!
//! Monthly statistics, consecutive work days, days until next rest,
//! and colleague mode (common rest days between two teams).
//!
//! Ported from Flutter `shift_metrics.dart` + `colleague_mode.dart`.

pub mod colleague;
pub mod metrics;

pub use colleague::*;
pub use metrics::*;
