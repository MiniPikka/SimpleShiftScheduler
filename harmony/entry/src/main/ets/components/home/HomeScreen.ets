import { ThemeColors } from '../../theme/ThemeColors'
import { ShiftType, TEAM_NAMES, SHIFT_SHORT_LABELS, WEEKDAY_LABELS } from '../../constants/ShiftConstants'
import { HomeState } from '../../models/ShiftModels'
import { getShiftTypeForDate, shiftHandover } from '../../algorithms/ShiftCalculator'
import { consecutiveWorkDays, daysUntilNextRest, countWorkDaysInMonth } from '../../algorithms/ShiftMetrics'
import { loadDefaultTeam, loadAlarmSettings, loadShiftCycle, loadReferenceDate } from '../../storage/SettingsStorage'
import { HeroCard } from './HeroCard'
import { StatsRow } from './StatsRow'
import { ToolsRow } from './ToolsRow'
import { MessageBanner } from './MessageBanner'
import router from '@ohos.router'

@Component
export struct HomeScreen {
  @State homeState: HomeState = {
    shiftType: ShiftType.MORNING,
    dayOfCycle: 1,
    daysUntilRest: 0,
    consecutiveWorkDays: 0,
    monthlyWorkDays: 0,
    monthlyTotalDays: 30,
    alarmTimeStr: '',
    teamName: '一值',
    dateStr: '',
    greeting: '早上好',
    tomorrowShiftType: ShiftType.MORNING,
    predecessorTeamId: 6,
    predecessorShiftType: ShiftType.REST,
    successorTeamId: 2,
    successorShiftType: ShiftType.REST
  }
  @State selectedTeam: number = 1

  aboutToAppear(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    const teamId = await loadDefaultTeam()
    const cycle = await loadShiftCycle()
    const refDate = await loadReferenceDate()
    const alarmSettings = await loadAlarmSettings()

    this.selectedTeam = teamId
    const today = new Date()
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    const shiftType = getShiftTypeForDate(today, teamId, cycle, refDate)
    const tomorrowType = getShiftTypeForDate(tomorrow, teamId, cycle, refDate)
    const consecWork = consecutiveWorkDays(today, teamId, cycle, refDate)
    const daysRest = daysUntilNextRest(today, teamId, cycle, refDate)
    const workDays = countWorkDaysInMonth(today.getFullYear(), today.getMonth() + 1, teamId, cycle, refDate)
    const totalDays = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    const alarm = alarmSettings.alarms.get(shiftType)
    let alarmStr = ''
    if (alarm) {
      alarmStr = `${String(alarm.hour).padStart(2, '0')}:${String(alarm.minute).padStart(2, '0')}`
    }

    const hour = today.getHours()
    let greeting = '早上好'
    if (hour >= 12 && hour < 18) greeting = '下午好'
    else if (hour >= 18 && hour < 22) greeting = '晚上好'
    else if (hour >= 22 || hour < 5) greeting = '夜深了'

    const refD = new Date(refDate)
    const msPerDay = 86400000
    const offset = Math.floor((Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()) - Date.UTC(refD.getFullYear(), refD.getMonth(), refD.getDate())) / msPerDay)
    const phase = (teamId - 1) * Math.floor(cycle.length / 6)
    const dayOfCycle = ((offset + phase) % cycle.length + cycle.length) % cycle.length + 1

    // 交接班：基于班次类型（夜→早→中→夜）
    const handover = shiftHandover(today, teamId, cycle, refDate)
    const predId = handover ? handover[0] : 0
    const predShift = handover ? getShiftTypeForDate(today, predId, cycle, refDate) : ShiftType.REST
    const succId = handover ? handover[1] : 0
    const succShift = handover ? getShiftTypeForDate(today, succId, cycle, refDate) : ShiftType.REST

    const y = today.getFullYear()
    const m = today.getMonth() + 1
    const d = today.getDate()
    const wd = WEEKDAY_LABELS[today.getDay()]

    this.homeState = {
      shiftType: shiftType,
      dayOfCycle: dayOfCycle,
      daysUntilRest: daysRest,
      consecutiveWorkDays: consecWork,
      monthlyWorkDays: workDays,
      monthlyTotalDays: totalDays,
      alarmTimeStr: alarmStr,
      teamName: TEAM_NAMES[teamId - 1],
      dateStr: `${y}年${m}月${d}日 星期${wd}`,
      greeting: greeting,
      tomorrowShiftType: tomorrowType,
      predecessorTeamId: predId,
      predecessorShiftType: predShift,
      successorTeamId: succId,
      successorShiftType: succShift
    }
  }

  build() {
    Column() {
      Row() {
        Text(this.homeState.greeting + '，' + this.homeState.teamName)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })

      Text(this.homeState.dateStr)
        .fontSize(14)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .padding({ left: 20, top: 4 })

      Scroll() {
        Column({ space: 12 }) {
          HeroCard({
            shiftType: this.homeState.shiftType,
            teamName: this.homeState.teamName,
            alarmTimeStr: this.homeState.alarmTimeStr,
            dayOfCycle: this.homeState.dayOfCycle,
            totalDays: 42,
            daysUntilRest: this.homeState.daysUntilRest,
            tomorrowShiftType: this.homeState.tomorrowShiftType
          })

          StatsRow({
            monthlyWorkDays: this.homeState.monthlyWorkDays,
            monthlyTotalDays: this.homeState.monthlyTotalDays,
            consecutiveDays: this.homeState.consecutiveWorkDays
          })

          // 交接班信息卡（休/学日不显示）
          if (this.homeState.predecessorTeamId > 0 && this.homeState.successorTeamId > 0) {
            Row() {
              Text('🔄')
                .fontSize(16)
              Column() {
                Text() {
                  Span(`← 接${TEAM_NAMES[this.homeState.predecessorTeamId - 1]}的班`)
                    .fontColor(ThemeColors.TEXT_SECONDARY)
                  Span(` · 正在上${SHIFT_SHORT_LABELS[this.homeState.predecessorShiftType]}班`)
                    .fontColor(ThemeColors.TEXT_SECONDARY)
                }
                .fontSize(13)
                Text() {
                  Span(`${TEAM_NAMES[this.homeState.successorTeamId - 1]}接我的班 →`)
                    .fontColor(ThemeColors.TEXT_SECONDARY)
                  Span(` · 正在上${SHIFT_SHORT_LABELS[this.homeState.successorShiftType]}班`)
                    .fontColor(ThemeColors.TEXT_SECONDARY)
                }
                .fontSize(13)
              }
              .margin({ left: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .borderRadius(20)
            .backgroundColor(ThemeColors.CARD_SURFACE)
          }

          ToolsRow({
            onLeaveTap: () => { router.pushUrl({ url: 'pages/LeaveOptimizer' }) },
            onColleagueTap: () => { router.pushUrl({ url: 'pages/ColleagueMode' }) },
            onSalaryTap: () => { router.pushUrl({ url: 'pages/SalaryPredictor' }) }
          })

          MessageBanner({
            shiftType: this.homeState.shiftType,
            daysUntilRest: this.homeState.daysUntilRest,
            consecutiveDays: this.homeState.consecutiveWorkDays
          })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.PRIMARY_BG)
  }
}
