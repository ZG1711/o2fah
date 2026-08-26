import { ThemeManager, ThemeColors } from '../../common/ThemeManager';
import { MergeResult } from '../../backup/BackupImporter';

@CustomDialog
export struct ImportMergeDialog {
  controller: CustomDialogController;
  @Prop mergeResult: MergeResult = {
    newTokens: [],
    skippedCount: 0,
    addedCount: 0,
    totalAfter: 0
  };
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
      // Title
      Text($r('app.string.dialog_import_merge_title'))
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .textAlign(TextAlign.Center)
        .padding({ top: 22, bottom: 8, left: 20, right: 20 })

      // Stats row
      Column({ space: 8 }) {
        Row() {
          Text($r('app.string.stat_total_tokens'))
            .fontSize(14)
            .fontColor(this.getColors().textSecondary)
            .layoutWeight(1)
          Text(this.mergeResult.totalAfter.toString())
            .fontSize(14)
            .fontWeight(600)
            .fontColor(this.getColors().textPrimary)
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        Divider().height(0.5).color(this.getColors().divider)

        Row() {
          Text($r('app.string.stat_added'))
            .fontSize(14)
            .fontColor(this.getColors().textSecondary)
            .layoutWeight(1)
          Text('+' + this.mergeResult.addedCount.toString())
            .fontSize(14)
            .fontWeight(600)
            .fontColor('#34C759')
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        Divider().height(0.5).color(this.getColors().divider)

        Row() {
          Text($r('app.string.stat_skipped'))
            .fontSize(14)
            .fontColor(this.getColors().textSecondary)
            .layoutWeight(1)
          Text(this.mergeResult.skippedCount.toString())
            .fontSize(14)
            .fontWeight(600)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        Divider().height(0.5).color(this.getColors().divider)

        Row() {
          Text($r('app.string.stat_total_after'))
            .fontSize(14)
            .fontColor(this.getColors().textSecondary)
            .layoutWeight(1)
          Text(this.mergeResult.totalAfter.toString())
            .fontSize(14)
            .fontWeight(600)
            .fontColor(this.getColors().textPrimary)
        }
        .width('100%')
        .padding({ left: 4, right: 4 })
      }
      .width('100%')
      .backgroundColor(this.getColors().pageBackground)
      .borderRadius(10)
      .padding({ top: 12, bottom: 12, left: 12, right: 12 })
      .margin({ left: 20, right: 20, top: 10 })

      // Warning
      Row() {
        Text($r('app.string.dialog_import_merge_warning'))
          .fontSize(11)
          .fontColor('#B45309')
      }
      .width('100%')
      .backgroundColor('#FEF3C7')
      .borderRadius(8)
      .padding({ top: 8, bottom: 8, left: 12, right: 12 })
      .margin({ left: 20, right: 20, top: 8 })
      .justifyContent(FlexAlign.Center)

      // Buttons
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

        Text($r('app.string.action_confirm_import'))
          .fontSize(15)
          .fontWeight(600)
          .fontColor(this.getColors().accentBlue)
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
      .margin({ top: 16 })
    }
    .width(320)
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(16)
  }
}
