import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

@Component
export struct EmptyState {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop title: string = '';
  @Prop subtitle: string = '';

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
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

      Text(this.title.length > 0 ? this.title : this.str($r('app.string.empty_tokens_title')))
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)

      Text(this.subtitle.length > 0 ? this.subtitle : this.str($r('app.string.empty_tokens_desc')))
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
