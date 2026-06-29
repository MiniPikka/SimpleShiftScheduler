import { ThemeColors } from '../theme/ThemeColors'
import { ShiftType, SHIFT_LABELS, SHIFT_SHORT_LABELS, SHIFT_COLORS, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE, TEAM_NAMES } from '../constants/ShiftConstants'
import { loadShiftCycle, saveShiftCycle, loadCycleLength, saveCycleLength, loadDefaultTeam, saveDefaultTeam, loadReferenceDate, saveReferenceDate } from '../storage/SettingsStorage'
import router from '@ohos.router'

@Entry
@Component
struct ShiftRulePage {
  @State cycleLength: number = 42
  @State sequence: ShiftType[] = []
  @State selectedTeam: number = 1
  @State startDate: string = DEFAULT_REFERENCE_DATE
  @State isDirty: boolean = false
  private teamIds: number[] = [1, 2, 3, 4, 5, 6]

  aboutToAppear(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    this.cycleLength = await loadCycleLength()
    this.sequence = await loadShiftCycle()
    this.selectedTeam = await loadDefaultTeam()
    this.startDate = await loadReferenceDate()
  }

  addShift(type: ShiftType): void {
    this.sequence = [...this.sequence, type]
    this.cycleLength = this.sequence.length
    this.isDirty = true
  }

  removeShift(index: number): void {
    this.sequence = this.sequence.filter((_, i) => i !== index)
    this.cycleLength = this.sequence.length
    this.isDirty = true
  }

  loadPreset(days: number): void {
    if (days === 42) {
      this.sequence = [...DEFAULT_SHIFT_CYCLE]
    } else {
      this.sequence = new Array<ShiftType>(days).fill(ShiftType.REST)
    }
    this.cycleLength = days
    this.isDirty = true
  }

  async save(): Promise<void> {
    await saveShiftCycle(this.sequence)
    await saveCycleLength(this.cycleLength)
    await saveDefaultTeam(this.selectedTeam)
    await saveReferenceDate(this.startDate)
    this.isDirty = false
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .padding(12)
          .onClick(() => {
            if (this.isDirty) {
              // show discard dialog - simplified: just go back
            }
            router.back()
          })
        Text('倒班规则设置')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, top: 16 })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 8 }) {
            Text('预设方案')
              .fontSize(14)
              .fontColor(ThemeColors.TEXT_SECONDARY)

            Row({ space: 8 }) {
              Text('42天默认')
                .fontSize(13)
                .fontColor(ThemeColors.TEXT_PRIMARY)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .borderRadius(16)
                .backgroundColor(ThemeColors.CARD_SURFACE)
                .onClick(() => this.loadPreset(42))
              Text('7天')
                .fontSize(13)
                .fontColor(ThemeColors.TEXT_PRIMARY)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .borderRadius(16)
                .backgroundColor(ThemeColors.CARD_SURFACE)
                .onClick(() => this.loadPreset(7))
              Text('14天')
                .fontSize(13)
                .fontColor(ThemeColors.TEXT_PRIMARY)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .borderRadius(16)
                .backgroundColor(ThemeColors.CARD_SURFACE)
                .onClick(() => this.loadPreset(14))
              Text('清空')
                .fontSize(13)
                .fontColor('#FF6B6B')
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .borderRadius(16)
                .backgroundColor(ThemeColors.CARD_SURFACE)
                .onClick(() => { this.sequence = []; this.cycleLength = 0; this.isDirty = true })
            }
          }
          .width('100%')
          .padding(20)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)

          Column({ space: 8 }) {
            Text('添加班次')
              .fontSize(14)
              .fontColor(ThemeColors.TEXT_SECONDARY)

            Row({ space: 6 }) {
              ForEach([ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.REST, ShiftType.NIGHT, ShiftType.STUDY],
                (type: ShiftType) => {
                  Text(SHIFT_SHORT_LABELS[type])
                    .fontSize(14)
                    .fontColor(Color.White)
                    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                    .borderRadius(20)
                    .backgroundColor(SHIFT_COLORS[type])
                    .onClick(() => this.addShift(type))
                })
            }
          }
          .width('100%')
          .padding(20)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)

          Column({ space: 8 }) {
            Row() {
              Text('周期序列')
                .fontSize(14)
                .fontColor(ThemeColors.TEXT_SECONDARY)
              Blank()
              Text(this.sequence.length + ' 天')
                .fontSize(14)
                .fontColor(ThemeColors.TEXT_PRIMARY)
            }
            .width('100%')

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.sequence, (type: ShiftType, idx: number) => {
                Row({ space: 4 }) {
                  Text(SHIFT_SHORT_LABELS[type])
                    .fontSize(12)
                    .fontColor(Color.White)
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(8)
                    .backgroundColor(SHIFT_COLORS[type])
                  Text('×')
                    .fontSize(11)
                    .fontColor(ThemeColors.TEXT_TERTIARY)
                    .onClick(() => this.removeShift(idx))
                }
                .margin({ right: 4, bottom: 4 })
              })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)

          Column({ space: 8 }) {
            Text('默认班组')
              .fontSize(14)
              .fontColor(ThemeColors.TEXT_SECONDARY)

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.teamIds, (teamId: number) => {
                Text(TEAM_NAMES[teamId - 1])
                  .fontSize(13)
                  .fontColor(this.selectedTeam === teamId ? Color.Black : ThemeColors.TEXT_PRIMARY)
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .margin({ right: 6, bottom: 6 })
                  .borderRadius(16)
                  .backgroundColor(this.selectedTeam === teamId ? ThemeColors.ACCENT_GOLD : ThemeColors.CARD_SURFACE)
                  .onClick(() => { this.selectedTeam = teamId; this.isDirty = true })
              })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)

          Button(this.isDirty ? '保存修改' : '已保存')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .backgroundColor(this.isDirty ? ThemeColors.ACCENT_GOLD : ThemeColors.DIVIDER)
            .borderRadius(24)
            .width('100%')
            .height(52)
            .enabled(this.isDirty)
            .onClick(() => this.save())
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
