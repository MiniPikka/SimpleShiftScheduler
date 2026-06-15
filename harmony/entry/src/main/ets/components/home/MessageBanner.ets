import { ThemeColors } from '../../theme/ThemeColors'
import { ShiftType } from '../../constants/ShiftConstants'

function getMessage(shiftType: ShiftType, daysUntilRest: number, consecutiveDays: number): string {
  if (shiftType === ShiftType.REST) {
    return '今天好好休息，补充能量！'
  }
  if (shiftType === ShiftType.STUDY) {
    return '学习日，充实自己！'
  }
  if (daysUntilRest === 1) {
    return '再坚持一天，明天就休息了！'
  }
  if (consecutiveDays >= 5) {
    return '已连续上班' + consecutiveDays + '天，注意调节状态'
  }
  return '坚持住，休息日不远了'
}

@Component
export struct MessageBanner {
  @Prop shiftType: ShiftType = ShiftType.MORNING
  @Prop daysUntilRest: number = 0
  @Prop consecutiveDays: number = 0

  build() {
    Text(getMessage(this.shiftType, this.daysUntilRest, this.consecutiveDays))
      .width('100%')
      .fontSize(14)
      .fontColor(ThemeColors.TEXT_SECONDARY)
      .textAlign(TextAlign.Center)
      .padding(16)
      .borderRadius(20)
      .backgroundColor(ThemeColors.CARD_SURFACE)
  }
}
