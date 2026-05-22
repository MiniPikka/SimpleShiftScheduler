# 班伴 · ShiftMate

**倒班人群的生活伴侣** — shift schedule engine written in Rust.

## What is this?

A worker on a rotating shift schedule (e.g. 42-day cycle, 6 teams) can answer:

- **What shift am I on today?** → `banban today`
- **When do I next rest?** → `banban next-rest`
- **How should I take leave to maximize my break?** → `banban leave`
- **When can my colleague and I rest together?** → `banban colleague 1 3`

## Crates

| Crate | Purpose | Status |
|-------|---------|--------|
| [`shift-algorithm`](crates/shift-algorithm/) | Core scheduling algorithm (date → shift type) | ✅ Stable |
| [`shift-statistics`](crates/shift-statistics/) | Monthly stats, colleague mode | ✅ Stable |
| [`holiday-engine`](crates/holiday-engine/) | 2026-2027 Chinese statutory holidays | ✅ Stable |
| [`leave-optimizer`](crates/leave-optimizer/) | Gap-merging leave strategy optimizer | ✅ Stable |
| [`export-engine`](crates/export-engine/) | ICS calendar file export | 🏗️ Phase 2 |

## Quick start

```bash
# Build and test
cd shift-core
cargo build
cargo test

# Run the CLI
cargo run --bin banban -- today
cargo run --bin banban -- -t 2 calendar
cargo run --bin banban -- leave -m 3
cargo run --bin banban -- colleague 1 3
```

## Install

```bash
cargo install --path cli --root ~/.local
~/.local/bin/banban today
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
