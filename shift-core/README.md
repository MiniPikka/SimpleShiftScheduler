# 班伴 · ShiftMate

**倒班人群的生活伴侣** — shift schedule engine written in Rust.

## What is this?

A worker on a rotating shift schedule (e.g. 42-day cycle, 6 teams) can answer:

- **What shift am I on today?** → `banban today`
- **When do I next rest?** → `banban next-rest`
- **How should I take leave to maximize my break?** → `banban leave`
- **When can my colleague and I rest together?** → `banban colleague 1 3`
- **Show shift in Waybar status bar** → `banban waybar` (supports `--lang` and custom labels)

## Crates

| Crate | crates.io | Purpose |
|-------|-----------|---------|
| [`shift-algorithm`](crates/shift-algorithm/) | [![crates.io](https://img.shields.io/crates/v/shift-algorithm)](https://crates.io/crates/shift-algorithm) | Core scheduling algorithm (date → shift type) |
| [`shift-statistics`](crates/shift-statistics/) | [![crates.io](https://img.shields.io/crates/v/shift-statistics)](https://crates.io/crates/shift-statistics) | Monthly stats, colleague mode |
| [`holiday-engine`](crates/holiday-engine/) | [![crates.io](https://img.shields.io/crates/v/holiday-engine)](https://crates.io/crates/holiday-engine) | 2026-2027 Chinese statutory holidays |
| [`leave-optimizer`](crates/leave-optimizer/) | [![crates.io](https://img.shields.io/crates/v/leave-optimizer)](https://crates.io/crates/leave-optimizer) | Gap-merging leave strategy optimizer |
| [`shift-export`](crates/shift-export/) | [![crates.io](https://img.shields.io/crates/v/shift-export)](https://crates.io/crates/shift-export) | ICS (RFC 5545) calendar file export |
| [`shift-cli`](cli/) | [![crates.io](https://img.shields.io/crates/v/shift-cli)](https://crates.io/crates/shift-cli) | CLI + TUI — binary `banban` |

## Quick start

```bash
# Install from crates.io
cargo install shift-cli
banban today

# Or build from source
cd shift-core
cargo build
cargo run --bin banban -- today
cargo test                       # 111 tests
```

## Documentation

```bash
cargo doc --open    # Open full API docs in browser
```

Each crate has rustdoc comments with examples. The doc examples also serve as tests — run `cargo test` to verify them.

## Algorithm constants

Shared across Android (Kotlin), Flutter (Dart), and Rust implementations:

| Constant | Value |
|----------|-------|
| Reference date | 2025-12-15 (day 1) |
| Cycle length | 42 days |
| Total teams | 6 |
| Team offset | `(team_id - 1) × 7` days |

## License

MIT
