import { ThemeManager, ThemeColors } from '../../common/ThemeManager';

@CustomDialog
export struct TagDeleteDialog {
  controller: CustomDialogController;
  @Prop tagName: string = '';
  @Prop tokenCount: number = 0;
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
      Text($r('app.string.dialog_delete_tag_title'))
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .textAlign(TextAlign.Center)
        .padding({ top: 22, bottom: 8, left: 20, right: 20 })

      Text(this.str($r('app.string.dialog_delete_tag_message')).replace('%s', this.tagName))
        .fontSize(13)
        .fontColor(this.getColors().textSecondary)
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20, bottom: 6 })

      Text(this.str($r('app.string.dialog_delete_tag_effect')).replace('%d', this.tokenCount.toString()))
        .fontSize(12)
        .fontColor(this.getColors().textTertiary)
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20, bottom: 16 })

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
    }
    .width(300)
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(16)
  }
}
