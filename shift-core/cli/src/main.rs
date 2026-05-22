//! # shift — 班伴 CLI
//!
//! Command-line interface for querying shift schedules.
//! TODO: Full CLI with clap derive (Phase 3).

use chrono::Local;
use shift_algorithm::cycle::default_config;
use shift_algorithm::get_shift_info;

fn main() {
    let config = default_config();
    let today = Local::now().date_naive();
    let info = get_shift_info(today, &config, 0);

    println!("{} · {} · 第 {}/{} 天",
        info.shift_type.full_label(),
        info.date.format("%Y-%m-%d"),
        info.day_of_cycle,
        config.cycle_length,
    );
}
