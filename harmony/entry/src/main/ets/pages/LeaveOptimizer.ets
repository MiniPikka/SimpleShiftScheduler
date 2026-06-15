import { ThemeColors } from '../theme/ThemeColors'
import { LeaveStrategy } from '../models/ShiftModels'
import { findBestLeavePlans } from '../algorithms/LeaveOptimizer'
import { loadDefaultTeam, loadShiftCycle, loadReferenceDate } from '../storage/SettingsStorage'
import router from '@ohos.router'

@Entry
@Component
struct LeaveOptimizerPage {
  @State strategies: LeaveStrategy[] = []
  @State maxLeaveDays: number = 5

  aboutToAppear(): void {
    this.loadPlans()
  }

  async loadPlans(): Promise<void> {
    const teamId = await loadDefaultTeam()
    const cycle = await loadShiftCycle()
    const refDate = await loadReferenceDate()
    this.strategies = findBestLeavePlans(teamId, this.maxLeaveDays, cycle, refDate)
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .padding(12)
          .onClick(() => router.back())
        Text('拼假神器')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, top: 16 })

      Text('基于你的倒班表和法定节假日，自动分析最佳请假方案')
        .fontSize(13)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .padding({ left: 20, right: 20, top: 8, bottom: 12 })

      Row({ space: 8 }) {
        Text('最多请假天数:')
          .fontSize(14)
          .fontColor(ThemeColors.TEXT_SECONDARY)
        ForEach([1, 2, 3, 4, 5], (n: number) => {
          Text(String(n) + '天')
            .fontSize(13)
            .fontColor(this.maxLeaveDays === n ? Color.Black : ThemeColors.TEXT_PRIMARY)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.maxLeaveDays === n ? ThemeColors.ACCENT_GOLD : ThemeColors.CARD_SURFACE)
            .onClick(() => {
              this.maxLeaveDays = n
              this.loadPlans()
            })
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.strategies, (s: LeaveStrategy, idx: number) => {
            Column({ space: 8 }) {
              if (idx === 0) {
                Row() {
                  Text('最佳方案')
                    .fontSize(12)
                    .fontColor(Color.Black)
                    .fontWeight(FontWeight.Bold)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .borderRadius(10)
                    .backgroundColor(ThemeColors.ACCENT_GOLD)
                }
              }

              Row({ space: 12 }) {
                Column({ space: 2 }) {
                  Text('请假 ' + s.leaveDays + ' 天')
                    .fontSize(15)
                    .fontColor(ThemeColors.TEXT_SECONDARY)
                  Text('连休 ' + s.totalBreakDays + ' 天')
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ThemeColors.TEXT_PRIMARY)
                }

                Column({ space: 2 }) {
                  Text(s.breakStart + ' — ' + s.breakEnd)
                    .fontSize(13)
                    .fontColor(ThemeColors.TEXT_SECONDARY)
                  Row({ space: 6 }) {
                    ForEach(s.overlappingHolidayNames, (name: string) => {
                      Text(name)
                        .fontSize(12)
                        .fontColor(ThemeColors.SHIFT_MORNING)
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .borderRadius(8)
                        .backgroundColor('#33FFB347')
                    })
                    if (s.weekendOverlap > 0) {
                      Text('含周末')
                        .fontSize(12)
                        .fontColor(ThemeColors.SHIFT_AFTERNOON)
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .borderRadius(8)
                        .backgroundColor('#334DA3FF')
                    }
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Text('效率: ' + s.efficiency + 'x')
                .fontSize(12)
                .fontColor(idx === 0 ? ThemeColors.ACCENT_GOLD : ThemeColors.TEXT_TERTIARY)
            }
            .width('100%')
            .padding(20)
            .borderRadius(24)
            .backgroundColor(ThemeColors.CARD_SURFACE)
            .border(idx === 0 ? { width: 1, color: ThemeColors.ACCENT_GOLD } : undefined)
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
