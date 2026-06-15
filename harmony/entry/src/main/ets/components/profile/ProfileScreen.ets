import { ThemeColors } from '../../theme/ThemeColors'
import { TEAM_NAMES, TOTAL_TEAMS } from '../../constants/ShiftConstants'
import { loadDefaultTeam, saveDefaultTeam } from '../../storage/SettingsStorage'
import router from '@ohos.router'

@Component
export struct ProfileScreen {
  @State selectedTeam: number = 1

  aboutToAppear(): void {
    this.loadTeam()
  }

  async loadTeam(): Promise<void> {
    this.selectedTeam = await loadDefaultTeam()
  }

  build() {
    Column() {
      Text('我的')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 8 }) {
            Text('当前班组')
              .fontSize(14)
              .fontColor(ThemeColors.TEXT_SECONDARY)

            Row({ space: 8 }) {
              ForEach(Array.from({ length: TOTAL_TEAMS }, (_, i) => i + 1), (teamId: number) => {
                Text(TEAM_NAMES[teamId - 1])
                  .fontSize(14)
                  .fontColor(this.selectedTeam === teamId ? Color.Black : ThemeColors.TEXT_PRIMARY)
                  .fontWeight(this.selectedTeam === teamId ? FontWeight.Medium : FontWeight.Normal)
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .borderRadius(20)
                  .backgroundColor(this.selectedTeam === teamId ? ThemeColors.ACCENT_GOLD : ThemeColors.CARD_SURFACE)
                  .onClick(async () => {
                    this.selectedTeam = teamId
                    await saveDefaultTeam(teamId)
                  })
              })
            }
            .width('100%')
            .flexWrap(FlexWrap.Wrap)
          }
          .width('100%')
          .padding(20)
          .borderRadius(24)
          .backgroundColor(ThemeColors.CARD_SURFACE)

          this.menuItem('倒班规则', '⚙️', () => { router.pushUrl({ url: 'pages/ShiftRule' }) })
          this.menuItem('提醒设置', '⏰', () => { router.pushUrl({ url: 'pages/AlarmSettings' }) })
          this.menuItem('拼假神器', '📅', () => { router.pushUrl({ url: 'pages/LeaveOptimizer' }) })
          this.menuItem('同事模式', '👥', () => { router.pushUrl({ url: 'pages/ColleagueMode' }) })
          this.menuItem('倒班津贴', '💰', () => { router.pushUrl({ url: 'pages/SalaryPredictor' }) })

          Column({ space: 4 }) {
            Text('班伴 ShiftMate')
              .fontSize(14)
              .fontColor(ThemeColors.TEXT_SECONDARY)
            Text('v1.0.0 · HarmonyOS')
              .fontSize(12)
              .fontColor(ThemeColors.TEXT_TERTIARY)
          }
          .width('100%')
          .padding(20)
          .alignItems(HorizontalAlign.Center)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.PRIMARY_BG)
  }

  @Builder
  menuItem(label: string, icon: string, onTap: () => void) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })
      Text(label)
        .fontSize(16)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .layoutWeight(1)
      Text('>')
        .fontSize(16)
        .fontColor(ThemeColors.TEXT_TERTIARY)
    }
    .width('100%')
    .padding(20)
    .borderRadius(20)
    .backgroundColor(ThemeColors.CARD_SURFACE)
    .onClick(onTap)
  }
}
