//! Terminal UI — btop/lazygit style interactive shift viewer.

use chrono::{Datelike, Local, NaiveDate};
use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use crossterm::ExecutableCommand;
use ratatui::layout::{Alignment, Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style, Stylize};
use ratatui::text::{Line, Span, Text};
use ratatui::widgets::{Block, Gauge, List, ListItem, Paragraph};
use ratatui::Frame;
use shift_algorithm::{get_shift_info, ShiftCycleConfig, ShiftType};
use shift_statistics::metrics::{consecutive_work_days, count_shift_type_in_month, count_work_days_in_month, days_until_next_rest};
use shift_statistics::colleague::find_common_rest_days;
use leave_optimizer::find_best_leave_plans;
use unicode_width::UnicodeWidthStr;
use std::io;

enum View {
    Today,
    Calendar,
    Leave,
    Colleague,
}

struct App {
    view: View,
    today: NaiveDate,
    config: ShiftCycleConfig,
    offset: u32,
    team_id: u32,
    should_quit: bool,
    max_leave_days: u32,
    col_team_a: u32,
    col_team_b: u32,
    lang: String,
}

impl App {
    fn new(config: ShiftCycleConfig, offset: u32, team_id: u32, lang: String) -> Self {
        Self {
            view: View::Today,
            today: Local::now().date_naive(),
            config,
            offset,
            team_id,
            should_quit: false,
            max_leave_days: 5,
            col_team_a: team_id,
            col_team_b: if team_id < 3 { team_id + 2 } else { team_id - 2 },
            lang,
        }
    }

    fn is_zh(&self) -> bool { self.lang == "zh" }

    fn lbl(&self, st: ShiftType) -> &'static str {
        if self.is_zh() { st.label() } else { st.label_en() }
    }

    fn full_lbl(&self, st: ShiftType) -> &'static str {
        if self.is_zh() { st.full_label() } else { st.full_label_en() }
    }

    fn team_str(&self, id: u32) -> String {
        if self.is_zh() { shift_algorithm::team_name(id) } else { format!("Team {}", id) }
    }
}

pub fn run_tui(config: ShiftCycleConfig, offset: u32, team_id: u32, lang: &str) -> io::Result<()> {
    let mut app = App::new(config, offset, team_id, lang.to_string());

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    stdout.execute(EnterAlternateScreen)?;

    let mut terminal = ratatui::Terminal::new(ratatui::backend::CrosstermBackend::new(stdout))?;

    while !app.should_quit {
        terminal.draw(|f| draw(f, &app))?;
        handle_input(&mut app)?;
    }

    disable_raw_mode()?;
    terminal.backend_mut().execute(LeaveAlternateScreen)?;
    Ok(())
}

fn handle_input(app: &mut App) -> io::Result<()> {
    if event::poll(std::time::Duration::from_millis(100))? {
        if let Event::Key(key) = event::read()? {
            if key.kind == KeyEventKind::Press {
                match app.view {
                    View::Leave => match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => app.should_quit = true,
                        KeyCode::Char('1') => app.view = View::Today,
                        KeyCode::Char('2') => app.view = View::Calendar,
                        KeyCode::Char('4') => app.view = View::Colleague,
                        KeyCode::Char('+') | KeyCode::Char('=')
                            if app.max_leave_days < 10 => { app.max_leave_days += 1; }
                        KeyCode::Char('-') | KeyCode::Char('_') | KeyCode::Backspace
                            if app.max_leave_days > 1 => { app.max_leave_days -= 1; }
                        _ => {}
                    },
                    View::Colleague => match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => app.should_quit = true,
                        KeyCode::Char('1') => app.view = View::Today,
                        KeyCode::Char('2') => app.view = View::Calendar,
                        KeyCode::Char('3') => app.view = View::Leave,
                        KeyCode::Left | KeyCode::Char('h') => {
                            app.col_team_a = if app.col_team_a > 1 { app.col_team_a - 1 } else { 6 };
                        }
                        KeyCode::Right | KeyCode::Char('l') => {
                            app.col_team_a = if app.col_team_a < 6 { app.col_team_a + 1 } else { 1 };
                        }
                        KeyCode::Up | KeyCode::Char('k') => {
                            app.col_team_b = if app.col_team_b < 6 { app.col_team_b + 1 } else { 1 };
                        }
                        KeyCode::Down | KeyCode::Char('j') => {
                            app.col_team_b = if app.col_team_b > 1 { app.col_team_b - 1 } else { 6 };
                        }
                        _ => {}
                    },
                    _ => match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => app.should_quit = true,
                        KeyCode::Char('1') => app.view = View::Today,
                        KeyCode::Char('2') => app.view = View::Calendar,
                        KeyCode::Char('3') => app.view = View::Leave,
                        KeyCode::Char('4') => app.view = View::Colleague,
                        KeyCode::Char('t') => {
                            app.team_id = if app.team_id < 6 { app.team_id + 1 } else { 1 };
                            app.offset = app.config.team_phase_offset(app.team_id);
                        }
                        KeyCode::Char('T') => {
                            app.team_id = if app.team_id > 1 { app.team_id - 1 } else { 6 };
                            app.offset = app.config.team_phase_offset(app.team_id);
                        }
                        _ => {}
                    },
                }
            }
        }
    }
    Ok(())
}

fn draw(f: &mut Frame, app: &App) {
    let area = f.area();
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(3), Constraint::Length(1)])
        .split(area);

    match app.view {
        View::Today => draw_today(f, chunks[0], app),
        View::Calendar => draw_calendar(f, chunks[0], app),
        View::Leave => draw_leave(f, chunks[0], app),
        View::Colleague => draw_colleague(f, chunks[0], app),
    }

    draw_bottom_bar(f, chunks[1], app);
}

fn shift_tui_color(st: ShiftType) -> Color {
    match st {
        ShiftType::Morning => Color::Rgb(0xFF, 0xB3, 0x47),
        ShiftType::Afternoon => Color::Rgb(0x4D, 0xA3, 0xFF),
        ShiftType::Rest => Color::Rgb(0x35, 0xD0, 0x7F),
        ShiftType::Night => Color::Rgb(0x7C, 0x5C, 0xFF),
        ShiftType::Study => Color::Rgb(0xF2, 0xD9, 0x4E),
    }
}

fn month_name_en(m: u32) -> &'static str {
    match m {
        1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun",
        7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec",
        _ => "???",
    }
}

fn draw_today(f: &mut Frame, area: Rect, app: &App) {
    let info = get_shift_info(app.today, &app.config, app.offset);
    let rest = days_until_next_rest(app.today, &app.config, app.offset);
    let consec = consecutive_work_days(app.today, &app.config, app.offset);

    let color = shift_tui_color(info.shift_type);
    let rest_text = if info.shift_type.is_rest() {
        if app.is_zh() { "今天是休息日" } else { "Rest day" }.to_string()
    } else if rest == 0 {
        if app.is_zh() { "明天休息" } else { "Rest tomorrow" }.to_string()
    } else {
        if app.is_zh() { format!("距休 {} 天", rest) } else { format!("{}d until rest", rest) }
    };

    let h = area.height;
    let constraints: &[Constraint] = if h > 20 {
        &[Constraint::Length(3), Constraint::Length(2), Constraint::Length(2), Constraint::Length(1), Constraint::Length(2)]
    } else {
        &[Constraint::Length(2), Constraint::Length(1), Constraint::Length(1), Constraint::Length(0), Constraint::Length(1)]
    };
    let chunks = Layout::vertical(constraints).split(area);

    // Title
    let title = Paragraph::new(Line::from(vec![
        Span::styled(app.full_lbl(info.shift_type), Style::default().fg(color).add_modifier(Modifier::BOLD)),
        Span::raw(format!("  ·  {}  ·  {}", app.team_str(app.team_id), app.today.format("%Y-%m-%d %A"))),
    ]));
    f.render_widget(title, chunks[0]);

    // Progress
    let progress = info.day_of_cycle as f64 / app.config.cycle_length as f64;
    let gauge_label = if app.is_zh() {
        format!("第 {}/{} 天", info.day_of_cycle, app.config.cycle_length)
    } else {
        format!("Day {}/{}", info.day_of_cycle, app.config.cycle_length)
    };
    let gauge = Gauge::default()
        .gauge_style(Style::default().fg(color).add_modifier(Modifier::BOLD))
        .label(gauge_label)
        .ratio(progress);
    f.render_widget(gauge, chunks[1]);

    // Stats row
    let streak_label = if app.is_zh() { "连续上班" } else { "Work streak" };
    let stats = Line::from(vec![
        Span::raw("  "),
        Span::styled(rest_text, Style::default().fg(if info.shift_type.is_rest() { Color::Green } else { Color::White })),
        Span::raw("  │  "),
        Span::raw(format!("{} {}d", streak_label, consec)),
    ]);
    f.render_widget(Paragraph::new(stats), chunks[2]);

    if h <= 20 { return; }

    // Monthly overview
    let month = app.today.month();
    let year = app.today.year();
    let work = count_work_days_in_month(year, month, &app.config, app.offset);
    let days_in_month = NaiveDate::from_ymd_opt(
        if month == 12 { year + 1 } else { year },
        if month == 12 { 1 } else { month + 1 }, 1,
    ).map(|d| (d - NaiveDate::from_ymd_opt(year, month, 1).unwrap()).num_days() as u32).unwrap_or(30);

    let m = count_shift_type_in_month(year, month, ShiftType::Morning, &app.config, app.offset);
    let a = count_shift_type_in_month(year, month, ShiftType::Afternoon, &app.config, app.offset);
    let r = count_shift_type_in_month(year, month, ShiftType::Rest, &app.config, app.offset);
    let n = count_shift_type_in_month(year, month, ShiftType::Night, &app.config, app.offset);
    let s = count_shift_type_in_month(year, month, ShiftType::Study, &app.config, app.offset);

    let monthly = Paragraph::new(Line::from(vec![
        Span::raw(if app.is_zh() {
            format!("本月上班 {}/{}  ", work, days_in_month)
        } else {
            format!("Work {}/{}d  ", work, days_in_month)
        }),
        Span::styled(format!("{}{} ", app.lbl(ShiftType::Morning), m), Style::default().fg(shift_tui_color(ShiftType::Morning))),
        Span::styled(format!("{}{} ", app.lbl(ShiftType::Afternoon), a), Style::default().fg(shift_tui_color(ShiftType::Afternoon))),
        Span::styled(format!("{}{} ", app.lbl(ShiftType::Rest), r), Style::default().fg(shift_tui_color(ShiftType::Rest))),
        Span::styled(format!("{}{} ", app.lbl(ShiftType::Night), n), Style::default().fg(shift_tui_color(ShiftType::Night))),
        Span::styled(format!("{}{}", app.lbl(ShiftType::Study), s), Style::default().fg(shift_tui_color(ShiftType::Study))),
    ]));
    f.render_widget(monthly, chunks[4]);
}

fn draw_calendar(f: &mut Frame, area: Rect, app: &App) {
    let year = app.today.year();
    let month = app.today.month();
    let first = NaiveDate::from_ymd_opt(year, month, 1).unwrap();
    let weekday = first.weekday().num_days_from_sunday();
    let cal_start = first - chrono::Duration::days(weekday as i64);

    let cell_w = (area.width / 7).max(5) as usize;

    fn pad_width(s: &str, width: usize) -> String {
        let vis = UnicodeWidthStr::width(s);
        if vis >= width { s.to_string() } else { format!("{}{}", s, " ".repeat(width - vis)) }
    }

    let mut lines: Vec<Line> = Vec::new();

    let dow: &[&str] = if app.is_zh() {
        &["日", "一", "二", "三", "四", "五", "六"]
    } else {
        &["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    };
    let header_spans: Vec<Span> = dow.iter().map(|d| {
        Span::styled(pad_width(d, cell_w), Style::default().add_modifier(Modifier::BOLD))
    }).collect();
    lines.push(Line::from(header_spans));

    for w in 0..6 {
        let mut spans: Vec<Span> = Vec::new();
        for d in 0..7 {
            let date = cal_start + chrono::Duration::days((w * 7 + d) as i64);
            let info = get_shift_info(date, &app.config, app.offset);
            let is_cur = date.month() == month;
            let is_tdy = date == app.today;

            let content = format!("{:2}{}", date.day(), app.lbl(info.shift_type));
            let s = pad_width(&content, cell_w);

            let style = if !is_cur {
                Style::default().dim()
            } else if is_tdy {
                Style::default()
                    .fg(shift_tui_color(info.shift_type))
                    .add_modifier(Modifier::BOLD | Modifier::REVERSED)
            } else {
                Style::default().fg(shift_tui_color(info.shift_type))
            };
            spans.push(Span::styled(s, style));
        }
        lines.push(Line::from(spans));
    }

    let title = if app.is_zh() {
        format!("{}年{}月 · {}", year, month, app.team_str(app.team_id))
    } else {
        format!("{} {} · {}", month_name_en(month), year, app.team_str(app.team_id))
    };
    let cal = Paragraph::new(Text::from(lines)).block(Block::default().title(title));
    f.render_widget(cal, area);
}

fn draw_leave(f: &mut Frame, area: Rect, app: &App) {
    let end_of_year = NaiveDate::from_ymd_opt(app.today.year(), 12, 31).unwrap();
    let days = ((end_of_year - app.today).num_days() + 1) as u32;
    let plans = find_best_leave_plans(app.today, days, &app.config, app.offset, None, app.max_leave_days);

    let max_items = (area.height.saturating_sub(2)).max(3) as usize;

    let mut items: Vec<ListItem> = Vec::new();
    for (i, s) in plans.iter().take(max_items).enumerate() {
        let prefix = if i == 0 { "🏆" } else { "  " };
        let holiday_tag = if !s.overlapping_holiday_names.is_empty() {
            if app.is_zh() { format!(" 含{}", s.overlapping_holiday_names.join("·")) }
            else { format!(" +{}", s.overlapping_holiday_names.join("·")) }
        } else if s.weekend_overlap > 0 {
            if app.is_zh() { " 含周末".to_string() } else { " +weekend".to_string() }
        } else {
            String::new()
        };
        let line_text = if app.is_zh() {
            format!("{}d→{}d", s.leave_days, s.total_break_days)
        } else {
            format!("{}d → {}d break", s.leave_days, s.total_break_days)
        };
        let line = Line::from(vec![
            Span::raw(format!("{} ", prefix)),
            Span::styled(line_text, Style::default().add_modifier(Modifier::BOLD)),
            Span::raw(format!("  {:.1}x  {}–{}", s.efficiency, s.break_start.format("%m/%d"), s.break_end.format("%m/%d"))),
            Span::styled(holiday_tag, Style::default().fg(Color::Yellow)),
        ]);
        items.push(ListItem::new(line));
    }

    let title = if app.is_zh() {
        format!("拼假方案 · +/-请假天数({}) · {} → 12/31", app.max_leave_days, app.today.format("%m/%d"))
    } else {
        format!("Leave Plans · +/-leave({}) · {} → 12/31", app.max_leave_days, app.today.format("%m/%d"))
    };
    let list = List::new(items).block(Block::default().title(title));
    f.render_widget(list, area);
}

fn draw_colleague(f: &mut Frame, area: Rect, app: &App) {
    let end_of_year = NaiveDate::from_ymd_opt(app.today.year(), 12, 31).unwrap();
    let days = ((end_of_year - app.today).num_days() + 1) as u32;
    let result = find_common_rest_days(app.col_team_a, app.col_team_b, app.today, days, &app.config);

    let h = area.height;
    let constraints: &[Constraint] = if h > 10 {
        &[Constraint::Length(3), Constraint::Length(2), Constraint::Min(3)]
    } else {
        &[Constraint::Length(2), Constraint::Length(1), Constraint::Min(1)]
    };
    let chunks = Layout::vertical(constraints).split(area);

    if let Some(next) = result.next_common_rest_date {
        let until = result.days_until_next.unwrap_or(0);
        let next_text = Paragraph::new(Line::from(vec![
            Span::raw(if app.is_zh() { "下次共同休息：" } else { "Next common rest: " }),
            Span::styled(format!("{}", next.format("%b %d %A")), Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)),
            Span::raw(format!("  ({} {}d)", if app.is_zh() { "距今 " } else { "" }, until)),
        ]));
        f.render_widget(next_text, chunks[0]);
    } else {
        f.render_widget(Paragraph::new(if app.is_zh() { "今年无共同休息日" } else { "No common rest days" }), chunks[0]);
    }

    let stats = if app.is_zh() {
        format!("未来30天: {} 次    未来60天: {} 次", result.count_in_30_days, result.count_in_60_days)
    } else {
        format!("30 days: {}    60 days: {}", result.count_in_30_days, result.count_in_60_days)
    };
    f.render_widget(Paragraph::new(stats), chunks[1]);

    let max_dates = (chunks[2].height).max(3) as usize;
    let dates: Vec<ListItem> = result.common_rest_dates.iter().take(max_dates)
        .map(|d| ListItem::new(format!("  {} {}", d.format("%m/%d"), d.format("%A"))))
        .collect();

    let title = if app.is_zh() {
        format!("{}×{} 共同休息日", app.team_str(app.col_team_a), app.team_str(app.col_team_b))
    } else {
        format!("{} × {} Common Rests", app.team_str(app.col_team_a), app.team_str(app.col_team_b))
    };
    let list = List::new(dates).block(Block::default().title(title));
    f.render_widget(list, chunks[2]);
}

fn draw_bottom_bar(f: &mut Frame, area: Rect, app: &App) {
    let help: String = if app.is_zh() {
        match app.view {
            View::Today => "1今日  2日历  3拼假  4同事  t/T换班组  q退出".into(),
            View::Calendar => "1今日  2日历  3拼假  4同事  t/T换班组  q退出".into(),
            View::Leave => format!("1今日  2日历  3拼假  4同事  +/-请假天数({})  q退出", app.max_leave_days),
            View::Colleague => format!("1今日  2日历  3拼假  4同事  ←→调我({})  ↑↓调他({})  q退出",
                app.team_str(app.col_team_a), app.team_str(app.col_team_b)),
        }
    } else {
        match app.view {
            View::Today => "1Today  2Cal  3Leave  4Colleague  t/T team  q quit".into(),
            View::Calendar => "1Today  2Cal  3Leave  4Colleague  t/T team  q quit".into(),
            View::Leave => format!("1Today  2Cal  3Leave  4Colleague  +/-leave({})  q quit", app.max_leave_days),
            View::Colleague => format!("1Today  2Cal  3Leave  4Colleague  ←→me({})  ↑↓them({})  q quit",
                app.team_str(app.col_team_a), app.team_str(app.col_team_b)),
        }
    };
    let bar = Paragraph::new(help)
        .style(Style::default().bg(Color::DarkGray).fg(Color::White))
        .alignment(Alignment::Center);
    f.render_widget(bar, area);

}