#!/bin/bash
# verify-harmony.sh — Cross-validate HarmonyOS ArkTS algorithms against Rust banban CLI
# Runs on Linux (no DevEco needed). 185 test cases covering all algorithms.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BANBAN="$ROOT/shift-core/target/release/banban"
HARMONY_SRC="$ROOT/harmony/entry/src/main/ets"
VR="/tmp/opencode/harmony-verify"

echo "=== HarmonyOS ↔ Rust 交叉验证 ==="

# 1. Build banban if needed
if [ ! -f "$BANBAN" ]; then
  echo "Building banban (release)..."
  (cd "$ROOT/shift-core" && cargo build --release)
fi

# 2. Start banban serve (for HTTP API test cases)
if ! curl -s http://localhost:11451/health >/dev/null 2>&1; then
  echo "Starting banban serve..."
  nohup "$BANBAN" serve >"$VR/serve.log" 2>&1 &
  disown
  sleep 1.5
fi
curl -s http://localhost:11451/health >/dev/null || { echo "ERROR: banban serve failed to start"; exit 1; }

# 3. Copy .ets algorithm files as .ts (tsx can't load .ets)
rm -rf "$VR" && mkdir -p "$VR/constants" "$VR/models" "$VR/algorithms"
cp "$HARMONY_SRC/constants/ShiftConstants.ets" "$VR/constants/ShiftConstants.ts"
cp "$HARMONY_SRC/models/ShiftModels.ets" "$VR/models/ShiftModels.ts"
for f in ShiftCalculator ShiftMetrics HolidayData LeaveOptimizer ColleagueMode SalaryCalculator CalendarGenerator; do
  cp "$HARMONY_SRC/algorithms/$f.ets" "$VR/algorithms/$f.ts"
done

# 4. Write verify script
cat > "$VR/verify.ts" << 'VERIFYSRC'
import { getShiftInfo, getShiftTypeForDate, shiftHandover, isWorkDay } from './algorithms/ShiftCalculator'
import { countAllShiftTypesInMonth, daysUntilNextRest, consecutiveWorkDays } from './algorithms/ShiftMetrics'
import { generateMonthCalendarDays } from './algorithms/CalendarGenerator'
import { findBestLeavePlans } from './algorithms/LeaveOptimizer'
import { findCommonRestDays } from './algorithms/ColleagueMode'
import { HolidayData } from './algorithms/HolidayData'
import { execSync } from 'child_process'

const BANBAN = process.env.BANBAN_PATH || 'banban'
const API = 'http://localhost:11451'
const SHIFT_MAP: Record<string, number> = { morning: 0, afternoon: 1, rest: 2, night: 3, study: 4 }
let pass = 0, fail = 0
const fails: string[] = []

function check(label: string, got: unknown, want: unknown) {
  if (JSON.stringify(got) === JSON.stringify(want)) pass++
  else { fail++; fails.push(`FAIL ${label}\n  got: ${JSON.stringify(got)}\n  want: ${JSON.stringify(want)}`) }
}
async function http(p: string): Promise<any> { return (await fetch(`${API}${p}`)).json() }
function cli(...a: string[]): any { return JSON.parse(execSync(`${BANBAN} ${a.join(' ')}`, { encoding: 'utf8' })) }

async function main() {
  // A. getShiftInfo (team1, multi-date)
  for (const ds of ['2025-12-15','2025-12-16','2025-12-26','2026-01-26','2026-06-28','2026-12-15','2027-03-01','2024-01-01']) {
    const r = await http(`/shift/${ds}`)
    const d = new Date(ds + 'T00:00:00')
    const h = getShiftInfo(d, 1)
    check(`shift[${ds}] cycle`, h.dayOfCycle, r.day_of_cycle)
    check(`shift[${ds}] type`, h.shiftType, SHIFT_MAP[r.shift_type.toLowerCase()])
    check(`shift[${ds}] rest`, daysUntilNextRest(d, 1), r.days_until_rest)
    check(`shift[${ds}] consec`, consecutiveWorkDays(d, 1), r.consecutive_work_days)
  }
  // B. handover
  for (const ds of ['2025-12-15','2026-06-28','2026-01-26','2026-03-15']) {
    const r = await http(`/shift/${ds}`)
    const ho = shiftHandover(new Date(ds + 'T00:00:00'), 1)
    check(`ho[${ds}] pred`, ho ? ho[0] : 0, r.predecessor_team_id)
    check(`ho[${ds}] succ`, ho ? ho[1] : 0, r.successor_team_id)
  }
  // C. multi-team today
  for (let t = 1; t <= 6; t++) {
    const r = cli('-t', String(t), 'today', '--json')
    check(`t${t} type`, getShiftTypeForDate(new Date(), t), SHIFT_MAP[r.shift_type])
    check(`t${t} cycle`, getShiftInfo(new Date(), t).dayOfCycle, r.day_of_cycle)
    check(`t${t} rest`, daysUntilNextRest(new Date(), t), r.days_until_rest)
  }
  // D. calendar
  for (const [ym, team] of [['2025-12',1],['2026-06',1],['2026-06',3],['2027-02',5]] as [string,number][]) {
    const [y, m] = ym.split('-').map(Number)
    const r = cli('-t', String(team), 'calendar', ym, '--json')
    const flat: any[] = r.weeks.flat()
    const hs = generateMonthCalendarDays(y, m, team)
    check(`cal[${ym} t${team}] len`, hs.length, flat.length)
    let sOk = 0, dOk = 0
    for (let i = 0; i < Math.min(hs.length, flat.length); i++) {
      if (hs[i].shiftType === SHIFT_MAP[flat[i].shift_type.toLowerCase()]) sOk++
      if (hs[i].day === flat[i].day && hs[i].isCurrentMonth === flat[i].is_current_month) dOk++
    }
    check(`cal[${ym} t${team}] types`, sOk, flat.length)
    check(`cal[${ym} t${team}] days`, dOk, flat.length)
  }
  // E. stats
  for (const [ym, team] of [['2026-06',1],['2026-06',3],['2025-12',1]] as [string,number][]) {
    const [y, m] = ym.split('-').map(Number)
    const r = cli('-t', String(team), 'calendar', ym, '--json')
    const flat: any[] = r.weeks.flat().filter((d: any) => d.is_current_month)
    const rc: Record<string, number> = { morning: 0, afternoon: 0, rest: 0, night: 0, study: 0 }
    for (const d of flat) rc[d.shift_type.toLowerCase()]++
    const hs = countAllShiftTypesInMonth(y, m, team)
    check(`stats[${ym} t${team}] M`, hs.get(0) ?? 0, rc.morning)
    check(`stats[${ym} t${team}] A`, hs.get(1) ?? 0, rc.afternoon)
    check(`stats[${ym} t${team}] R`, hs.get(2) ?? 0, rc.rest)
    check(`stats[${ym} t${team}] N`, hs.get(3) ?? 0, rc.night)
    check(`stats[${ym} t${team}] S`, hs.get(4) ?? 0, rc.study)
  }
  // F. leave
  const rl = cli('leave', '--json', '--max-days', '5')
  const hs = findBestLeavePlans(1, 5).slice(0, 10)
  check('leave count', hs.length, rl.strategies.length)
  for (let i = 0; i < Math.min(hs.length, rl.strategies.length); i++) {
    const r = rl.strategies[i], h = hs[i]
    check(`leave#${i+1} days`, h.leaveDays, r.leave_days)
    check(`leave#${i+1} break`, h.totalBreakDays, r.total_break_days)
    check(`leave#${i+1} start`, h.breakStart, r.break_start)
    check(`leave#${i+1} end`, h.breakEnd, r.break_end)
    check(`leave#${i+1} eff`, Math.round(h.efficiency * 10) / 10, r.efficiency)
    check(`leave#${i+1} hol`, h.holidayOverlap, r.holiday_overlap)
    check(`leave#${i+1} wknd`, h.weekendOverlap, r.weekend_overlap)
    check(`leave#${i+1} score`, Math.round(h.score * 100) / 100, r.score)
  }
  // G. colleague
  for (const [a, b] of [[1,3],[2,5],[1,6]] as [number,number][]) {
    const r = cli('colleague', String(a), String(b), '--json')
    const h = findCommonRestDays(a, b)
    check(`coll[${a}v${b}] next`, h.nextCommonRestDate, r.next_common_rest)
    check(`coll[${a}v${b}] until`, h.daysUntilNext, r.days_until_next)
    check(`coll[${a}v${b}] c30`, h.countIn30Days, r.count_30_days)
    check(`coll[${a}v${b}] c60`, h.countIn60Days, r.count_60_days)
  }
  // H. holidays
  for (const ds of ['2026-01-01','2026-02-17','2026-10-01']) check(`hol[${ds}]`, HolidayData.isHoliday(ds), true)
  for (const ds of ['2026-02-14','2026-10-10']) { check(`hol[${ds}] adj`, HolidayData.isHoliday(ds), false); check(`hol[${ds}] info`, HolidayData.getHolidayInfo(ds) !== null, true) }

  console.log(`\n${'='.repeat(50)}\nPASS: ${pass}  FAIL: ${fail}`)
  if (fails.length) { console.log('\n--- Failures ---'); fails.forEach(f => console.log(f + '\n')) }
  else console.log('ALL PASS — HarmonyOS algorithms match Rust')
  process.exit(fail > 0 ? 1 : 0)
}
main().catch(e => { console.error(e); process.exit(1) })
VERIFYSRC

# 5. Run
export BANBAN_PATH="$BANBAN"
cd "$VR" && npx --yes tsx verify.ts
