import { preferences } from '@kit.ArkData'
import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_CYCLE_LENGTH, DEFAULT_REFERENCE_DATE } from '../constants/ShiftConstants'
import { AlarmSettings, AlarmTime, SalaryConfig } from '../models/ShiftModels'
import { defaultSalaryConfig } from '../algorithms/SalaryCalculator'

const STORE_NAME = 'shiftmate_settings'
const KEY_CYCLE_LENGTH = 'cycle_length'
const KEY_SHIFT_CYCLE = 'shift_cycle'
const KEY_DEFAULT_TEAM = 'default_team'
const KEY_REFERENCE_DATE = 'reference_date'
const KEY_ALARM_PREFIX = 'alarm_'
const KEY_SALARIES = 'salaries'

let prefs: preferences.Preferences | null = null

export async function initStorage(context: Context): Promise<void> {
  prefs = await preferences.getPreferences(context, STORE_NAME)
}

export async function loadCycleLength(): Promise<number> {
  if (!prefs) return DEFAULT_CYCLE_LENGTH
  try {
    const val = await prefs.get(KEY_CYCLE_LENGTH, DEFAULT_CYCLE_LENGTH)
    return val as number
  } catch {
    return DEFAULT_CYCLE_LENGTH
  }
}

export async function saveCycleLength(len: number): Promise<void> {
  if (!prefs) return
  await prefs.put(KEY_CYCLE_LENGTH, len)
  await prefs.flush()
}

export async function loadShiftCycle(): Promise<ShiftType[]> {
  if (!prefs) return DEFAULT_SHIFT_CYCLE
  try {
    const val = await prefs.get(KEY_SHIFT_CYCLE, '') as string
    if (!val || val.length === 0) return DEFAULT_SHIFT_CYCLE
    return val.split(',').map(s => parseInt(s) as ShiftType)
  } catch {
    return DEFAULT_SHIFT_CYCLE
  }
}

export async function saveShiftCycle(cycle: ShiftType[]): Promise<void> {
  if (!prefs) return
  await prefs.put(KEY_SHIFT_CYCLE, cycle.join(','))
  await prefs.flush()
}

export async function loadDefaultTeam(): Promise<number> {
  if (!prefs) return 1
  try {
    const val = await prefs.get(KEY_DEFAULT_TEAM, 1)
    return val as number
  } catch {
    return 1
  }
}

export async function saveDefaultTeam(teamId: number): Promise<void> {
  if (!prefs) return
  await prefs.put(KEY_DEFAULT_TEAM, teamId)
  await prefs.flush()
}

export async function loadReferenceDate(): Promise<string> {
  if (!prefs) return DEFAULT_REFERENCE_DATE
  try {
    const val = await prefs.get(KEY_REFERENCE_DATE, DEFAULT_REFERENCE_DATE)
    return val as string
  } catch {
    return DEFAULT_REFERENCE_DATE
  }
}

export async function saveReferenceDate(dateStr: string): Promise<void> {
  if (!prefs) return
  await prefs.put(KEY_REFERENCE_DATE, dateStr)
  await prefs.flush()
}

export async function loadAlarmSettings(): Promise<AlarmSettings> {
  const alarms = new Map<ShiftType, AlarmTime | null>()
  const types = [ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.REST, ShiftType.NIGHT, ShiftType.STUDY]
  for (const t of types) {
    const key = KEY_ALARM_PREFIX + t
    if (!prefs) { alarms.set(t, null); continue }
    try {
      const val = await prefs.get(key, '') as string
      if (val && val.length > 0) {
        const parts = val.split(':')
        alarms.set(t, { hour: parseInt(parts[0]), minute: parseInt(parts[1]) })
      } else {
        alarms.set(t, null)
      }
    } catch {
      alarms.set(t, null)
    }
  }
  return { alarms }
}

export async function saveAlarmTime(type: ShiftType, alarm: AlarmTime | null): Promise<void> {
  if (!prefs) return
  const key = KEY_ALARM_PREFIX + type
  if (alarm) {
    await prefs.put(key, `${String(alarm.hour).padStart(2, '0')}:${String(alarm.minute).padStart(2, '0')}`)
  } else {
    await prefs.delete(key)
  }
  await prefs.flush()
}

export async function loadSalaryConfig(): Promise<SalaryConfig> {
  if (!prefs) return defaultSalaryConfig()
  try {
    const val = await prefs.get(KEY_SALARIES, '') as string
    if (!val || val.length === 0) return defaultSalaryConfig()
    const premiums = new Map<ShiftType, number>()
    const parts = val.split(',')
    for (const p of parts) {
      const [key, value] = p.split('=')
      premiums.set(parseInt(key) as ShiftType, parseFloat(value))
    }
    return { premiums }
  } catch {
    return defaultSalaryConfig()
  }
}

export async function saveSalaryConfig(config: SalaryConfig): Promise<void> {
  if (!prefs) return
  const parts: string[] = []
  config.premiums.forEach((value, key) => {
    parts.push(`${key}=${value}`)
  })
  await prefs.put(KEY_SALARIES, parts.join(','))
  await prefs.flush()
}
