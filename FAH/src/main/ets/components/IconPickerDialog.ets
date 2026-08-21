import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { IconGrid } from './IconPicker';

@CustomDialog
export struct IconPickerDialog {
  controller: CustomDialogController;
  @Prop selected: string = '';
  confirm?: (name: string) => void;

  @StorageLink('isDarkMode') isDarkMode: boolean = false;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column() {
      Text('选择图标')
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 20, bottom: 14 })

      Column() {
        IconGrid({
          selected: this.selected,
          onSelect: (name: string): void => {
            if (this.confirm !== undefined) {
              this.confirm(name);
            }
            this.controller.close();
          }
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Text('取消')
        .fontSize(15)
        .fontWeight(500)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
        .onClick(() => {
          this.controller.close();
        })
    }
    .width(340)
    .height(500)
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(16)
  }
}
