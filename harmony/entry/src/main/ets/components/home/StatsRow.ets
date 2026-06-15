import { ThemeColors } from '../../theme/ThemeColors'

function getWorkloadLabel(workDays: number, totalDays: number): string {
  const ratio = workDays / totalDays
  if (ratio < 0.4) return '轻松'
  if (ratio < 0.55) return '适中'
  if (ratio < 0.7) return '较重'
  return '高强度'
}

function getStatusLabel(consecDays: number): string {
  if (consecDays <= 2) return '状态良好'
  if (consecDays <= 4) return '注意休息'
  if (consecDays <= 6) return '注意调节'
  return '务必休息'
}

function getStatusColor(consecDays: number): string {
  if (consecDays <= 2) return ThemeColors.SHIFT_REST
  if (consecDays <= 4) return ThemeColors.SHIFT_STUDY
  if (consecDays <= 6) return ThemeColors.SHIFT_MORNING
  return ThemeColors.SHIFT_NIGHT
}

@Component
export struct StatsRow {
  @Prop monthlyWorkDays: number = 0
  @Prop monthlyTotalDays: number = 30
  @Prop consecutiveDays: number = 0

  build() {
    Row({ space: 12 }) {
      Column({ space: 6 }) {
        Text('本月上班')
          .fontSize(13)
          .fontColor(ThemeColors.TEXT_SECONDARY)

        Row({ space: 4 }) {
          Text(String(this.monthlyWorkDays))
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.TEXT_PRIMARY)
          Text('/ ' + this.monthlyTotalDays + ' 天')
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_TERTIARY)
            .margin({ top: 10 })
        }

        Text(getWorkloadLabel(this.monthlyWorkDays, this.monthlyTotalDays))
          .fontSize(12)
          .fontColor(ThemeColors.SHIFT_STUDY)
      }
      .layoutWeight(1)
      .padding(16)
      .borderRadius(20)
      .backgroundColor(ThemeColors.CARD_SURFACE)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        Text('连续上班')
          .fontSize(13)
          .fontColor(ThemeColors.TEXT_SECONDARY)

        Row({ space: 4 }) {
          Text(String(this.consecutiveDays))
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.TEXT_PRIMARY)
          Text('天')
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_TERTIARY)
            .margin({ top: 10 })
        }

        Text(getStatusLabel(this.consecutiveDays))
          .fontSize(12)
          .fontColor(getStatusColor(this.consecutiveDays))
      }
      .layoutWeight(1)
      .padding(16)
      .borderRadius(20)
      .backgroundColor(ThemeColors.CARD_SURFACE)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }
}
