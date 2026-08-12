import { IconConstants } from '../../common/IconConstants';
import { ThemeManager, ThemeColors } from '../../common/ThemeManager';

@CustomDialog
export struct ImportPasswordDialog {
  controller: CustomDialogController;
  @Prop isDark: boolean = false;
  confirm?: (password: string) => void;

  @State password: string = '';
  @State showError: boolean = false;
  @State passwordVisible: boolean = false;

  getColors(): ThemeColors {
    if (this.isDark) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column() {
      // Title + description
      Text('输入备份密码')
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .textAlign(TextAlign.Center)
        .margin({ top: 24, bottom: 6 })

      Text('请输入导出时设置的密码来解密备份文件')
        .fontSize(12)
        .fontColor(this.getColors().textSecondary)
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20 })

      // Password input label
      Text('备份密码')
        .fontSize(12)
        .fontWeight(600)
        .fontColor(this.getColors().textSecondary)
        .padding({ left: 22, right: 20, top: 14, bottom: 6 })

      // Password input (with eye toggle)
      Row() {
        TextInput({ placeholder: '', text: this.password })
          .type(this.passwordVisible ? InputType.Normal : InputType.Password)
          .fontSize(17)
          .letterSpacing(4)
          .textAlign(TextAlign.Center)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.password = value;
          })
      }
      .width('100%')
      .backgroundColor(this.getColors().pageBackground)
      .borderRadius(10)

      // Error area
      if (this.showError) {
        Text('⚠️ 密码错误，请重试')
          .fontSize(10)
          .fontColor(this.getColors().dangerRed)
          .padding({ left: 22, top: 8 })
      }

      // Buttons
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

        Text('确认导入')
          .fontSize(15)
          .fontWeight(600)
          .fontColor(this.getColors().accentBlue)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.password.length === 0) {
              return;
            }
            this.controller.close();
            if (this.confirm !== undefined) {
              this.confirm(this.password);
            }
          })
      }
      .width('100%')
      .border({ width: { top: 0.5 }, color: this.getColors().divider })
      .margin({ top: 20 })
    }
    .width(310)
    .padding({ top: 24, left: 20, right: 20, bottom: 0 })
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(16)
  }
}
