//! DBus daemon for banban.
//! Registers on the session bus as `com.simpleshift.ShiftDaemon`.
//!
//! Usage: `banban dbus` — runs in foreground until Ctrl+C.
//!
//! Test: `busctl --user call com.simpleshift.ShiftDaemon \
//!        /com/simpleshift/Shift com.simpleshift.ShiftDaemon1 GetTodayShift`

use chrono::{Local, NaiveDate};
use serde::Serialize;
use shift_algorithm::{get_shift_info, ShiftCycleConfig, ShiftType};
use shift_statistics::metrics::days_until_next_rest;
use std::sync::Arc;
use tokio::sync::RwLock;
use zbus::interface;

// ── Shared state ──

struct DaemonState {
    cycle_config: ShiftCycleConfig,
    team: u32,
    offset: u32,
    last_date: RwLock<NaiveDate>,
}

// ── JSON helpers ──

fn team_label(id: u32) -> &'static str {
    ["一值", "二值", "三值", "四值", "五值", "六值"][(id.saturating_sub(1) as usize) % 6]
}

fn shift_label(st: ShiftType) -> &'static str {
    match st {
        ShiftType::Morning => "早",
        ShiftType::Afternoon => "中",
        ShiftType::Rest => "休",
        ShiftType::Night => "夜",
        ShiftType::Study => "学",
    }
}

#[derive(Serialize)]
struct ShiftJson {
    date: String,
    shift_type: String,
    shift_label: String,
    team: String,
    day_of_cycle: u32,
    total_days: u32,
    days_until_rest: u32,
}

fn build_shift_json(date: NaiveDate, config: &ShiftCycleConfig, offset: u32, team: u32) -> ShiftJson {
    let info = get_shift_info(date, config, offset);
    let until_rest = days_until_next_rest(date, config, offset);
    ShiftJson {
        date: date.to_string(),
        shift_type: format!("{:?}", info.shift_type),
        shift_label: shift_label(info.shift_type).into(),
        team: team_label(team).into(),
        day_of_cycle: info.day_of_cycle,
        total_days: config.cycle_length,
        days_until_rest: until_rest,
    }
}

#[derive(Serialize)]
struct ConfigJson {
    cycle_length: u32,
    reference_date: String,
    default_team: u32,
    total_teams: u32,
}

// ── DBus interface ──

struct ShiftDaemon {
    state: Arc<DaemonState>,
}

#[interface(name = "com.simpleshift.ShiftDaemon1")]
impl ShiftDaemon {
    /// Get today's shift info as JSON.
    async fn get_today_shift(&self) -> String {
        let today = Local::now().date_naive();
        let st = self.state.as_ref();
        serde_json::to_string(&build_shift_json(today, &st.cycle_config, st.offset, st.team))
            .unwrap_or_else(|e| format!(r#"{{"error":"{e}"}}"#))
    }

    /// Get shift info for a specific date (YYYY-MM-DD).
    async fn get_shift_for_date(&self, date_iso: &str) -> String {
        let date = match NaiveDate::parse_from_str(date_iso, "%Y-%m-%d") {
            Ok(d) => d,
            Err(e) => return format!(r#"{{"error":"{e}"}}"#),
        };
        let st = self.state.as_ref();
        serde_json::to_string(&build_shift_json(date, &st.cycle_config, st.offset, st.team))
            .unwrap_or_else(|e| format!(r#"{{"error":"{e}"}}"#))
    }

    /// Get days until next rest as JSON.
    async fn get_upcoming_rest(&self) -> String {
        let today = Local::now().date_naive();
        let st = self.state.as_ref();
        let days = days_until_next_rest(today, &st.cycle_config, st.offset);
        let info = get_shift_info(today, &st.cycle_config, st.offset);
        serde_json::to_string(&serde_json::json!({
            "date": today.to_string(),
            "shift_label": shift_label(info.shift_type),
            "days_until_rest": days,
        }))
        .unwrap_or_else(|e| format!(r#"{{"error":"{e}"}}"#))
    }

    /// Get current shift configuration as JSON.
    async fn get_config(&self) -> String {
        let st = self.state.as_ref();
        serde_json::to_string(&ConfigJson {
            cycle_length: st.cycle_config.cycle_length,
            reference_date: st.cycle_config.reference_date.to_string(),
            default_team: st.team,
            total_teams: st.cycle_config.total_teams,
        })
        .unwrap_or_else(|e| format!(r#"{{"error":"{e}"}}"#))
    }
}

// ── Signal emission (manual, no macro) ──

async fn emit_signal(
    conn: &zbus::Connection,
    signal_name: &str,
    body: &str,
) -> zbus::Result<()> {
    conn.emit_signal(
        None::<&str>,
        "/com/simpleshift/Shift",
        "com.simpleshift.ShiftDaemon1",
        signal_name,
        &body,
    )
    .await
}

// ── Background task: day-change monitor ──

async fn monitor_day_change(conn: zbus::Connection, state: Arc<DaemonState>) {
    let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(30));
    loop {
        interval.tick().await;
        let today = Local::now().date_naive();
        let mut last = state.last_date.write().await;
        if today != *last {
            let prev = *last;
            *last = today;

            let info = get_shift_info(today, &state.cycle_config, state.offset);
            let shift_str = shift_label(info.shift_type);
            let date_str = today.to_string();

            if let Err(e) = emit_signal(&conn, "ShiftChanged", shift_str).await {
                eprintln!("DBus: ShiftChanged signal failed: {e}");
            }
            if let Err(e) = emit_signal(&conn, "DayChanged", &date_str).await {
                eprintln!("DBus: DayChanged signal failed: {e}");
            }

            eprintln!(
                "DBus: day changed {} → {}, shift={}",
                prev, date_str, shift_str
            );
        }
    }
}

// ── Entry point ──

pub async fn run(cycle_config: ShiftCycleConfig, team: u32, offset: u32) -> zbus::Result<()> {
    let today = Local::now().date_naive();
    let state = Arc::new(DaemonState {
        cycle_config,
        team,
        offset,
        last_date: RwLock::new(today),
    });

    let daemon = ShiftDaemon { state: state.clone() };

    let conn = zbus::Connection::session().await?;
    conn.request_name("com.simpleshift.ShiftDaemon").await?;
    conn.object_server()
        .at("/com/simpleshift/Shift", daemon)
        .await?;

    eprintln!(
        "DBus service: com.simpleshift.ShiftDaemon → /com/simpleshift/Shift"
    );
    eprintln!("  Methods: GetTodayShift, GetShiftForDate(s), GetUpcomingRest, GetConfig");
    eprintln!("  Signals: ShiftChanged(s), DayChanged(s) (30s poll)");

    let monitor_conn = conn.clone();
    tokio::spawn(monitor_day_change(monitor_conn, state));

    tokio::signal::ctrl_c().await.ok();
    eprintln!("DBus: shutting down.");
    Ok(())
}
