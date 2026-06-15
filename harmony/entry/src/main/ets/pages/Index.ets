import { ThemeColors } from '../theme/ThemeColors'
import { HomeScreen } from '../components/home/HomeScreen'
import { CalendarScreen } from '../components/calendar/CalendarScreen'
import { ProfileScreen } from '../components/profile/ProfileScreen'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0

  @Builder
  tabBuilder(title: string, index: number, icon: string) {
    Column() {
      Text(icon)
        .fontSize(22)
        .fontColor(this.currentIndex === index ? ThemeColors.ACCENT_GOLD : ThemeColors.TEXT_TERTIARY)
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? ThemeColors.ACCENT_GOLD : ThemeColors.TEXT_TERTIARY)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        HomeScreen()
      }
      .tabBar(this.tabBuilder('首页', 0, '🏠'))

      TabContent() {
        CalendarScreen()
      }
      .tabBar(this.tabBuilder('日历', 1, '📅'))

      TabContent() {
        ProfileScreen()
      }
      .tabBar(this.tabBuilder('我的', 2, '👤'))
    }
    .barWidth('100%')
    .barHeight(56)
    .backgroundColor(ThemeColors.PRIMARY_BG)
    .onChange((index: number) => {
      this.currentIndex = index
    })
  }
}
