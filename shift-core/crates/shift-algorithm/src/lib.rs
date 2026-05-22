//! # shift-algorithm
//!
//! Core shift scheduling algorithm. Date offset → cycle index → shift type.
//! Pure functions, zero platform dependencies.
//!
//! Ported from Android `shift_calculator.kt` and Flutter `shift_calculator.dart`.

pub mod calculator;
pub mod cycle;
pub mod types;

pub use calculator::*;
pub use cycle::*;
pub use types::*;
