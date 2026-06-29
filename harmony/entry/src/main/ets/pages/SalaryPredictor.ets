import { ThemeColors } from '../theme/ThemeColors'
import { ShiftType, SHIFT_LABELS, SHIFT_COLORS, SHIFT_SHORT_LABELS, TEAM_NAMES } from '../constants/ShiftConstants'
import { SalaryConfig, SalaryBreakdown } from '../models/ShiftModels'
import { calculateSalaryBreakdown, defaultSalaryConfig, simulateExtraShifts } from '../algorithms/SalaryCalculator'
import { loadDefaultTeam, loadSalaryConfig, saveSalaryConfig, loadShiftCycle, loadReferenceDate } from '../storage/SettingsStorage'
import router from '@ohos.router'

@Entry
@Component
struct SalaryPredictorPage {
  @State config: SalaryConfig = defaultSalaryConfig()
  @State breakdown: SalaryBreakdown | null = null
  @State currentYear: number = 2026
  @State currentMonth: number = 1
  @State selectedTeam: number = 1
  @State extraDays: number = 2
  @State extraShiftType: ShiftType = ShiftType.NIGHT
  @State showSettings: boolean = false

  aboutToAppear(): void {
    const today = new Date()
    this.currentYear = today.getFullYear()
    this.currentMonth = today.getMonth() + 1
    this.loadData()
  }

  async loadData(): Promise<void> {
    this.config = await loadSalaryConfig()
    this.selectedTeam = await loadDefaultTeam()
    await this.calcBreakdown()
  }

  async calcBreakdown(): Promise<void> {
    const cycle = await loadShiftCycle()
    const refDate = await loadReferenceDate()
    this.breakdown = calculateSalaryBreakdown(this.currentYear, this.currentMonth, this.config, this.selectedTeam, cycle, refDate)
  }

  prevMonth(): void {
    if (this.currentMonth === 1) { this.currentYear--; this.currentMonth = 12 }
    else { this.currentMonth-- }
    this.calcBreakdown()
  }

  nextMonth(): void {
    if (this.currentMonth === 12) { this.currentYear++; this.currentMonth = 1 }
    else { this.currentMonth++ }
    this.calcBreakdown()
  }

  formatMoney(amount: number): string {
    return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
  }

  typeCount(type: ShiftType): number {
    return this.breakdown ? this.breakdown.counts.get(type) || 0 : 0
  }

  typePremium(type: ShiftType): number {
    return this.config.premiums.get(type) || 0
  }

  typeSubtotal(type: ShiftType): number {
    return this.typeCount(type) * this.typePremium(type)
  }

  extraAmount(): number {
    return simulateExtraShifts(
      this.breakdown ? this.breakdown.total : 0,
      this.extraDays, this.extraShiftType, this.config
    )
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .padding(12)
          .onClick(() => router.back())
        Text('倒班津贴')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, top: 16 })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 8 }) {
            Row() {
              Text('津贴设置')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeColors.TEXT_PRIMARY)
              Blank()
              Text(this.showSettings ? '收起' : '展开')
                .fontSize(13)
                .fontColor(ThemeColors.ACCENT_GOLD)
                .onClick(() => { this.showSettings = !this.showSettings })
            }
            .width('100%')

            if (this.showSettings) {
              Column({ space: 8 }) {
                this.premiumRow(ShiftType.MORNING)
                this.premiumRow(ShiftType.AFTERNOON)
                this.premiumRow(ShiftType.NIGHT)
                this.premiumRow(ShiftType.STUDY)
                Text('元/班')
                  .fontSize(12)
                  .fontColor(ThemeColors.TEXT_TERTIARY)
                  .width('100%')
                  .textAlign(TextAlign.End)
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding(20)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)

          Row() {
            Text('<')
              .fontSize(18)
              .fontColor(ThemeColors.TEXT_PRIMARY)
              .padding(8)
              .onClick(() => this.prevMonth())
            Text(this.currentMonth + '月 · ' + TEAM_NAMES[this.selectedTeam - 1])
              .fontSize(16)
              .fontColor(ThemeColors.TEXT_PRIMARY)
            Text('>')
              .fontSize(18)
              .fontColor(ThemeColors.TEXT_PRIMARY)
              .padding(8)
              .onClick(() => this.nextMonth())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Column({ space: 8 }) {
            Text('本月倒班津贴')
              .fontSize(14)
              .fontColor(ThemeColors.TEXT_SECONDARY)
            Text('¥' + this.formatMoney(this.breakdown ? this.breakdown.total : 0))
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.ACCENT_GOLD)
          }
          .width('100%')
          .padding(24)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)
          .alignItems(HorizontalAlign.Center)

          if (this.breakdown) {
            Column({ space: 8 }) {
              Text('班次统计')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeColors.TEXT_PRIMARY)

              ForEach([ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.NIGHT, ShiftType.REST, ShiftType.STUDY],
                (type: ShiftType) => {
                  Row() {
                    Circle({ width: 10, height: 10 })
                      .backgroundColor(SHIFT_COLORS[type])
                    Text(SHIFT_LABELS[type])
                      .fontSize(14)
                      .fontColor(ThemeColors.TEXT_PRIMARY)
                      .margin({ left: 8 })
                    Blank()
                    Text(this.typeCount(type) + '次')
                      .fontSize(14)
                      .fontColor(ThemeColors.TEXT_SECONDARY)
                    if (this.typePremium(type) > 0) {
                      Text(' · ¥' + this.formatMoney(this.typeSubtotal(type)))
                        .fontSize(14)
                        .fontColor(ThemeColors.TEXT_PRIMARY)
                    }
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                })
            }
            .width('100%')
            .padding(20)
            .borderRadius(24)
            .backgroundColor(ThemeColors.CARD_SURFACE)
          }

          Column({ space: 12 }) {
            Text('假设分析')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.TEXT_PRIMARY)

            Row({ space: 8 }) {
              Text('如果多上')
                .fontSize(14)
                .fontColor(ThemeColors.TEXT_SECONDARY)

              Text(String(this.extraDays) + '天')
                .fontSize(16)
                .fontColor(ThemeColors.ACCENT_GOLD)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(8)
                .backgroundColor('#33FACC15')
            }

            Row({ space: 4 }) {
              ForEach([ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.NIGHT, ShiftType.STUDY],
                (type: ShiftType) => {
                  Text(SHIFT_SHORT_LABELS[type])
                    .fontSize(13)
                    .fontColor(this.extraShiftType === type ? Color.Black : ThemeColors.TEXT_PRIMARY)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(12)
                    .backgroundColor(this.extraShiftType === type ? SHIFT_COLORS[type] : ThemeColors.CARD_SURFACE)
                    .onClick(() => {
                      this.extraShiftType = type
                    })
                })
            }

            Row({ space: 8 }) {
              ForEach([1, 2, 3, 5], (n: number) => {
                Text(String(n) + '天')
                  .fontSize(13)
                  .fontColor(this.extraDays === n ? Color.Black : ThemeColors.TEXT_PRIMARY)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(12)
                  .backgroundColor(this.extraDays === n ? ThemeColors.ACCENT_GOLD : ThemeColors.CARD_SURFACE)
                  .onClick(() => { this.extraDays = n })
              })
            }

            Text('津贴 +¥' + this.formatMoney(this.extraAmount()))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.SHIFT_REST)
          }
          .width('100%')
          .padding(20)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)
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

  @Builder
  premiumRow(type: ShiftType) {
    Row() {
      Text(SHIFT_LABELS[type])
        .fontSize(14)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .width(60)

      TextInput({ text: String(this.config.premiums.get(type) || 0) })
        .type(InputType.Number)
        .fontSize(14)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .backgroundColor(ThemeColors.SECONDARY_SURFACE)
        .borderRadius(8)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .layoutWeight(1)
        .onChange((value: string) => {
          const num = parseFloat(value) || 0
          const newPremiums = new Map<ShiftType, number>(this.config.premiums)
          newPremiums.set(type, num)
          this.config = { premiums: newPremiums }
          saveSalaryConfig(this.config)
          this.calcBreakdown()
        })

      Text('元')
        .fontSize(13)
        .fontColor(ThemeColors.TEXT_TERTIARY)
        .margin({ left: 8 })
    }
    .width('100%')
  }
}
