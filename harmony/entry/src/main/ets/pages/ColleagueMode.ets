import { ThemeColors } from '../theme/ThemeColors'
import { TEAM_NAMES, WEEKDAY_LABELS } from '../constants/ShiftConstants'
import { CommonRestResult } from '../models/ShiftModels'
import { findCommonRestDays } from '../algorithms/ColleagueMode'
import { loadShiftCycle, loadReferenceDate } from '../storage/SettingsStorage'
import { parseDate, formatDate } from '../algorithms/ShiftCalculator'
import router from '@ohos.router'

@Entry
@Component
struct ColleagueModePage {
  @State teamA: number = 1
  @State teamB: number = 3
  @State result: CommonRestResult | null = null
  @State selectedDays: number = 20

  aboutToAppear(): void {
    this.calcResult()
  }

  async calcResult(): Promise<void> {
    const cycle = await loadShiftCycle()
    const refDate = await loadReferenceDate()
    this.result = findCommonRestDays(this.teamA, this.teamB, cycle, refDate)
  }

  swapTeams(): void {
    const temp = this.teamA
    this.teamA = this.teamB
    this.teamB = temp
    this.calcResult()
  }

  formatDateDisplay(dateStr: string): string {
    const d = parseDate(dateStr)
    const m = d.getMonth() + 1
    const day = d.getDate()
    const wd = WEEKDAY_LABELS[d.getDay()]
    return `${m}月${String(day).padStart(2, '0')}日 星期${wd}`
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .padding(12)
          .onClick(() => router.back())
        Text('同事模式')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, top: 16 })

      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('我是')
            .fontSize(12)
            .fontColor(ThemeColors.TEXT_SECONDARY)
          this.teamSelector(this.teamA, (id: number) => {
            this.teamA = id
            this.calcResult()
          })
        }
        .layoutWeight(1)

        Text('⇄')
          .fontSize(24)
          .fontColor(ThemeColors.ACCENT_GOLD)
          .padding(8)
          .onClick(() => this.swapTeams())

        Column({ space: 4 }) {
          Text('他是')
            .fontSize(12)
            .fontColor(ThemeColors.TEXT_SECONDARY)
          this.teamSelector(this.teamB, (id: number) => {
            this.teamB = id
            this.calcResult()
          })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })

      if (this.result) {
        Scroll() {
          Column({ space: 12 }) {
            if (this.teamA === this.teamB) {
              Text('两个班组相同，每天都是共同休息日')
                .fontSize(14)
                .fontColor(ThemeColors.TEXT_SECONDARY)
                .padding(20)
                .width('100%')
                .textAlign(TextAlign.Center)
                .borderRadius(24)
                .backgroundColor(ThemeColors.CARD_SURFACE)
            } else {
              Column({ space: 8 }) {
                Text('下次同时休息')
                  .fontSize(14)
                  .fontColor(ThemeColors.TEXT_SECONDARY)
                Text(this.formatDateDisplay(this.result!.nextCommonRestDate))
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ThemeColors.SHIFT_REST)
                Text('距今 ' + this.result!.daysUntilNext + ' 天')
                  .fontSize(14)
                  .fontColor(ThemeColors.TEXT_TERTIARY)
                Text('我是' + this.result!.teamAName + '，他是' + this.result!.teamBName)
                  .fontSize(12)
                  .fontColor(ThemeColors.TEXT_TERTIARY)
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding(24)
              .borderRadius(24)
              .backgroundColor(ThemeColors.CARD_SURFACE)
              .alignItems(HorizontalAlign.Center)

              Row({ space: 12 }) {
                this.countCard('未来30天共同休息', this.result!.countIn30Days)
                this.countCard('未来60天共同休息', this.result!.countIn60Days)
              }
              .width('100%')

              Column({ space: 8 }) {
                Text('共同休息日')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ThemeColors.TEXT_PRIMARY)
                  .width('100%')

                ForEach(this.result!.commonRestDates.slice(0, this.selectedDays), (dateStr: string) => {
                  Row() {
                    Text(this.formatDateDisplay(dateStr))
                      .fontSize(14)
                      .fontColor(ThemeColors.TEXT_PRIMARY)
                    Blank()
                    if (this.result!.commonRestDates.indexOf(dateStr) === 0) {
                      Text('距今 ' + this.result!.daysUntilNext + ' 天')
                        .fontSize(12)
                        .fontColor(ThemeColors.TEXT_TERTIARY)
                    }
                  }
                  .width('100%')
                  .padding({ top: 8, bottom: 8 })
                  .border({ width: { bottom: 0.5 }, color: ThemeColors.DIVIDER })
                })

                if (this.result!.commonRestDates.length > this.selectedDays) {
                  Text('查看更多...')
                    .fontSize(14)
                    .fontColor(ThemeColors.ACCENT_GOLD)
                    .padding(8)
                    .onClick(() => { this.selectedDays += 20 })
                }
              }
              .width('100%')
              .padding(20)
              .borderRadius(24)
              .backgroundColor(ThemeColors.CARD_SURFACE)

              Text('分析范围：' + formatDate(new Date()) + ' — ' + new Date().getFullYear() + '/12/31')
                .fontSize(12)
                .fontColor(ThemeColors.TEXT_TERTIARY)
                .width('100%')
                .textAlign(TextAlign.Center)
            }
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.PRIMARY_BG)
  }

  @Builder
  teamSelector(current: number, onChange: (id: number) => void) {
    Select(TEAM_NAMES.map((name, idx) => ({ value: name, icon: '' } as SelectOption)))
      .selected(current - 1)
      .value(TEAM_NAMES[current - 1])
      .font({ size: 16 }).fontColor(ThemeColors.TEXT_PRIMARY)
      .selectedOptionFont({ size: 16, weight: FontWeight.Medium })
      .selectedOptionFontColor(ThemeColors.ACCENT_GOLD)
      .optionFont({ size: 16 })
      .optionFontColor(ThemeColors.TEXT_PRIMARY)
      .backgroundColor(ThemeColors.CARD_SURFACE)
      .borderRadius(20)
      .width('100%')
      .height(48)
      .onSelect((index: number) => {
        onChange(index + 1)
      })
  }

  @Builder
  countCard(label: string, count: number) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(13)
        .fontColor(ThemeColors.TEXT_SECONDARY)
      Text(count + ' 次')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.TEXT_PRIMARY)
    }
    .layoutWeight(1)
    .padding(16)
    .borderRadius(20)
    .backgroundColor(ThemeColors.CARD_SURFACE)
    .alignItems(HorizontalAlign.Center)
  }
}
