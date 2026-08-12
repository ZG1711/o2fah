import { IconConstants } from '../../common/IconConstants';
import { ThemeManager, ThemeColors } from '../../common/ThemeManager';

@CustomDialog
export struct BiometricDialog {
  controller: CustomDialogController;
  @Prop isDark: boolean = false;
  onCancel?: () => void;

  getColors(): ThemeColors {
    if (this.isDark) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column() {
      // Fingerprint icon circle
      Column() {
        Image(IconConstants.IC_FINGERPRINT)
          .width(40)
          .height(40)
          .fillColor(this.getColors().accentBlue)
      }
      .width(72)
      .height(72)
      .borderRadius(36)
      .backgroundColor(this.getColors().blueBackground)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 20 })

      // Title
      Text('验证身份')
        .fontSize(18)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .margin({ bottom: 6 })

      // Subtitle
      Text('请验证指纹以解锁 O2FAH')
        .fontSize(13)
        .fontColor(this.getColors().textSecondary)
        .margin({ bottom: 24 })

      // Cancel button
      Text('取消')
        .fontSize(15)
        .fontWeight(500)
        .fontColor(this.getColors().textPrimary)
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getColors().buttonGray)
        .borderRadius(12)
        .onClick(() => {
          if (this.onCancel !== undefined) {
            this.onCancel();
          }
          this.controller.close();
        })
    }
    .width(280)
    .padding({ top: 32, bottom: 24, left: 24, right: 24 })
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(20)
  }
}
