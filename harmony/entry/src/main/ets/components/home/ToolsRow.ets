import { ThemeColors } from '../../theme/ThemeColors'

interface ToolItem {
  label: string
  icon: string
  color: string
  onTap: () => void
}

@Component
export struct ToolsRow {
  onLeaveTap: () => void = () => {}
  onColleagueTap: () => void = () => {}
  onSalaryTap: () => void = () => {}

  build() {
    Row({ space: 12 }) {
      this.toolCard('拼假神器', '📅', ThemeColors.SHIFT_MORNING, this.onLeaveTap)
      this.toolCard('同事模式', '👥', ThemeColors.SHIFT_AFTERNOON, this.onColleagueTap)
      this.toolCard('倒班津贴', '💰', ThemeColors.SHIFT_STUDY, this.onSalaryTap)
    }
    .width('100%')
  }

  @Builder
  toolCard(label: string, icon: string, color: string, onTap: () => void) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(28)
      Text(label)
        .fontSize(14)
        .fontColor(ThemeColors.TEXT_PRIMARY)
    }
    .layoutWeight(1)
    .padding(16)
    .borderRadius(20)
    .backgroundColor(ThemeColors.CARD_SURFACE)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height(88)
    .onClick(onTap)
  }
}
