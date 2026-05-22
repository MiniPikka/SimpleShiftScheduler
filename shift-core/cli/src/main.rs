//! # banban — 班伴 CLI
//!
//! Command-line tool for querying shift schedules.
//! Named after the product 班伴 (ShiftMate).
//! Default: human-readable ANSI-colored output.
//! With --json: machine-readable JSON.

use chrono::{Datelike, Local, NaiveDate};
use clap::{Parser, Subcommand};
use colored::*;
use export_engine::generate_shift_ics;
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
    fn load() -> Self {
        let path = dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("banban")
            .join("config.toml");

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
        let cycle = if self.shift.cycle_length == 42 {
            default_shift_cycle()
        } else {
            // Generate a simple repeating cycle for custom lengths
            // User should edit config.toml for full custom cycles (future: cycle array in config)
            default_shift_cycle()[..self.shift.cycle_length as usize].to_vec()
        };
        ShiftCycleConfig {
            cycle_length: self.shift.cycle_length,
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
            },
            alarms: AlarmSection::default(),
        }
    }
}

// ── CLI definition ──

/// 倒班工人每天按照固定周期轮换班次：早→早→中→中→休→夜→夜→休→...
/// 42 天一个循环，6 个班组（一值～六值）各差 7 天。
///
/// 这个工具帮你查今天什么班、什么时候休息、怎么请假最划算、
/// 和另一个班组的人哪天能一起休息。
///
/// 第一步：如果你不是一值（默认），先告诉工具你的班组：
///   banban --team 2 today              试试看今天什么班
///   banban --team 2 calendar           看看这个月的排班日历
///
/// 第二步：觉得班组对了，写进配置文件免得每次敲 --team：
///   mkdir -p ~/.config/banban
///   printf '\[shift]\ndefault_team = 2\n' > ~/.config/banban/config.toml
///
/// 第三步：每天敲 banban 看一眼，或者加到 Waybar 状态栏上。
#[derive(Parser)]
#[command(
    name = "banban",
    version,
    about = "班伴 — 倒班助手命令行",
    long_about = "倒班工人每天按照固定周期轮换班次：早→早→中→中→休→夜→夜→休→...\n42 天一个循环，6 个班组（一值～六值）各差 7 天。\n\n这个工具帮你查今天什么班、什么时候休息、怎么请假最划算、\n和另一个班组的人哪天能一起休息。",
    after_help = "快速上手：\n  \
                  banban today              看看今天什么班\n  \
                  banban --team 2 today     如果你是二值，试试这个\n  \
                  banban calendar           这个月的排班日历\n  \
                  banban next-rest          还有几天休息\n  \
                  banban leave              今年怎么请假最划算\n  \
                  banban colleague 1 3      一值和三值哪天能一起休\n  \
                  banban waybar             Waybar 状态栏上显示班次\n  \
                  \n  \
                  默认就是一值（第 1 班组），周期 42 天，起始日 2025-12-15。\n  \
                  如果你的班组不同，用 --team 或写配置文件：\n  \
                  ~/.config/banban/config.toml"
)]
struct Cli {
    /// 输出 JSON 格式（给脚本用），默认是给人看的彩色文字
    #[arg(short, long, global = true)]
    json: bool,

    /// 你的班组编号（1=一值, 2=二值, ..., 6=六值），不写默认读配置文件或一值
    #[arg(short = 't', long, global = true, default_value = "0")]
    team: u32,

    /// 指定配置文件路径（默认 ~/.config/shift/config.toml）
    #[arg(short, long, global = true)]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 今天什么班？周期第几天？还有几天休息？
    Today,
    /// 明天什么班？
    Tomorrow,
    /// 距离下次休息还有几天（"明天休息" 或 "距休 3 天"）
    NextRest,
    /// 月历视图，每一天用颜色标出班次（橙早/蓝中/绿休/紫夜/黄学）
    Calendar {
        /// 哪个月，如 2026-06（不写就是当月）
        month: Option<String>,
    },
    /// 这个月每种班次各有几天（带 ASCII 进度条）
    Stats {
        /// 哪个月，如 2026-06（不写就是当月）
        month: Option<String>,
    },
    /// 拼假神器：分析今天到年底，结合你的排班和法定节假日，
    /// 算出怎么请假最划算（请最少天，连休最久）。
    Leave {
        /// 最多愿意请几天假（默认 5 天）
        #[arg(short, long, default_value = "5")]
        max_days: u32,
    },
    /// 同事模式：两个班组哪天能一起休息？
    /// "我是二值，她是五值，我们什么时候能一起休？"
    Colleague {
        /// 我的班组（1=一值, ... 6=六值）
        team_a: u32,
        /// 对方的班组（1=一值, ... 6=六值）
        team_b: u32,
    },
    /// Waybar 状态栏显示班次（给 Sway/Hyprland 用）。
    /// 配置：~/.config/waybar/config.json 中加
    ///   "custom/banban": {"exec": "banban waybar", "interval": 3600}
    Waybar,
    /// 导出 ICS 日历文件，可导入 Thunderbird/Nextcloud/Google Calendar 等。
    /// 每天一个独立事件，全年约 365 条。
    ///
    /// 示例：
    ///   banban export --ics              导出到默认路径
    ///   banban export --ics --open       导出并用系统默认程序打开（通常是 Thunderbird）
    ///   banban export --ics -o ~/shifts.ics  导出到指定路径
    Export {
        /// 导出 ICS 格式
        #[arg(long)]
        ics: bool,
        /// 输出文件路径（默认 ~/.local/share/banban/shifts.ics）
        #[arg(short, long)]
        output: Option<PathBuf>,
        /// 生成后用系统默认程序打开（通常是 Thunderbird 或日历 App）
        #[arg(long)]
        open: bool,
    },
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

fn team_name(id: u32) -> String {
    let prefix = match id {
        1 => "一",
        2 => "二",
        3 => "三",
        4 => "四",
        5 => "五",
        6 => "六",
        _ => return format!("{}值", id),
    };
    format!("{}值", prefix)
}

// ── Main ──

fn main() {
    let cli = Cli::parse();
    let config = Config::load();
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
    }
}

// ── Command handlers ──

fn cmd_today(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32, team: u32) {
    let info = get_shift_info(today, config, offset);
    let rest = days_until_next_rest(today, config, offset);
    let consec = consecutive_work_days(today, config, offset);

    if cli.json {
        let out = TodayOutput {
            date: today.format("%Y-%m-%d").to_string(),
            shift_type: format!("{:?}", info.shift_type).to_lowercase(),
            shift_label: info.shift_type.full_label().to_string(),
            team: team_name(team),
            day_of_cycle: info.day_of_cycle,
            total_days: config.cycle_length,
            days_until_rest: rest,
            consecutive_work_days: consec,
        };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        let color = shift_color(info.shift_type);
        let rest_msg = if info.shift_type.is_rest() {
            "今天是休息日 🎉".green().bold().to_string()
        } else if rest == 0 {
            "明天休息".green().to_string()
        } else {
            format!("距休 {} 天", rest)
        };
        println!(
            "{} {} · {} · 第 {}/{} 天 · {}",
            shift_icon(info.shift_type),
            info.shift_type.full_label().color(color).bold(),
            team_name(team).dimmed(),
            info.day_of_cycle,
            config.cycle_length,
            rest_msg,
        );
        println!(
            "  {} {} · {} {}",
            "连续上班".dimmed(),
            format!("{}天", consec).bold(),
            "日期".dimmed(),
            today.format("%Y-%m-%d %A").to_string().dimmed(),
        );
    }
}

fn cmd_tomorrow(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32, team: u32) {
    let tomorrow = today + chrono::Duration::days(1);
    let info = get_shift_info(tomorrow, config, offset);

    if cli.json {
        println!(
            "{}",
            serde_json::json!({
                "date": tomorrow.format("%Y-%m-%d").to_string(),
                "shift_type": format!("{:?}", info.shift_type).to_lowercase(),
                "shift_label": info.shift_type.full_label(),
                "team": team_name(team),
                "day_of_cycle": info.day_of_cycle,
                "total_days": config.cycle_length,
            })
            .to_string()
        );
    } else {
        let color = shift_color(info.shift_type);
        println!(
            "{} {} · {} · 第 {}/{} 天",
            shift_icon(info.shift_type),
            info.shift_type.full_label().color(color).bold(),
            tomorrow.format("%m月%d日 %A").to_string().dimmed(),
            info.day_of_cycle,
            config.cycle_length,
        );
    }
}

fn cmd_next_rest(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32) {
    let info = get_shift_info(today, config, offset);
    let today_is_rest = info.shift_type.is_rest();
    let days = days_until_next_rest(today, config, offset);

    if cli.json {
        let rest_date = if today_is_rest {
            today
        } else {
            today + chrono::Duration::days(days as i64)
        };
        let msg = if today_is_rest {
            "今天休息".into()
        } else if days == 0 {
            "明天休息".into()
        } else {
            format!("距休 {} 天", days)
        };
        let out = NextRestOutput {
            days_until: if today_is_rest { 0 } else { days },
            rest_date: rest_date.format("%Y-%m-%d").to_string(),
            message: msg,
        };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        if today_is_rest {
            println!("{} {}", "🟢".bold(), "今天是休息日".green().bold());
        } else if days == 0 {
            let tomorrow = today + chrono::Duration::days(1);
            println!(
                "{} {} · {}",
                "🟢".bold(),
                "明天休息".green().bold(),
                tomorrow.format("%m月%d日 %A").to_string().dimmed(),
            );
        } else {
            let rest_date = today + chrono::Duration::days(days as i64);
            println!(
                "{} {} {} 天 · {} {}",
                "⏳".bold(),
                "距下次休息".dimmed(),
                days.to_string().bold(),
                "休息日".dimmed(),
                rest_date.format("%m月%d日 %A").to_string().bold(),
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
                    shift_label: info.shift_type.label().to_string(),
                    is_current_month: date.month() == month_num,
                    is_today: date == today,
                });
            }
            weeks.push(week);
        }
        let stats = build_stats(year, month_num, config, offset, total_days);
        let out = CalendarOutput {
            month: format!("{}-{:02}", year, month_num),
            team: team_name(team),
            weeks,
            stats,
        };
        println!("{}", serde_json::to_string_pretty(&out).unwrap());
    } else {
        println!(
            "{} {} · {}",
            "📅".bold(),
            format!("{}年{}月", year, month_num).bold(),
            team_name(team).dimmed(),
        );
        println!("{}", "日  一  二  三  四  五  六".dimmed());

        for w in 0..6 {
            for d in 0..7 {
                let date = cal_start + chrono::Duration::days((w * 7 + d) as i64);
                let info = get_shift_info(date, config, offset);
                let is_cur = date.month() == month_num;
                let is_tdy = date == today;

                let label = info.shift_type.label();

                if !is_cur {
                    print!("{} ", format!("{:2} {}", date.day(), label).dimmed());
                } else if is_tdy {
                    print!(
                        "{} ",
                        format!("{:2}{}", date.day(), label)
                            .color(shift_color(info.shift_type))
                            .bold()
                            .on_bright_black()
                    );
                } else {
                    let s = format!("{:2}{}", date.day(), label);
                    print!("{} ", s.color(shift_color(info.shift_type)));
                }
            }
            println!();
        }

        // Inline stats
        let stats = build_stats(year, month_num, config, offset, total_days);
        println!();
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
            format!("{}年{}月 统计", year, month_num).bold(),
            team_name(team).dimmed(),
        );
        println!();
        println!(
            "  早班  {:>3} 天   {}",
            stats.morning,
            "█".repeat(stats.morning as usize).color(shift_color(ShiftType::Morning)),
        );
        println!(
            "  中班  {:>3} 天   {}",
            stats.afternoon,
            "█".repeat(stats.afternoon as usize).color(shift_color(ShiftType::Afternoon)),
        );
        println!(
            "  休班  {:>3} 天   {}",
            stats.rest,
            "█".repeat(stats.rest as usize).color(shift_color(ShiftType::Rest)),
        );
        println!(
            "  夜班  {:>3} 天   {}",
            stats.night,
            "█".repeat(stats.night as usize).color(shift_color(ShiftType::Night)),
        );
        println!(
            "  学习  {:>3} 天   {}",
            stats.study,
            "█".repeat(stats.study as usize).color(shift_color(ShiftType::Study)),
        );
        println!();
        println!(
            "  上班 {} 天 / {} 天",
            stats.work_days.to_string().bold(),
            stats.total_days,
        );
    }
}

fn cmd_leave(cli: &Cli, today: NaiveDate, config: &ShiftCycleConfig, offset: u32, max_days: u32) {
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
            "{} {} · 请假 ≤ {} 天 · {}",
            "🏖️".bold(),
            "最佳拼假方案".bold(),
            max_days,
            range.dimmed(),
        );
        println!();

        if plans.is_empty() {
            println!("  {}", "未找到拼假方案".dimmed());
            return;
        }

        for (i, s) in plans.iter().take(10).enumerate() {
            let rank = if i == 0 { "🏆".to_string() } else { format!("{}", i + 1) };
            let eff_str = format!("{:.1}x", s.efficiency);
            let holiday_tag = if s.holiday_overlap > 0 {
                let names = s.overlapping_holiday_names.join("·");
                format!(" 含{}", names)
            } else if s.weekend_overlap > 0 {
                " 含周末".to_string()
            } else {
                String::new()
            };

            println!(
                "  {:>3} 请 {} 天 → 连休 {} 天  {:>5}  {} — {}{}",
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
            println!("  ... 还有 {} 个方案", plans.len() - 10);
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
            team_name(team_a).bold(),
            team_name(team_b).bold(),
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
            println!("  {}", "今年无共同休息日".dimmed());
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
            "  分析范围：{} → {}",
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
        ShiftType::Morning => format!("🌅 早"),
        ShiftType::Afternoon => format!("☀️ 中"),
        ShiftType::Rest => format!("🌿 休"),
        ShiftType::Night => format!("🌙 夜"),
        ShiftType::Study => format!("📚 学"),
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
        team_name(team),
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
            println!("ICS 文件已导出到: {}", path.display());
            println!();
            println!("导入方法：");
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
            Err(e) => eprintln!("无法打开文件: {} ({}))", path_str, e),
        }
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
