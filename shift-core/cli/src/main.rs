//! # banban — 班伴 CLI
//!
//! Command-line tool for querying shift schedules.
//! Named after the product 班伴 (ShiftMate).
//! Default: human-readable ANSI-colored output.
//! With --json: machine-readable JSON.

mod tui;

use chrono::{Datelike, Local, NaiveDate, Timelike};
use clap::{Parser, Subcommand};
use colored::*;
use unicode_width::UnicodeWidthStr;
use shift_export::generate_shift_ics;
use holiday_engine::get_china_holidays;
use leave_optimizer::find_best_leave_plans;
use serde::Serialize;
use shift_algorithm::cycle::{default_reference_date, default_shift_cycle};
use shift_algorithm::{get_shift_info, ShiftCycleConfig, ShiftType};
use shift_statistics::colleague::find_common_rest_days;
use shift_statistics::metrics::{
    consecutive_work_days, count_shift_type_in_month, count_work_days_in_month,
    days_until_next_rest,
};
use std::path::PathBuf;

// ── Config ──

#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
struct Config {
    #[serde(default)]
    shift: ShiftSection,
    #[serde(default)]
    alarms: AlarmSection,
}

#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
struct ShiftSection {
    #[serde(default = "default_cycle_len")]
    cycle_length: u32,
    #[serde(default = "default_ref_date_str")]
    reference_date: String,
    #[serde(default = "default_team")]
    default_team: u32,
    /// Custom cycle: e.g. ["早","早","中","中","休","夜","休"]
    /// If empty, uses the default 42-day cycle.
    #[serde(default)]
    cycle: Vec<String>,
}

impl Default for ShiftSection {
    fn default() -> Self {
        Self {
            cycle_length: 42,
            reference_date: "2025-12-15".into(),
            default_team: 1,
            cycle: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, Default, serde::Deserialize, serde::Serialize)]
struct AlarmSection {
    morning: Option<String>,
    afternoon: Option<String>,
    night: Option<String>,
}

fn default_cycle_len() -> u32 {
    42
}
fn default_ref_date_str() -> String {
    "2025-12-15".into()
}
fn default_team() -> u32 {
    1
}

impl Config {
    fn load(override_path: Option<&std::path::Path>) -> Self {
        let path = if let Some(p) = override_path {
            p.to_path_buf()
        } else {
            dirs::config_dir()
                .unwrap_or_else(|| PathBuf::from("."))
                .join("banban")
                .join("config.toml")
        };

        if path.exists() {
            std::fs::read_to_string(&path)
                .ok()
                .and_then(|s| toml::from_str(&s).ok())
                .unwrap_or_default()
        } else {
            Self::default()
        }
    }

    fn to_cycle_config(&self) -> ShiftCycleConfig {
        let ref_date = NaiveDate::parse_from_str(&self.shift.reference_date, "%Y-%m-%d")
            .unwrap_or_else(|_| default_reference_date());
        let cycle = if !self.shift.cycle.is_empty() {
            self.shift.cycle.iter().map(|s| parse_shift_label(s)).collect()
        } else {
            default_shift_cycle()
        };
        let cycle_length = cycle.len() as u32;
        ShiftCycleConfig {
            cycle_length,
            cycle,
            reference_date: ref_date,
            total_teams: 6,
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            shift: ShiftSection {
                cycle_length: 42,
                reference_date: "2025-12-15".into(),
                default_team: 1,
                cycle: Vec::new(),
            },
            alarms: AlarmSection::default(),
        }
    }
}

// ── CLI definition ──

/// Rotating shift schedule CLI — check today's shift, plan leave, find common rest days.
///
/// Default 42-day cycle, 6 teams. Switch language: --lang zh
///
/// Step 1: tell it your team (if not team 1):
///   banban --team 2 today
///
/// Step 2: save your team so you don't need --team every time:
///   banban config
///   # edit ~/.config/banban/config.toml → default_team = 2
///
/// Step 3: use it daily, or add to Waybar/systemd timer:
///   banban install
#[derive(Parser)]
#[command(
    name = "banban",
    version,
    about = "Shift schedule CLI — 班伴 (ShiftMate)",
    long_about = "Rotating shift schedule CLI. Default 42-day cycle, 6 teams.\nCheck today's shift, plan optimal leave, find common rest days with colleagues.",
    after_help = "Quick start:\n  \
                  banban today              What shift is today?\n  \
                  banban --team 2 today     If you're on team 2\n  \
                  banban calendar           Monthly calendar (color-coded)\n  \
                  banban stats              Monthly shift counts\n  \
                  banban next-rest          Days until next rest\n  \
                  banban leave              Best leave strategies\n  \
                  banban colleague 1 3      Common rest days: team 1 vs 3\n  \
                  banban export --ics       Export ICS calendar file\n  \
                  banban tui                Full-screen terminal UI\n  \
                  banban notify             Desktop notification\n  \
                  banban install            Install systemd daily timer\n  \
                  \n  \
                  Custom cycle:\n  \
                  banban config             Generate sample config file\n  \
                  Edit ~/.config/banban/config.toml, change the cycle array.\n  \
                  Accepts English labels (morning/afternoon/rest/night/study)\n  \
                  or Chinese (早/中/休/夜/学)."
)]
struct Cli {
    /// JSON output (machine-readable). Default: human-readable colored text
    #[arg(short, long, global = true)]
    json: bool,

    /// Your team number (1-6). Default: from config file, or team 1
    #[arg(short = 't', long, global = true, default_value = "0")]
    team: u32,

    /// Display language: en (default) or zh (Chinese)
    #[arg(short = 'l', long, global = true, default_value = "en")]
    lang: String,

    /// Config file path (default: ~/.config/banban/config.toml)
    #[arg(short, long, global = true)]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// What shift is today? Cycle day, days until rest
    Today,
    /// What shift is tomorrow?
    Tomorrow,
    /// Days until next rest day ("Rest tomorrow" or "3 days until rest")
    NextRest,
    /// Monthly calendar with color-coded shifts (orange AM / blue PM / green Off / purple NT / yellow TR)
    Calendar {
        /// Month in YYYY-MM format (default: current month)
        month: Option<String>,
    },
    /// Monthly shift counts with ASCII bar chart
    Stats {
        /// Month in YYYY-MM format (default: current month)
        month: Option<String>,
    },
    /// Find optimal leave strategies. Analyzes from today to Dec 31,
    /// combining your shift schedule with Chinese statutory holidays.
    Leave {
        /// Max leave days to consider (default: 5)
        #[arg(short, long, default_value = "5")]
        max_days: u32,
    },
    /// Find common rest days between two teams.
    /// "I'm team 2, they're team 5 — when can we both rest?"
    Colleague {
        /// My team (1=一值, ... 6=六值)
        team_a: u32,
        /// Their team (1=一值, ... 6=六值)
        team_b: u32,
    },
    /// Output for Waybar status bar (Sway/Hyprland).
    /// Config: add to ~/.config/waybar/config.json
    ///   "custom/banban": {"exec": "banban waybar", "interval": 3600}
    Waybar,
    /// Export ICS calendar file for Thunderbird/Nextcloud/Google Calendar.
    /// One event per day, ~365 events per year.
    Export {
        /// Export in ICS format
        #[arg(long)]
        ics: bool,
        /// Output path (default: ~/.local/share/banban/shifts.ics)
        #[arg(short, long)]
        output: Option<PathBuf>,
        /// Open with default app after export (usually Thunderbird)
        #[arg(long)]
        open: bool,
    },
    /// Send desktop notification with today's shift info
    Notify,
    /// Install systemd timer for daily ICS export + notification
    Install,
    /// Full-screen interactive terminal UI (btop/lazygit style)
    Tui,
    /// Generate sample config file with custom cycle documentation
    Config,
}

// ── JSON output types ──

#[derive(Serialize)]
struct TodayOutput {
    date: String,
    shift_type: String,
    shift_label: String,
    team: String,
    day_of_cycle: u32,
    total_days: u32,
    days_until_rest: u32,
    consecutive_work_days: u32,
}

#[derive(Serialize)]
struct NextRestOutput {
    days_until: u32,
    rest_date: String,
    message: String,
}

#[derive(Serialize)]
struct CalendarOutput {
    month: String,
    team: String,
    weeks: Vec<Vec<CalendarDayOutput>>,
    stats: StatsOutput,
}

#[derive(Serialize)]
struct CalendarDayOutput {
    day: u32,
    shift_type: String,
    shift_label: String,
    is_current_month: bool,
    is_today: bool,
}

#[derive(Serialize)]
struct StatsOutput {
    morning: u32,
    afternoon: u32,
    rest: u32,
    night: u32,
    study: u32,
    work_days: u32,
    total_days: u32,
}

#[derive(Serialize)]
struct LeaveOutput {
    strategies: Vec<LeaveStrategyOutput>,
}

#[derive(Serialize)]
struct LeaveStrategyOutput {
    rank: u32,
    leave_days: u32,
    total_break_days: u32,
    break_start: String,
    break_end: String,
    efficiency: f64,
    score: f64,
    holiday_overlap: u32,
    weekend_overlap: u32,
    holiday_names: Vec<String>,
    leave_dates: Vec<String>,
}

#[derive(Serialize)]
struct ColleagueOutput {
    team_a: u32,
    team_b: u32,
    next_common_rest: Option<String>,
    days_until_next: Option<u32>,
    common_rest_dates: Vec<String>,
    count_30_days: u32,
    count_60_days: u32,
}

#[derive(Serialize)]
struct WaybarOutput {
    text: String,
    class: String,
    tooltip: String,
}

// ── Color helpers ──

fn shift_color(st: ShiftType) -> Color {
    match st {
        ShiftType::Morning => Color::TrueColor { r: 0xFF, g: 0xB3, b: 0x47 },
        ShiftType::Afternoon => Color::TrueColor { r: 0x4D, g: 0xA3, b: 0xFF },
        ShiftType::Rest => Color::TrueColor { r: 0x35, g: 0xD0, b: 0x7F },
        ShiftType::Night => Color::TrueColor { r: 0x7C, g: 0x5C, b: 0xFF },
        ShiftType::Study => Color::TrueColor { r: 0xF2, g: 0xD9, b: 0x4E },
    }
}

fn shift_icon(st: ShiftType) -> &'static str {
    match st {
        ShiftType::Morning => "🟠",
        ShiftType::Afternoon => "🔵",
        ShiftType::Rest => "🟢",
        ShiftType::Night => "🟣",
        ShiftType::Study => "🟡",
    }
}

/// Pad a string to exactly `width` terminal columns, accounting for CJK double-width.
fn pad_cjk(s: &str, width: usize) -> String {
    let vis = UnicodeWidthStr::width(s);
    if vis >= width {
        s.to_string()
    } else {
        format!("{}{}", s, " ".repeat(width - vis))
    }
}

/// Parse a shift label (Chinese or English) into a ShiftType.
fn parse_shift_label(s: &str) -> ShiftType {
    match s.trim() {
        "早" | "早班" | "morning" | "Morning" | "MORNING" => ShiftType::Morning,
        "中" | "中班" | "afternoon" | "Afternoon" | "AFTERNOON" => ShiftType::Afternoon,
        "休" | "休班" | "rest" | "Rest" | "REST" => ShiftType::Rest,
        "夜" | "夜班" | "night" | "Night" | "NIGHT" => ShiftType::Night,
        "学" | "学习" | "学习班" | "study" | "Study" | "STUDY" => ShiftType::Study,
        _ => ShiftType::Rest,
    }
}

/// Short label in current language.
fn lbl(st: ShiftType, lang: &str) -> &'static str {
    if lang == "zh" { st.label() } else { st.label_en() }
}

/// Full label in current language.
fn full_lbl(st: ShiftType, lang: &str) -> &'static str {
    if lang == "zh" { st.full_label() } else { st.full_label_en() }
}

/// Team name in current language.
fn team_lbl(id: u32, lang: &str) -> String {
    if lang == "zh" { shift_algorithm::team_name(id) } else { format!("Team {}", id) }
}

fn month_name_en(m: u32) -> &'static str {
    match m {
        1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun",
        7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec",
        _ => "???",
    }
}

// ── Main ──

fn main() {
    let cli = Cli::parse();
    let config = Config::load(cli.config.as_deref());
    let cycle_config = config.to_cycle_config();
    // --team flag overrides config file
    let team_id = if cli.team > 0 { cli.team } else { config.shift.default_team };
    let offset = cycle_config.team_phase_offset(team_id);
    let today = Local::now().date_naive();

    match cli.command {
        Commands::Today => cmd_today(&cli, today, &cycle_config, offset, team_id),
        Commands::Tomorrow => cmd_tomorrow(&cli, today, &cycle_config, offset, team_id),
        Commands::NextRest => cmd_next_rest(&cli, today, &cycle_config, offset),
        Commands::Calendar { ref month } => cmd_calendar(&cli, today, &cycle_config, offset, team_id, month.as_ref()),
        Commands::Stats { ref month } => cmd_stats(&cli, today, &cycle_config, offset, team_id, month.as_ref()),
        Commands::Leave { max_days } => cmd_leave(&cli, today, &cycle_config, offset, max_days),
        Commands::Colleague { team_a, team_b } => cmd_colleague(&cli, today, &cycle_config, team_a, team_b),
        Commands::Waybar => cmd_waybar(today, &cycle_config, offset, team_id),
        Commands::Export { ics: _, output, open } => cmd_export(today, &cycle_config, offset, team_id, output, open),
        Commands::Notify => cmd_notify(today, &cycle_config, offset, team_id),
        Commands::Install => cmd_install(),
        Commands::Tui => {
            if let Err(e) = tui::run_tui(cycle_config, offset, team_id) {
                eprintln!("TUI error: {}", e);
            }
        }
        Commands::Config => cmd_config(),
    }
}

// ── Command handlers ──

fn cmd_today(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32, team: u32) {
    let info = get_shift_info(today, config, offset);
    let rest = days_until_next_rest(today, config, offset);
    let consec = consecutive_work_days(today, config, offset);
    let lang = cli.lang.as_str();

    if cli.json {
        let out = TodayOutput {
            date: today.format("%Y-%m-%d").to_string(),
            shift_type: format!("{:?}", info.shift_type).to_lowercase(),
            shift_label: full_lbl(info.shift_type, lang).to_string(),
            team: team_lbl(team, lang),
            day_of_cycle: info.day_of_cycle,
            total_days: config.cycle_length,
            days_until_rest: rest,
            consecutive_work_days: consec,
        };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        let color = shift_color(info.shift_type);
        let rest_msg = if info.shift_type.is_rest() {
            if lang == "zh" { "今天是休息日 🎉".green().bold().to_string() }
            else { "Rest day 🎉".green().bold().to_string() }
        } else if rest == 0 {
            if lang == "zh" { "明天休息".green().to_string() }
            else { "Rest tomorrow".green().to_string() }
        } else {
            if lang == "zh" { format!("距休 {} 天", rest) }
            else { format!("{}d until rest", rest) }
        };
        println!(
            "{} {} · {} · Day {}/{} · {}",
            shift_icon(info.shift_type),
            full_lbl(info.shift_type, lang).color(color).bold(),
            team_lbl(team, lang).dimmed(),
            info.day_of_cycle,
            config.cycle_length,
            rest_msg,
        );
        println!(
            "  {} {} · {} {}",
            if lang == "zh" { "连续上班".dimmed() } else { "Work streak".dimmed() },
            format!("{}d", consec).bold(),
            today.format("%Y-%m-%d %A").to_string().dimmed(),
            "".dimmed(),
        );
    }
}

fn cmd_tomorrow(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32, team: u32) {
    let tomorrow = today + chrono::Duration::days(1);
    let info = get_shift_info(tomorrow, config, offset);
    let lang = cli.lang.as_str();

    if cli.json {
        println!(
            "{}",
            serde_json::json!({
                "date": tomorrow.format("%Y-%m-%d").to_string(),
                "shift_type": format!("{:?}", info.shift_type).to_lowercase(),
                "shift_label": full_lbl(info.shift_type, lang),
                "team": team_lbl(team, lang),
                "day_of_cycle": info.day_of_cycle,
                "total_days": config.cycle_length,
            })
        );
    } else {
        let color = shift_color(info.shift_type);
        println!(
            "{} {} · {} · 第 {}/{} 天",
            shift_icon(info.shift_type),
            full_lbl(info.shift_type, lang).color(color).bold(),
            tomorrow.format("%b %d %A").to_string().dimmed(),
            info.day_of_cycle,
            config.cycle_length,
        );
    }
}

fn cmd_next_rest(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32) {
    let info = get_shift_info(today, config, offset);
    let lang = cli.lang.as_str();
    let today_is_rest = info.shift_type.is_rest();
    let days = days_until_next_rest(today, config, offset);

    if cli.json {
        let rest_date = if today_is_rest {
            today
        } else {
            today + chrono::Duration::days(days as i64)
        };
        let msg = if today_is_rest {
            if lang == "zh" { "今天休息".to_string() } else { "Rest day".to_string() }
        } else if days == 0 {
            if lang == "zh" { "明天休息".to_string() } else { "Rest tomorrow".to_string() }
        } else {
            format!("{}", format!("{}", if lang == "zh" { format!("距休 {} 天", days) } else { format!("{}d until rest", days) }))
        };
        let out = NextRestOutput {
            days_until: if today_is_rest { 0 } else { days },
            rest_date: rest_date.format("%Y-%m-%d").to_string(),
            message: msg,
        };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        if today_is_rest {
            println!("{} {}", "🟢".bold(), if lang == "zh" { "今天是休息日".green().bold() } else { "Rest day".green().bold() });
        } else if days == 0 {
            let tomorrow = today + chrono::Duration::days(1);
            println!(
                "{} {} · {}",
                "🟢".bold(),
                if lang == "zh" { "明天休息".green().bold() } else { "Rest tomorrow".green().bold() },
                tomorrow.format("%b %d %A").to_string().dimmed(),
            );
        } else {
            let rest_date = today + chrono::Duration::days(days as i64);
            println!(
                "{} {} {} · {} {}",
                "⏳".bold(),
                if lang == "zh" { format!("距下次休息 {} 天", days) } else { format!("{}d until rest", days) }.dimmed(),
                "".dimmed(),
                rest_date.format("%b %d %A").to_string().bold(),
                "".dimmed(),
            );
        }
    }
}

fn cmd_calendar(
    cli: &Cli,
    today: NaiveDate,
    config: &ShiftCycleConfig,
    offset: u32,
    team: u32,
    month: Option<&String>,
) {
    let lang = cli.lang.as_str();
    let (year, month_num) = parse_month(today, month);
    let start = NaiveDate::from_ymd_opt(year, month_num, 1).unwrap();
    let days_in_month = if month_num == 12 {
        NaiveDate::from_ymd_opt(year + 1, 1, 1).unwrap()
    } else {
        NaiveDate::from_ymd_opt(year, month_num + 1, 1).unwrap()
    };
    let total_days = (days_in_month - start).num_days() as u32;

    // Find the Sunday before (or on) the 1st
    let weekday = start.weekday().num_days_from_sunday();
    let cal_start = start - chrono::Duration::days(weekday as i64);

    if cli.json {
        let mut weeks: Vec<Vec<CalendarDayOutput>> = Vec::new();
        for w in 0..6 {
            let mut week = Vec::new();
            for d in 0..7 {
                let date = cal_start + chrono::Duration::days((w * 7 + d) as i64);
                let info = get_shift_info(date, config, offset);
                week.push(CalendarDayOutput {
                    day: date.day(),
                    shift_type: format!("{:?}", info.shift_type).to_lowercase(),
                    shift_label: lbl(info.shift_type, lang).to_string(),
                    is_current_month: date.month() == month_num,
                    is_today: date == today,
                });
            }
            weeks.push(week);
        }
        let stats = build_stats(year, month_num, config, offset, total_days);
        let out = CalendarOutput {
            month: format!("{}-{:02}", year, month_num),
            team: team_lbl(team, lang),
            weeks,
            stats,
        };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        println!(
            "{} {} · {}",
            "📅".bold(),
            format!("{}年{}月", year, month_num).bold(),
            shift_algorithm::team_name(team).dimmed(),
        );

        // Unicode-width-aware header
        let dow = if lang == "zh" { ["日", "一", "二", "三", "四", "五", "六"] } else { ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"] };
        let header_width = if lang == "zh" { 5 } else { 4 };
        for d in dow {
            print!("{}", pad_cjk(d, header_width).dimmed());
        }
        println!();

        for w in 0..6 {
            for d in 0..7 {
                let date = cal_start + chrono::Duration::days((w * 7 + d) as i64);
                let info = get_shift_info(date, config, offset);
                let is_cur = date.month() == month_num;
                let is_tdy = date == today;

                let label = lbl(info.shift_type, lang);
                let content = if lang == "zh" { format!("{:2}{}", date.day(), label) } else { format!("{:2} {}", date.day(), label) };
                let cell = pad_cjk(&content, header_width);

                if !is_cur {
                    print!("{}", cell.dimmed());
                } else if is_tdy {
                    print!("{}", cell.color(shift_color(info.shift_type)).bold().on_bright_black());
                } else {
                    print!("{}", cell.color(shift_color(info.shift_type)));
                }
            }
            println!();
        }

        // Inline stats
        let stats = build_stats(year, month_num, config, offset, total_days);
        println!();
        if lang == "zh" {
            println!(
                "早{}  中{}  休{}  夜{}  学{}  上班{}/{}",
                stats.morning.to_string().color(shift_color(ShiftType::Morning)).bold(),
                stats.afternoon.to_string().color(shift_color(ShiftType::Afternoon)).bold(),
                stats.rest.to_string().color(shift_color(ShiftType::Rest)).bold(),
                stats.night.to_string().color(shift_color(ShiftType::Night)).bold(),
                stats.study.to_string().color(shift_color(ShiftType::Study)).bold(),
                stats.work_days,
                stats.total_days,
            );
        } else {
            println!(
                "AM{} PM{} Off{} NT{} TR{} Work{}/{}",
                stats.morning.to_string().color(shift_color(ShiftType::Morning)).bold(),
                stats.afternoon.to_string().color(shift_color(ShiftType::Afternoon)).bold(),
                stats.rest.to_string().color(shift_color(ShiftType::Rest)).bold(),
                stats.night.to_string().color(shift_color(ShiftType::Night)).bold(),
                stats.study.to_string().color(shift_color(ShiftType::Study)).bold(),
                stats.work_days,
                stats.total_days,
            );
        }
    }
}

fn cmd_stats(
    cli: &Cli,
    today: NaiveDate,
    config: &ShiftCycleConfig,
    offset: u32,
    team: u32,
    month: Option<&String>,
) {
    let lang = cli.lang.as_str();
    let (year, month_num) = parse_month(today, month);
    let days_in_month = if month_num == 12 {
        NaiveDate::from_ymd_opt(year + 1, 1, 1).unwrap()
    } else {
        NaiveDate::from_ymd_opt(year, month_num + 1, 1).unwrap()
    };
    let total_days = (days_in_month - NaiveDate::from_ymd_opt(year, month_num, 1).unwrap())
        .num_days() as u32;
    let stats = build_stats(year, month_num, config, offset, total_days);

    if cli.json {
        println!("{}", serde_json::to_string_pretty(&stats).unwrap());
    } else {
        println!(
            "{} {} · {}",
            "📊".bold(),
            if lang == "zh" { format!("{}年{}月 统计", year, month_num) } else { format!("{} {}", month_name_en(month_num), year) }.bold(),
            team_lbl(team, lang).dimmed(),
        );
        println!();
        println!(
            "  {}  {:>3}d   {}",
            if lang == "zh" { "早班" } else { "AM  " },
            stats.morning,
            "█".repeat(stats.morning as usize).color(shift_color(ShiftType::Morning)),
        );
        println!(
            "  {}  {:>3}d   {}",
            if lang == "zh" { "中班" } else { "PM  " },
            stats.afternoon,
            "█".repeat(stats.afternoon as usize).color(shift_color(ShiftType::Afternoon)),
        );
        println!(
            "  {}  {:>3}d   {}",
            if lang == "zh" { "休班" } else { "Off " },
            stats.rest,
            "█".repeat(stats.rest as usize).color(shift_color(ShiftType::Rest)),
        );
        println!(
            "  {}  {:>3}d   {}",
            if lang == "zh" { "夜班" } else { "NT  " },
            stats.night,
            "█".repeat(stats.night as usize).color(shift_color(ShiftType::Night)),
        );
        println!(
            "  {}  {:>3}d   {}",
            if lang == "zh" { "学习" } else { "TR  " },
            stats.study,
            "█".repeat(stats.study as usize).color(shift_color(ShiftType::Study)),
        );
        println!();
        println!(
            "  {}",
            if lang == "zh" {
                format!("上班 {} 天 / {} 天", stats.work_days, stats.total_days)
            } else {
                format!("Work {}d / {}d", stats.work_days, stats.total_days)
            },
        );
    }
}

fn cmd_leave(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32, max_days: u32) {
    let lang = cli.lang.as_str();
    // Analyze from today to end of year
    let end_of_year = NaiveDate::from_ymd_opt(today.year(), 12, 31).unwrap();
    let days_to_analyze = ((end_of_year - today).num_days() + 1) as u32;

    let holidays = get_china_holidays();
    let plans = find_best_leave_plans(today, days_to_analyze, config, offset, Some(&holidays), max_days);

    if cli.json {
        let strategies: Vec<LeaveStrategyOutput> = plans
            .iter()
            .take(10)
            .enumerate()
            .map(|(i, s)| LeaveStrategyOutput {
                rank: (i + 1) as u32,
                leave_days: s.leave_days,
                total_break_days: s.total_break_days,
                break_start: s.break_start.format("%Y-%m-%d").to_string(),
                break_end: s.break_end.format("%Y-%m-%d").to_string(),
                efficiency: (s.efficiency * 10.0).round() / 10.0,
                score: (s.score * 100.0).round() / 100.0,
                holiday_overlap: s.holiday_overlap,
                weekend_overlap: s.weekend_overlap,
                holiday_names: s.overlapping_holiday_names.clone(),
                leave_dates: s.leave_dates.iter().map(|d| d.format("%Y-%m-%d").to_string()).collect(),
            })
            .collect();
        let out = LeaveOutput { strategies };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        let range = format!("{} → {}", today.format("%m/%d"), end_of_year.format("%m/%d"));
        println!(
            "{} {} · ≤ {} leave days · {}",
            "🏖️".bold(),
            if lang == "zh" { "最佳拼假方案".bold() } else { "Best Leave Plans".bold() },
            max_days,
            range.dimmed(),
        );
        println!();

        if plans.is_empty() {
            println!("  {}", if lang == "zh" { "未找到拼假方案".dimmed() } else { "No strategies found".dimmed() });
            return;
        }

        for (i, s) in plans.iter().take(10).enumerate() {
            let rank = if i == 0 { "🏆".to_string() } else { format!("{}", i + 1) };
            let eff_str = format!("{:.1}x", s.efficiency);
            let holiday_tag = if s.holiday_overlap > 0 {
                let names = s.overlapping_holiday_names.join("·");
                if lang == "zh" { format!(" 含{}", names) } else { format!(" +{}", names) }
            } else if s.weekend_overlap > 0 {
                if lang == "zh" { " 含周末".to_string() } else { " +weekend".to_string() }
            } else {
                String::new()
            };

            println!(
                "  {:>3}  {}d → break {}d  {:>5}  {} — {}{}",
                rank,
                s.leave_days.to_string().bold(),
                s.total_break_days.to_string().green().bold(),
                eff_str.yellow(),
                s.break_start.format("%m/%d"),
                s.break_end.format("%m/%d"),
                holiday_tag.dimmed(),
            );
        }

        if plans.len() > 10 {
            println!("  ... {} {} {}", plans.len() - 10, if lang == "zh" { "个方案" } else { "more" }, "".dimmed());
        }
    }
}

fn cmd_colleague(
    cli: &Cli,
    today: NaiveDate,
    config: &ShiftCycleConfig,
    team_a: u32,
    team_b: u32,
) {
    let lang = cli.lang.as_str();
    let end_of_year = NaiveDate::from_ymd_opt(today.year(), 12, 31).unwrap();
    let days_to_analyze = ((end_of_year - today).num_days() + 1) as u32;

    let result = find_common_rest_days(team_a, team_b, today, days_to_analyze, config);

    if cli.json {
        let out = ColleagueOutput {
            team_a,
            team_b,
            next_common_rest: result.next_common_rest_date.map(|d| d.format("%Y-%m-%d").to_string()),
            days_until_next: result.days_until_next,
            common_rest_dates: result
                .common_rest_dates
                .iter()
                .take(60)
                .map(|d| d.format("%Y-%m-%d").to_string())
                .collect(),
            count_30_days: result.count_in_30_days,
            count_60_days: result.count_in_60_days,
        };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        println!(
            "{} {} × {}",
            "👥".bold(),
            shift_algorithm::team_name(team_a).bold(),
            shift_algorithm::team_name(team_b).bold(),
        );
        println!();

        if let Some(next_date) = result.next_common_rest_date {
            let days = result.days_until_next.unwrap_or(0);
            println!(
                "  下次共同休息：{} {}",
                next_date.format("%m月%d日 %A").to_string().green().bold(),
                format!("(距今 {} 天)", days).dimmed(),
            );
        } else {
            println!("  {}", if lang == "zh" { "今年无共同休息日".dimmed() } else { "No common rest days this year".dimmed() });
        }

        println!();
        println!(
            "  未来30天: {} 次    未来60天: {} 次",
            result.count_in_30_days.to_string().bold(),
            result.count_in_60_days.to_string().bold(),
        );

        if !result.common_rest_dates.is_empty() {
            println!();
            println!("  {}", "共同休息日：".dimmed());
            for date in result.common_rest_dates.iter().take(12) {
                let info = get_shift_info(*date, config, config.team_phase_offset(team_a));
                let is_rest = info.shift_type.is_rest();
                let marker = if is_rest { "✓" } else { "?" };
                print!(
                    "  {} {}  ",
                    date.format("%m/%d").to_string().bold(),
                    marker.dimmed(),
                );
            }
            println!();
        }

        println!();
        println!(
            "  {}: {} → {}",
            if lang == "zh" { "分析范围" } else { "Range" },
            today.format("%Y/%m/%d").to_string().dimmed(),
            end_of_year.format("%Y/%m/%d").to_string().dimmed(),
        );
    }
}

fn cmd_waybar(today: NaiveDate, config: &ShiftCycleConfig, offset: u32, team: u32) {
    let info = get_shift_info(today, config, offset);
    let rest = days_until_next_rest(today, config, offset);

    let class = format!("{:?}", info.shift_type).to_lowercase();
    let text = match info.shift_type {
        ShiftType::Morning => "🌅 早".to_string(),
        ShiftType::Afternoon => "☀️ 中".to_string(),
        ShiftType::Rest => "🌿 休".to_string(),
        ShiftType::Night => "🌙 夜".to_string(),
        ShiftType::Study => "📚 学".to_string(),
    };
    let rest_text = if info.shift_type.is_rest() {
        "今日休息".to_string()
    } else if rest == 0 {
        "明天休息".to_string()
    } else {
        format!("距休 {} 天", rest)
    };
    let tooltip = format!(
        "{} · {} · 第 {}/{} 天 · {}",
        info.shift_type.full_label(),
        shift_algorithm::team_name(team),
        info.day_of_cycle,
        config.cycle_length,
        rest_text,
    );

    let out = WaybarOutput {
        text,
        class,
        tooltip,
    };
    println!("{}", serde_json::to_string(&out).unwrap());
}

fn cmd_export(
    today: NaiveDate,
    config: &ShiftCycleConfig,
    offset: u32,
    team: u32,
    output: Option<PathBuf>,
    open: bool,
) {
    let end_of_year = NaiveDate::from_ymd_opt(today.year(), 12, 31).unwrap();
    let path = output.unwrap_or_else(|| {
        dirs::data_local_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("banban")
            .join("shifts.ics")
    });

    // Ensure parent directory exists
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).ok();
    }

    let ics = generate_shift_ics(today, end_of_year, config, offset, team, None, "Asia/Shanghai");

    match std::fs::write(&path, &ics) {
        Ok(_) => {
            println!("ICS file exported to: {}", path.display());
            println!();
            println!("Import instructions:");
            println!("  Thunderbird: 日历 → 新建日历 → 从文件导入");
            println!("  GNOME:      设置 → 在线账户 → 从文件导入");
            println!("  Nextcloud:   日历 → 导入日历");
            println!("  Google:      settings → Import & export → Select file");
        }
        Err(e) => {
            eprintln!("导出失败: {}", e);
            std::process::exit(1);
        }
    }

    if open {
        let path_str = path.to_string_lossy().to_string();
        println!("正在用系统默认程序打开...");
        match std::process::Command::new("xdg-open").arg(&path_str).spawn() {
            Ok(_) => {} // xdg-open detaches, don't wait
            Err(e) => eprintln!("Can't open file: {} ({})", path_str, e),
        }
    }
}

fn cmd_notify(today: NaiveDate, cycle_config: &ShiftCycleConfig, offset: u32, team: u32) {
    let _lang = "en";
    let info = get_shift_info(today, cycle_config, offset);
    let rest = days_until_next_rest(today, cycle_config, offset);
    let config = Config::load(None);

    // Only notify if current time is close to this shift's alarm time (±10 min)
    // This prevents 3 irrelevant notifications per day when systemd timer
    // fires at all 3 shift alarm times.
    let alarm_key = match info.shift_type {
        ShiftType::Morning => "morning",
        ShiftType::Afternoon => "afternoon",
        ShiftType::Night => "night",
        _ => "", // Rest/Study: always notify (once at morning alarm time)
    };

    if !alarm_key.is_empty() {
        let alarm_str = match alarm_key {
            "morning" => config.alarms.morning.as_deref().unwrap_or("06:45"),
            "afternoon" => config.alarms.afternoon.as_deref().unwrap_or("13:45"),
            "night" => config.alarms.night.as_deref().unwrap_or("21:45"),
            _ => "",
        };
        if let Some((ah, am)) = alarm_str.split_once(':') {
            if let (Ok(ah), Ok(am)) = (ah.parse::<u32>(), am.parse::<u32>()) {
                let now = Local::now();
                let now_min = now.hour() * 60 + now.minute();
                let alarm_min = ah * 60 + am;
                let diff = (now_min as i32 - alarm_min as i32).abs();
                if diff > 10 {
                    // Not in the right time window — skip silently
                    return;
                }
            }
        }
    }

    let title = format!("{} · {}", info.shift_type.full_label(), shift_algorithm::team_name(team));
    let body = if info.shift_type.is_rest() {
        "今天是休息日".to_string()
    } else if rest == 0 {
        "明天休息".to_string()
    } else {
        format!("第 {}/{} 天 · 距休 {} 天", info.day_of_cycle, cycle_config.cycle_length, rest)
    };

    match notify_rust::Notification::new()
        .summary(&title)
        .body(&body)
        .appname("ShiftMate")
        .icon("calendar")
        .show()
    {
        Ok(_) => println!("Notification sent: {} — {}", title, body),
        Err(e) => eprintln!("Notification failed: {}", e),
    }
}

fn cmd_install() {
    let service_dir = dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("~/.config"))
        .join("systemd/user");
    std::fs::create_dir_all(&service_dir).ok();

    let banban_bin = std::env::current_exe()
        .map(|p| p.to_string_lossy().to_string())
        .unwrap_or_else(|_| "banban".to_string());

    // Read alarm config for timing
    let config = Config::load(None);
    let morning_time = config.alarms.morning.as_deref().unwrap_or("06:45");
    let afternoon_time = config.alarms.afternoon.as_deref().unwrap_or("13:45");
    let night_time = config.alarms.night.as_deref().unwrap_or("21:45");

    // Service: exports ICS daily (for calendar integration)
    let ics_service = format!(
        r#"[Unit]
Description=班伴 · 每日 ICS 导出

[Service]
Type=oneshot
ExecStart={0} export --ics
"#,
        banban_bin,
    );

    // Service: sends notification at alarm time
    let notify_service = format!(
        r#"[Unit]
Description=班伴 · 班次提醒通知

[Service]
Type=oneshot
ExecStart={0} notify
"#,
        banban_bin,
    );

    // Timer: ICS export daily at 00:00
    let ics_timer = r#"[Unit]
Description=班伴 · 每日 ICS 导出

[Timer]
OnCalendar=*-*-* 00:03:00
Persistent=true

[Install]
WantedBy=timers.target
"#;

    // Timer: notification at each shift's alarm time
    // banban notify checks if today's shift matches the alarm window
    let notify_timer = format!(
        r#"[Unit]
Description=班伴 · 班次提醒通知

[Timer]
OnCalendar=*-*-* {0}:00
OnCalendar=*-*-* {1}:00
OnCalendar=*-*-* {2}:00
Persistent=true
RandomizedDelaySec=60

[Install]
WantedBy=timers.target
"#,
        morning_time, afternoon_time, night_time,
    );

    std::fs::write(service_dir.join("banban-ics.service"), &ics_service).ok();
    std::fs::write(service_dir.join("banban-ics.timer"), ics_timer).ok();
    std::fs::write(service_dir.join("banban-notify.service"), &notify_service).ok();
    std::fs::write(service_dir.join("banban-notify.timer"), &notify_timer).ok();

    // Clean up old files from previous install
    let _ = std::fs::remove_file(service_dir.join("banban-notify.service.bak"));

    println!("systemd timers installed to: {}", service_dir.display());
    println!();
    println!("Alarm times (from config or defaults):");
    println!("  AM: {}  PM: {}  NT: {}", morning_time, afternoon_time, night_time);
    println!();
    println!("To change alarm times:");
    println!("  Edit ~/.config/banban/config.toml, add [alarms] section:");
    println!("  [alarms]");
    println!("  morning = \"06:30\"");
    println!("  afternoon = \"13:45\"");
    println!("  night = \"21:30\"");
    println!("  Then re-run: banban install");
    println!();
    // Generate initial ICS immediately so user doesn't wait until midnight
    println!("Generating initial ICS file...");
    let today = Local::now().date_naive();
    let end_of_year = NaiveDate::from_ymd_opt(today.year(), 12, 31).unwrap();
    let config = Config::load(None);
    let cycle_config = config.to_cycle_config();
    let team_id = if config.shift.default_team > 0 { config.shift.default_team } else { 1 };
    let offset = cycle_config.team_phase_offset(team_id);
    let ics_path = dirs::data_local_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("banban")
        .join("shifts.ics");
    if let Some(parent) = ics_path.parent() {
        std::fs::create_dir_all(parent).ok();
    }
    let ics = generate_shift_ics(today, end_of_year, &cycle_config, offset, team_id, None, "Asia/Shanghai");
    std::fs::write(&ics_path, &ics).ok();
    println!("  ICS: {}", ics_path.display());
    println!();

    println!("Enable timers:");
    println!("  systemctl --user enable --now banban-ics.timer");
    println!("  systemctl --user enable --now banban-notify.timer");
    println!();
    println!("Check status:");
    println!("  systemctl --user list-timers | grep banban");
    println!();
    println!("Waybar（添加到 ~/.config/waybar/config.json）:");
    println!(r#"  "custom/banban": {{"exec": "banban waybar", "interval": 3600}}"#);
}

fn cmd_config() {
    let config_dir = dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("banban");
    let config_path = config_dir.join("config.toml");

    let sample = r#"# 班伴 · ShiftMate 配置文件
# 修改后运行 banban install 重新生成 systemd 定时器

[shift]
# 排班周期：每天一个标签，写几个就几天
# 支持中文：早 中 休 夜 学
# 支持英文：morning afternoon rest night study
cycle = ["早","早","中","中","休","夜","休","休","早","早","中","中","休","夜","休","休","休","早","早","中","休","夜","夜","休","休","休","早","中","中","休","夜","夜","休","休","学","学","学","学","学","休","休"]

# 周期起始日（第 1 天是哪天）
reference_date = "2025-12-15"

# 默认班组编号（1=一值, ... 6=六值）
default_team = 1

# 总班组数
total_teams = 6

[alarms]
# 提醒时间，可选。不写则用默认值
morning = "06:45"     # 早班前提醒
afternoon = "13:45"   # 中班前提醒
night = "21:45"       # 夜班前提醒
"#;

    if config_path.exists() {
        println!("Config file already exists: {}", config_path.display());
        println!("Delete it first, then re-run banban config to regenerate");
    } else {
        std::fs::create_dir_all(&config_dir).ok();
        std::fs::write(&config_path, sample).ok();
        println!("Sample config file generated: {}", config_path.display());
        println!();
        println!("编辑这个文件来定义你自己的排班表，然后运行:");
        println!("  banban today");
    }
}

// ── Helpers ──

fn parse_month(today: NaiveDate, month: Option<&String>) -> (i32, u32) {
    match month {
        Some(m) if m.len() == 7 && m.contains('-') => {
            let parts: Vec<&str> = m.split('-').collect();
            (
                parts[0].parse().unwrap_or(today.year()),
                parts[1].parse().unwrap_or(today.month()),
            )
        }
        _ => (today.year(), today.month()),
    }
}

fn build_stats(
    year: i32,
    month: u32,
    config: &ShiftCycleConfig,
    offset: u32,
    total_days: u32,
) -> StatsOutput {
    StatsOutput {
        morning: count_shift_type_in_month(year, month, ShiftType::Morning, config, offset),
        afternoon: count_shift_type_in_month(year, month, ShiftType::Afternoon, config, offset),
        rest: count_shift_type_in_month(year, month, ShiftType::Rest, config, offset),
        night: count_shift_type_in_month(year, month, ShiftType::Night, config, offset),
        study: count_shift_type_in_month(year, month, ShiftType::Study, config, offset),
        work_days: count_work_days_in_month(year, month, config, offset),
        total_days,
    }
}
