import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

@Component
export struct EmptyState {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column({ space: 16 }) {
      // Icon placeholder
      Column() {
        Image(IconConstants.IC_LOCK)
          .width(28)
          .height(28)
          .fillColor(this.getColors().textTertiary)
      }
      .width(64)
      .height(64)
      .borderRadius(32)
      .backgroundColor(this.getColors().buttonGray)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text('还没有令牌')
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)

      Text('点击右下角 + 按钮添加你的第一个两步验证令牌')
        .fontSize(13)
        .fontColor(this.getColors().textSecondary)
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }
}
