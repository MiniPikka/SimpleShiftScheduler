import { ThemeColors } from '../../theme/ThemeColors'
import { ShiftType, TEAM_NAMES, SHIFT_SHORT_LABELS, SHIFT_COLORS, WEEKDAY_LABELS } from '../../constants/ShiftConstants'
import { CalendarDayInfo } from '../../models/ShiftModels'
import { generateMonthCalendarDays } from '../../algorithms/CalendarGenerator'
import { getMonthlyStats } from '../../algorithms/ShiftMetrics'
import { loadDefaultTeam, loadShiftCycle, loadReferenceDate } from '../../storage/SettingsStorage'

@Component
export struct CalendarScreen {
  @State currentYear: number = 2026
  @State currentMonth: number = 1
  @State selectedTeam: number = 1
  @State calendarDays: CalendarDayInfo[] = []
  @State monthlyCounts: Map<ShiftType, number> = new Map<ShiftType, number>()
  @State showStats: boolean = false

  aboutToAppear(): void {
    const today = new Date()
    this.currentYear = today.getFullYear()
    this.currentMonth = today.getMonth() + 1
    this.loadCalendar()
  }

  async loadCalendar(): Promise<void> {
    const teamId = await loadDefaultTeam()
    const cycle = await loadShiftCycle()
    const refDate = await loadReferenceDate()
    this.selectedTeam = teamId

    this.calendarDays = generateMonthCalendarDays(this.currentYear, this.currentMonth, teamId, cycle, refDate)
    const stats = getMonthlyStats(this.currentYear, this.currentMonth, teamId, cycle, refDate)
    this.monthlyCounts = stats.counts
  }

  prevMonth(): void {
    if (this.currentMonth === 1) {
      this.currentYear--
      this.currentMonth = 12
    } else {
      this.currentMonth--
    }
    this.loadCalendar()
  }

  nextMonth(): void {
    if (this.currentMonth === 12) {
      this.currentYear++
      this.currentMonth = 1
    } else {
      this.currentMonth++
    }
    this.loadCalendar()
  }

  goToday(): void {
    const today = new Date()
    this.currentYear = today.getFullYear()
    this.currentMonth = today.getMonth() + 1
    this.loadCalendar()
  }

  build() {
    Column() {
      Row() {
        Text('倒班日历')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      Row() {
        Text(TEAM_NAMES[this.selectedTeam - 1])
          .fontSize(14)
          .fontColor(ThemeColors.ACCENT_GOLD)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .border({ width: 1, color: ThemeColors.ACCENT_GOLD })
      }
      .padding({ left: 20, bottom: 8 })

      Row() {
        Text('<')
          .fontSize(20)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .padding(12)
          .onClick(() => this.prevMonth())

        Text(this.currentYear + '年' + this.currentMonth + '月')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('今天')
          .fontSize(14)
          .fontColor(ThemeColors.ACCENT_GOLD)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick(() => this.goToday())

        Text('>')
          .fontSize(20)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .padding(12)
          .onClick(() => this.nextMonth())
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Row() {
        ForEach(WEEKDAY_LABELS, (label: string) => {
          Text(label)
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.calendarDays, (day: CalendarDayInfo) => {
          Column({ space: 2 }) {
            Text(String(day.day))
              .fontSize(14)
              .fontColor(day.isCurrentMonth ? ThemeColors.TEXT_PRIMARY : ThemeColors.TEXT_TERTIARY)
              .fontWeight(day.isToday ? FontWeight.Bold : FontWeight.Normal)

            Text(SHIFT_SHORT_LABELS[day.shiftType])
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(SHIFT_COLORS[day.shiftType])
          }
          .width('14.28%')
          .height(52)
          .justifyContent(FlexAlign.Center)
          .borderRadius(day.isToday ? 8 : 0)
          .border(day.isToday ? { width: 1.5, color: ThemeColors.ACCENT_GOLD } : undefined)
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })

      if (this.showStats) {
        Column({ space: 8 }) {
          Text('本月统计')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeColors.TEXT_PRIMARY)
            .padding({ bottom: 4 })

          Row({ space: 0 }) {
            this.statItem('早', this.monthlyCounts.get(ShiftType.MORNING) || 0, ThemeColors.SHIFT_MORNING)
            this.statItem('中', this.monthlyCounts.get(ShiftType.AFTERNOON) || 0, ThemeColors.SHIFT_AFTERNOON)
            this.statItem('休', this.monthlyCounts.get(ShiftType.REST) || 0, ThemeColors.SHIFT_REST)
            this.statItem('夜', this.monthlyCounts.get(ShiftType.NIGHT) || 0, ThemeColors.SHIFT_NIGHT)
            this.statItem('学', this.monthlyCounts.get(ShiftType.STUDY) || 0, ThemeColors.SHIFT_STUDY)
          }
          .width('100%')
        }
        .width('100%')
        .padding(20)
        .margin({ top: 12, left: 16, right: 16 })
        .borderRadius(24)
        .backgroundColor(ThemeColors.CARD_SURFACE)
      }

      Row() {
        Text(this.showStats ? '收起统计' : '展开统计')
          .fontSize(14)
          .fontColor(ThemeColors.ACCENT_GOLD)
          .padding(12)
          .onClick(() => { this.showStats = !this.showStats })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.PRIMARY_BG)
  }

  @Builder
  statItem(label: string, count: number, color: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(13)
        .fontColor(color)
      Text(String(count))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.TEXT_PRIMARY)
      Text('天')
        .fontSize(11)
        .fontColor(ThemeColors.TEXT_TERTIARY)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}
