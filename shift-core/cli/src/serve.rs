//! Local HTTP API server for banban.
//! Listens on localhost:11451, JSON responses only.

use axum::{
    Router,
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::get,
};
use chrono::{Datelike, Local, NaiveDate};
use serde::Serialize;
use shift_algorithm::{get_shift_info, ShiftCycleConfig, ShiftType};
use shift_statistics::{
    colleague::find_common_rest_days,
    metrics::{consecutive_work_days, days_until_next_rest},
};
use leave_optimizer::find_best_leave_plans;
use std::sync::Arc;

// ── App state ──

struct AppState {
    cycle_config: ShiftCycleConfig,
    team: u32,
    offset: u32,
}

// ── Response types ──

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
}

#[derive(Serialize)]
struct ShiftResponse {
    date: String,
    shift_type: String,
    shift_label: String,
    shift_label_zh: String,
    team: String,
    day_of_cycle: u32,
    total_days: u32,
    days_until_rest: u32,
    consecutive_work_days: u32,
}

#[derive(Serialize)]
struct CalendarDayResponse {
    date: String,
    shift_type: String,
    shift_label: String,
    is_current_month: bool,
    is_today: bool,
}

#[derive(Serialize)]
struct CalendarResponse {
    year: i32,
    month: u32,
    team: String,
    days: Vec<CalendarDayResponse>,
}

#[derive(Serialize)]
struct LeaveStrategyResponse {
    leave_days: u32,
    total_break_days: u32,
    leave_dates: Vec<String>,
    break_start: String,
    break_end: String,
    holiday_overlap: u32,
    weekend_overlap: u32,
    overlapping_holiday_names: Vec<String>,
    efficiency: f64,
    score: f64,
}

#[derive(Serialize)]
struct ColleagueResponse {
    team_a: String,
    team_b: String,
    next_common_rest_date: Option<String>,
    days_until_next: Option<u32>,
    common_rest_dates: Vec<String>,
    total_count: u32,
    count_in_30_days: u32,
    count_in_60_days: u32,
}

#[derive(Serialize)]
struct ErrorPayload {
    error: String,
}

// ── Labels ──

fn team_label(id: u32) -> String {
    let zh = ["一值", "二值", "三值", "四值", "五值", "六值"];
    let i = (id.saturating_sub(1) as usize) % 6;
    zh[i].into()
}

fn shift_label(st: ShiftType) -> &'static str {
    match st {
        ShiftType::Morning => "AM",
        ShiftType::Afternoon => "PM",
        ShiftType::Rest => "Off",
        ShiftType::Night => "NT",
        ShiftType::Study => "TR",
    }
}

fn shift_label_zh(st: ShiftType) -> &'static str {
    match st {
        ShiftType::Morning => "早",
        ShiftType::Afternoon => "中",
        ShiftType::Rest => "休",
        ShiftType::Night => "夜",
        ShiftType::Study => "学",
    }
}

fn err(msg: &str) -> (StatusCode, Json<ErrorPayload>) {
    (StatusCode::BAD_REQUEST, Json(ErrorPayload { error: msg.into() }))
}

// ── Handlers ──

async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".into(),
        version: env!("CARGO_PKG_VERSION").into(),
    })
}

async fn today_shift(
    State(state): State<Arc<AppState>>,
) -> Result<Json<ShiftResponse>, (StatusCode, Json<ErrorPayload>)> {
    shift_for_date(State(state), Path(Local::now().date_naive().to_string())).await
}

async fn shift_for_date(
    State(state): State<Arc<AppState>>,
    Path(date_str): Path<String>,
) -> Result<Json<ShiftResponse>, (StatusCode, Json<ErrorPayload>)> {
    let date = NaiveDate::parse_from_str(&date_str, "%Y-%m-%d")
        .map_err(|_| err(&format!("Invalid date: {date_str}. Use YYYY-MM-DD.")))?;

    let info = get_shift_info(date, &state.cycle_config, state.offset);
    let until_rest = days_until_next_rest(date, &state.cycle_config, state.offset);
    let consecutive = consecutive_work_days(date, &state.cycle_config, state.offset);

    Ok(Json(ShiftResponse {
        date: date_str,
        shift_type: format!("{:?}", info.shift_type),
        shift_label: shift_label(info.shift_type).into(),
        shift_label_zh: shift_label_zh(info.shift_type).into(),
        team: team_label(state.team),
        day_of_cycle: info.day_of_cycle,
        total_days: state.cycle_config.cycle_length,
        days_until_rest: until_rest,
        consecutive_work_days: consecutive,
    }))
}

async fn calendar(
    State(state): State<Arc<AppState>>,
    Path((year_str, month_str)): Path<(String, String)>,
) -> Result<Json<CalendarResponse>, (StatusCode, Json<ErrorPayload>)> {
    let year: i32 = year_str.parse().map_err(|_| err("Invalid year"))?;
    let month: u32 = month_str.parse().map_err(|_| err("Invalid month"))?;
    if !(1..=12).contains(&month) {
        return Err(err("Month must be 1-12"));
    }

    let today = Local::now().date_naive();
    let first = NaiveDate::from_ymd_opt(year, month, 1).unwrap();
    let start_offset = first.weekday().num_days_from_sunday();
    let start = first - chrono::Duration::days(start_offset as i64);

    let mut days = Vec::with_capacity(42);
    for i in 0..42u32 {
        let d = start + chrono::Duration::days(i as i64);
        let info = get_shift_info(d, &state.cycle_config, state.offset);
        days.push(CalendarDayResponse {
            date: d.to_string(),
            shift_type: format!("{:?}", info.shift_type),
            shift_label: shift_label(info.shift_type).into(),
            is_current_month: d.month() == month,
            is_today: d == today,
        });
    }

    Ok(Json(CalendarResponse {
        year,
        month,
        team: team_label(state.team),
        days,
    }))
}

#[derive(serde::Deserialize)]
struct LeaveQuery {
    #[serde(default = "default_max")]
    max_days: u32,
}

fn default_max() -> u32 { 5 }

async fn leave(
    State(state): State<Arc<AppState>>,
    Query(query): Query<LeaveQuery>,
) -> Json<Vec<LeaveStrategyResponse>> {
    let today = Local::now().date_naive();
    let holidays = holiday_engine::get_china_holidays();
    let plans = find_best_leave_plans(
        today,
        365,
        &state.cycle_config,
        state.offset,
        Some(&holidays),
        query.max_days,
    );

    Json(
        plans
            .into_iter()
            .map(|s| LeaveStrategyResponse {
                leave_days: s.leave_days,
                total_break_days: s.total_break_days,
                leave_dates: s.leave_dates.iter().map(|d| d.to_string()).collect(),
                break_start: s.break_start.to_string(),
                break_end: s.break_end.to_string(),
                holiday_overlap: s.holiday_overlap,
                weekend_overlap: s.weekend_overlap,
                overlapping_holiday_names: s.overlapping_holiday_names,
                efficiency: s.efficiency,
                score: s.score,
            })
            .collect(),
    )
}

async fn colleague(
    State(state): State<Arc<AppState>>,
    Path((team_a, team_b)): Path<(u32, u32)>,
) -> Result<Json<ColleagueResponse>, (StatusCode, Json<ErrorPayload>)> {
    if !(1..=6).contains(&team_a) || !(1..=6).contains(&team_b) {
        return Err(err("Team numbers must be 1-6"));
    }

    let today = Local::now().date_naive();
    let result = find_common_rest_days(team_a, team_b, today, 365, &state.cycle_config);

    Ok(Json(ColleagueResponse {
        team_a: team_label(team_a),
        team_b: team_label(team_b),
        next_common_rest_date: result.next_common_rest_date.map(|d| d.to_string()),
        days_until_next: result.days_until_next,
        common_rest_dates: result.common_rest_dates.iter().map(|d| d.to_string()).collect(),
        total_count: result.total_count,
        count_in_30_days: result.count_in_30_days,
        count_in_60_days: result.count_in_60_days,
    }))
}

// ── Server entry point ──

pub async fn run(cycle_config: ShiftCycleConfig, team: u32, offset: u32) {
    let state = Arc::new(AppState { cycle_config, team, offset });

    let app = Router::new()
        .route("/health", get(health))
        .route("/shift", get(today_shift))
        .route("/shift/{date}", get(shift_for_date))
        .route("/calendar/{year}/{month}", get(calendar))
        .route("/leave", get(leave))
        .route("/colleague/{team_a}/{team_b}", get(colleague))
        .with_state(state);

    let addr = "127.0.0.1:11451";
    println!("banban API server → http://{addr}");
    println!("  GET /health                  health check");
    println!("  GET /shift                   today's shift");
    println!("  GET /shift/YYYY-MM-DD        shift for a date");
    println!("  GET /calendar/YYYY/MM        monthly calendar");
    println!("  GET /leave?max_days=5        leave strategies");
    println!("  GET /colleague/1/3           common rest days");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
