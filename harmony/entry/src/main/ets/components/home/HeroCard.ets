import { ThemeColors } from '../../theme/ThemeColors'
import { ShiftType, SHIFT_SHORT_LABELS, SHIFT_COLORS, SHIFT_LABELS } from '../../constants/ShiftConstants'

@Component
export struct HeroCard {
  @Prop shiftType: ShiftType = ShiftType.MORNING
  @Prop teamName: string = ''
  @Prop alarmTimeStr: string = ''
  @Prop dayOfCycle: number = 1
  @Prop totalDays: number = 42
  @Prop daysUntilRest: number = 0
  @Prop tomorrowShiftType: ShiftType = ShiftType.MORNING

  private progress: number = 0

  aboutToAppear(): void {
    this.progress = this.dayOfCycle / this.totalDays
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 16 }) {
        Column() {
          Text(SHIFT_SHORT_LABELS[this.shiftType])
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
        }
        .width(64)
        .height(64)
        .borderRadius(32)
        .backgroundColor(SHIFT_COLORS[this.shiftType])
        .justifyContent(FlexAlign.Center)

        Column({ space: 6 }) {
          Text(SHIFT_LABELS[this.shiftType])
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeColors.TEXT_PRIMARY)

          Row({ space: 8 }) {
            if (this.alarmTimeStr) {
              Text('提醒 ' + this.alarmTimeStr)
                .fontSize(13)
                .fontColor(ThemeColors.TEXT_SECONDARY)
            }
          }

          Row({ space: 6 }) {
            if (this.daysUntilRest === 0) {
              Text('今天休息')
                .fontSize(13)
                .fontColor(ThemeColors.SHIFT_REST)
                .fontWeight(FontWeight.Medium)
            } else if (this.daysUntilRest === 1) {
              Text('明天休息')
                .fontSize(13)
                .fontColor(ThemeColors.SHIFT_REST)
            } else {
              Text('距休 ' + this.daysUntilRest + ' 天')
                .fontSize(13)
                .fontColor(ThemeColors.TEXT_SECONDARY)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 6 }) {
        Text('第 ' + this.dayOfCycle + ' / ' + this.totalDays + ' 天')
          .fontSize(13)
          .fontColor(ThemeColors.TEXT_SECONDARY)

        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width('100%')
            .height(8)
            .borderRadius(4)
            .backgroundColor(ThemeColors.DIVIDER)

          Row()
            .width((this.progress * 100) + '%')
            .height(8)
            .borderRadius(4)
            .backgroundColor(SHIFT_COLORS[this.shiftType])
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor(ThemeColors.CARD_SURFACE)
  }
}

