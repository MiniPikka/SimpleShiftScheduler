export enum ShiftType {
  MORNING = 0,
  AFTERNOON = 1,
  REST = 2,
  NIGHT = 3,
  STUDY = 4
}

export const TOTAL_TEAMS = 6
export const DEFAULT_CYCLE_LENGTH = 42
export const DEFAULT_REFERENCE_DATE = '2025-12-15'

export const DEFAULT_SHIFT_CYCLE: ShiftType[] = [
  ShiftType.MORNING, ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.AFTERNOON,
  ShiftType.REST, ShiftType.NIGHT, ShiftType.NIGHT,
  ShiftType.REST, ShiftType.REST, ShiftType.MORNING, ShiftType.MORNING,
  ShiftType.AFTERNOON, ShiftType.AFTERNOON, ShiftType.REST,
  ShiftType.NIGHT, ShiftType.REST, ShiftType.REST, ShiftType.REST,
  ShiftType.MORNING, ShiftType.MORNING, ShiftType.AFTERNOON,
  ShiftType.REST, ShiftType.NIGHT, ShiftType.NIGHT, ShiftType.REST, ShiftType.REST, ShiftType.REST,
  ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.AFTERNOON, ShiftType.REST,
  ShiftType.NIGHT, ShiftType.NIGHT, ShiftType.REST, ShiftType.REST,
  ShiftType.STUDY, ShiftType.STUDY, ShiftType.STUDY, ShiftType.STUDY, ShiftType.STUDY,
  ShiftType.REST, ShiftType.REST
]

export const SHIFT_COLORS: string[] = [
  '#FFB347', // MORNING - orange
  '#4DA3FF', // AFTERNOON - blue
  '#35D07F', // REST - green
  '#7C5CFF', // NIGHT - purple
  '#F2D94E'  // STUDY - yellow
]

export const SHIFT_LABELS: string[] = ['早班', '中班', '休息', '夜班', '学习']
export const SHIFT_SHORT_LABELS: string[] = ['早', '中', '休', '夜', '学']

export const TEAM_NAMES: string[] = ['一值', '二值', '三值', '四值', '五值', '六值']

export const WEEKDAY_LABELS: string[] = ['日', '一', '二', '三', '四', '五', '六']

export const CARD_RADIUS = 24
export const CARD_PADDING = 16
export const CARD_SPACING = 12
