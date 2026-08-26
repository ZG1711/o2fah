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

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
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

      Text($r('app.string.dialog_delete_token_title'))
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .margin({ bottom: 6 })

      Text(this.str($r('app.string.dialog_delete_token_message')).replace('%s', this.tokenName))
        .fontSize(13)
        .fontColor(this.getColors().textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 2 })

      Text($r('app.string.dialog_irreversible'))
        .fontSize(11)
        .fontColor(this.getColors().textTertiary)

      Row() {
        Text($r('app.string.button_cancel'))
          .fontSize(15)
          .fontWeight(500)
          .fontColor(this.getColors().textSecondary)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.controller.close();
          })

        Text($r('app.string.button_delete'))
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
