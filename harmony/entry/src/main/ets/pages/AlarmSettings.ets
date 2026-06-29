import { ThemeColors } from '../theme/ThemeColors'
import { ShiftType, SHIFT_LABELS, SHIFT_COLORS } from '../constants/ShiftConstants'
import { AlarmSettings, AlarmTime } from '../models/ShiftModels'
import { loadAlarmSettings, saveAlarmTime } from '../storage/SettingsStorage'
import router from '@ohos.router'

@Entry
@Component
struct AlarmSettingsPage {
  @State settings: AlarmSettings = { alarms: new Map<ShiftType, AlarmTime | null>() }
  @State showPicker: boolean = false
  @State editingType: ShiftType = ShiftType.MORNING
  @State pickerHour: number = 8
  @State pickerMinute: number = 0

  aboutToAppear(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    this.settings = await loadAlarmSettings()
  }

  getAlarmStr(type: ShiftType): string {
    const alarm = this.settings.alarms.get(type)
    if (alarm) {
      return `${String(alarm.hour).padStart(2, '0')}:${String(alarm.minute).padStart(2, '0')}`
    }
    return '未设置'
  }

  openPicker(type: ShiftType): void {
    this.editingType = type
    const alarm = this.settings.alarms.get(type)
    if (alarm) {
      this.pickerHour = alarm.hour
      this.pickerMinute = alarm.minute
    } else {
      this.pickerHour = type === ShiftType.MORNING ? 6 : type === ShiftType.AFTERNOON ? 14 : type === ShiftType.NIGHT ? 22 : 8
      this.pickerMinute = 0
    }
    this.showPicker = true
  }

  async removeAlarm(type: ShiftType): Promise<void> {
    await saveAlarmTime(type, null)
    const newAlarms = new Map<ShiftType, AlarmTime | null>(this.settings.alarms)
    newAlarms.set(type, null)
    this.settings = { alarms: newAlarms }
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor(ThemeColors.TEXT_PRIMARY)
          .padding(12)
          .onClick(() => router.back())
        Text('提醒设置')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, top: 16 })

      Text('为每个班次类型设置独立的提醒时间')
        .fontSize(13)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .padding({ left: 20, right: 20, top: 8, bottom: 16 })

      Column({ space: 4 }) {
        ForEach([ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.REST, ShiftType.NIGHT, ShiftType.STUDY],
          (type: ShiftType) => {
            Row() {
              Circle({ width: 12, height: 12 })
                .backgroundColor(SHIFT_COLORS[type])
              Text(SHIFT_LABELS[type])
                .fontSize(16)
                .fontColor(ThemeColors.TEXT_PRIMARY)
                .margin({ left: 12 })
              Blank()
              Text(this.getAlarmStr(type))
                .fontSize(14)
                .fontColor(this.settings.alarms.get(type) ? ThemeColors.TEXT_PRIMARY : ThemeColors.TEXT_TERTIARY)

              if (this.settings.alarms.get(type)) {
                Text('关闭')
                  .fontSize(13)
                  .fontColor('#FF6B6B')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .margin({ left: 8 })
                  .borderRadius(12)
                  .backgroundColor('#33FF6B6B')
                  .onClick(() => this.removeAlarm(type))
              }
            }
            .width('100%')
            .padding(20)
            .borderRadius(20)
            .backgroundColor(ThemeColors.CARD_SURFACE)
            .onClick(() => this.openPicker(type))
          })
      }
      .padding({ left: 16, right: 16 })

      if (this.showPicker) {
        Column() {
          Column({ space: 12 }) {
            Text('设置 ' + SHIFT_LABELS[this.editingType] + ' 提醒时间')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.TEXT_PRIMARY)

            TimePicker({
              selected: new Date(2026, 0, 1, this.pickerHour, this.pickerMinute)
            })
              .onChange((value: TimePickerResult) => {
                this.pickerHour = value.hour
                this.pickerMinute = value.minute
              })

            Row({ space: 12 }) {
              Button('取消')
                .fontSize(14)
                .fontColor(ThemeColors.TEXT_PRIMARY)
                .backgroundColor(ThemeColors.DIVIDER)
                .borderRadius(20)
                .layoutWeight(1)
                .onClick(() => { this.showPicker = false })

              Button('确认')
                .fontSize(14)
                .fontColor(Color.Black)
                .backgroundColor(ThemeColors.ACCENT_GOLD)
                .borderRadius(20)
                .layoutWeight(1)
                .onClick(async () => {
                  const alarm: AlarmTime = { hour: this.pickerHour, minute: this.pickerMinute }
                  await saveAlarmTime(this.editingType, alarm)
                  const newAlarms = new Map<ShiftType, AlarmTime | null>(this.settings.alarms)
                  newAlarms.set(this.editingType, alarm)
                  this.settings = { alarms: newAlarms }
                  this.showPicker = false
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(24)
          .borderRadius(28)
          .backgroundColor(ThemeColors.CARD_SURFACE)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000')
        .justifyContent(FlexAlign.Center)
        .padding(32)
        .onClick(() => { this.showPicker = false })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.PRIMARY_BG)
  }
}
