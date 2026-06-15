export interface HolidayInfo {
  date: string
  name: string
  isHoliday: boolean
}

const HOLIDAYS_2026: HolidayInfo[] = [
  { date: '2026-01-01', name: '元旦', isHoliday: true },
  { date: '2026-01-02', name: '元旦', isHoliday: true },
  { date: '2026-01-03', name: '元旦', isHoliday: true },
  { date: '2026-01-04', name: '元旦调休', isHoliday: false },
  { date: '2026-02-17', name: '春节', isHoliday: true },
  { date: '2026-02-18', name: '春节', isHoliday: true },
  { date: '2026-02-19', name: '春节', isHoliday: true },
  { date: '2026-02-20', name: '春节', isHoliday: true },
  { date: '2026-02-21', name: '春节', isHoliday: true },
  { date: '2026-02-22', name: '春节', isHoliday: true },
  { date: '2026-02-23', name: '春节', isHoliday: true },
  { date: '2026-02-14', name: '春节调休', isHoliday: false },
  { date: '2026-02-28', name: '春节调休', isHoliday: false },
  { date: '2026-04-05', name: '清明节', isHoliday: true },
  { date: '2026-04-06', name: '清明节', isHoliday: true },
  { date: '2026-04-07', name: '清明节', isHoliday: true },
  { date: '2026-05-01', name: '劳动节', isHoliday: true },
  { date: '2026-05-02', name: '劳动节', isHoliday: true },
  { date: '2026-05-03', name: '劳动节', isHoliday: true },
  { date: '2026-05-04', name: '劳动节', isHoliday: true },
  { date: '2026-05-05', name: '劳动节', isHoliday: true },
  { date: '2026-04-26', name: '劳动节调休', isHoliday: false },
  { date: '2026-06-19', name: '端午节', isHoliday: true },
  { date: '2026-06-20', name: '端午节', isHoliday: true },
  { date: '2026-06-21', name: '端午节', isHoliday: true },
  { date: '2026-10-01', name: '国庆节', isHoliday: true },
  { date: '2026-10-02', name: '国庆节', isHoliday: true },
  { date: '2026-10-03', name: '国庆节', isHoliday: true },
  { date: '2026-10-04', name: '国庆节', isHoliday: true },
  { date: '2026-10-05', name: '国庆节', isHoliday: true },
  { date: '2026-10-06', name: '国庆节', isHoliday: true },
  { date: '2026-10-07', name: '国庆节', isHoliday: true },
  { date: '2026-09-27', name: '国庆节调休', isHoliday: false },
  { date: '2026-10-10', name: '国庆节调休', isHoliday: false },
  { date: '2026-10-08', name: '中秋节', isHoliday: true },
  { date: '2026-10-09', name: '中秋节', isHoliday: true }
]

const HOLIDAYS_2027: HolidayInfo[] = [
  { date: '2027-01-01', name: '元旦', isHoliday: true },
  { date: '2027-01-02', name: '元旦', isHoliday: true },
  { date: '2027-01-03', name: '元旦', isHoliday: true },
  { date: '2027-02-06', name: '春节', isHoliday: true },
  { date: '2027-02-07', name: '春节', isHoliday: true },
  { date: '2027-02-08', name: '春节', isHoliday: true },
  { date: '2027-02-09', name: '春节', isHoliday: true },
  { date: '2027-02-10', name: '春节', isHoliday: true },
  { date: '2027-02-11', name: '春节', isHoliday: true },
  { date: '2027-02-12', name: '春节', isHoliday: true },
  { date: '2027-04-05', name: '清明节', isHoliday: true },
  { date: '2027-04-06', name: '清明节', isHoliday: true },
  { date: '2027-05-01', name: '劳动节', isHoliday: true },
  { date: '2027-05-02', name: '劳动节', isHoliday: true },
  { date: '2027-05-03', name: '劳动节', isHoliday: true },
  { date: '2027-06-09', name: '端午节', isHoliday: true },
  { date: '2027-06-10', name: '端午节', isHoliday: true },
  { date: '2027-10-01', name: '国庆节', isHoliday: true },
  { date: '2027-10-02', name: '国庆节', isHoliday: true },
  { date: '2027-10-03', name: '国庆节', isHoliday: true },
  { date: '2027-10-04', name: '国庆节', isHoliday: true },
  { date: '2027-10-05', name: '国庆节', isHoliday: true },
  { date: '2027-10-06', name: '国庆节', isHoliday: true },
  { date: '2027-10-07', name: '国庆节', isHoliday: true }
]

const ALL_HOLIDAYS: HolidayInfo[] = [...HOLIDAYS_2026, ...HOLIDAYS_2027]

export class HolidayData {
  static getHolidayInfo(dateStr: string): HolidayInfo | null {
    for (const h of ALL_HOLIDAYS) {
      if (h.date === dateStr) return h
    }
    return null
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
