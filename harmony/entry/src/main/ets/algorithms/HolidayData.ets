export interface HolidayInfo {
  date: string
  name: string
  isHoliday: boolean
}

const holidayMap: Map<string, HolidayInfo> = new Map<string, HolidayInfo>()

function add(date: string, name: string, isHoliday: boolean): void {
  holidayMap.set(date, { date, name, isHoliday })
}

function addRange(start: string, days: number, name: string, isHoliday: boolean): void {
  const d = new Date(start + 'T00:00:00')
  for (let i = 0; i < days; i++) {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    add(`${y}-${m}-${day}`, name, isHoliday)
    d.setDate(d.getDate() + 1)
  }
}

// ═══════════════════════════════════════════
// 2026 Official Holidays (国办发明电〔2025〕)
// ═══════════════════════════════════════════
add('2026-01-01', '元旦', true)
addRange('2026-02-15', 7, '春节', true)
add('2026-02-14', '春节调休', false)
add('2026-02-28', '春节调休', false)
add('2026-04-05', '清明节', true)
add('2026-04-06', '清明节', true)
addRange('2026-05-01', 5, '劳动节', true)
add('2026-05-09', '劳动节调休', false)
addRange('2026-06-19', 3, '端午节', true)
addRange('2026-09-25', 3, '中秋节', true)
addRange('2026-10-01', 7, '国庆节', true)
add('2026-09-27', '国庆节调休', false)
add('2026-10-10', '国庆节调休', false)

// ═══════════════════════════════════════════
// 2027 Estimated (based on lunar calendar, pending official confirmation)
// ═══════════════════════════════════════════
addRange('2027-01-01', 3, '元旦[待确认]', true)
addRange('2027-02-05', 7, '春节[待确认]', true)
add('2027-01-31', '春节调休[待确认]', false)
add('2027-02-13', '春节调休[待确认]', false)
add('2027-04-05', '清明节[待确认]', true)
addRange('2027-05-01', 5, '劳动节[待确认]', true)
add('2027-05-08', '劳动节调休[待确认]', false)

export class HolidayData {
  static getHolidayInfo(dateStr: string): HolidayInfo | null {
    return holidayMap.get(dateStr) ?? null
  }

  static isHoliday(dateStr: string): boolean {
    const info = this.getHolidayInfo(dateStr)
    return info !== null && info.isHoliday
  }

  static getHolidayName(dateStr: string): string {
    const info = this.getHolidayInfo(dateStr)
    return info !== null ? info.name : ''
  }
}
