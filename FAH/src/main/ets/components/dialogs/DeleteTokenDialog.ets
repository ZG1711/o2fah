import { IconConstants } from '../../common/IconConstants';
import { ThemeManager, ThemeColors } from '../../common/ThemeManager';

@CustomDialog
export struct DeleteTokenDialog {
  controller: CustomDialogController;
  @Prop tokenName: string = '';
  @Prop isDark: boolean = false;
  confirm?: () => void;

  getColors(): ThemeColors {
    if (this.isDark) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column() {
      // Trash icon circle
      Column() {
        Image(IconConstants.IC_TRASH)
          .width(24)
          .height(24)
          .fillColor(this.getColors().dangerRed)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.getColors().dangerBackground)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 14 })

      Text('删除令牌')
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .margin({ bottom: 6 })

      Text('确定删除 ' + this.tokenName + ' 吗？')
        .fontSize(13)
        .fontColor(this.getColors().textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 2 })

      Text('此操作不可恢复')
        .fontSize(11)
        .fontColor(this.getColors().textTertiary)

      Row() {
        Text('取消')
          .fontSize(15)
          .fontWeight(500)
          .fontColor(this.getColors().textSecondary)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.controller.close();
          })

        Text('删除')
          .fontSize(15)
          .fontWeight(600)
          .fontColor(this.getColors().dangerRed)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.confirm !== undefined) {
              this.confirm();
            }
            this.controller.close();
          })
      }
      .width('100%')
      .border({ width: { top: 0.5 }, color: this.getColors().divider })
      .margin({ top: 10 })
    }
    .width(300)
    .padding({ top: 24, bottom: 0, left: 20, right: 20 })
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(16)
  }
}
