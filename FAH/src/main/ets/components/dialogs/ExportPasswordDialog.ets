import { IconConstants } from '../../common/IconConstants';
import { ThemeManager, ThemeColors } from '../../common/ThemeManager';

@CustomDialog
export struct ExportPasswordDialog {
  controller: CustomDialogController;
  @Prop isDark: boolean = false;
  confirm?: (password: string) => void;

  @State password: string = '';
  @State confirmPassword: string = '';
  @State showError: boolean = false;
  @State passwordVisible: boolean = false;
  @State confirmVisible: boolean = false;

  getColors(): ThemeColors {
    if (this.isDark) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
  }

  calculateStrength(pwd: string): number {
    if (pwd.length === 0) {
      return 0;
    }
    let types: number = 0;
    if (pwd.search(new RegExp('[A-Z]')) !== -1) {
      types++;
    }
    if (pwd.search(new RegExp('[a-z]')) !== -1) {
      types++;
    }
    if (pwd.search(new RegExp('[0-9]')) !== -1) {
      types++;
    }
    if (pwd.search(new RegExp('[^A-Za-z0-9]')) !== -1) {
      types++;
    }
    if (pwd.length >= 12 && types >= 4) {
      return 3;
    }
    if (pwd.length >= 10 && types >= 3) {
      return 2;
    }
    if (pwd.length >= 8 && types >= 2) {
      return 1;
    }
    return 0;
  }

  getStrengthLabel(level: number): string {
    if (level === 0) {
      return this.str($r('app.string.strength_weak'));
    }
    if (level === 1) {
      return this.str($r('app.string.strength_medium'));
    }
    if (level === 2) {
      return this.str($r('app.string.strength_strong'));
    }
    return this.str($r('app.string.strength_very_strong'));
  }

  getStrengthColor(level: number): string {
    if (level <= 0) {
      return this.getColors().dangerRed;
    }
    if (level === 1) {
      return this.getColors().editOrange;
    }
    if (level === 2) {
      return this.getColors().accentBlue;
    }
    return this.getColors().successGreen;
  }

  getBarColor(barIndex: number, level: number): string {
    if (barIndex <= level) {
      return this.getStrengthColor(level);
    }
    return this.getColors().divider;
  }

  build() {
    Column() {
      // Title + description
      Text($r('app.string.dialog_set_backup_password'))
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 6 })

      Text($r('app.string.dialog_backup_password_desc'))
        .fontSize(12)
        .fontColor(this.getColors().textSecondary)
        .textAlign(TextAlign.Center)

      // Password input label
      Text($r('app.string.field_backup_password'))
        .fontSize(12)
        .fontWeight(600)
        .fontColor(this.getColors().textSecondary)
        .padding({ left: 2, top: 12, bottom: 6 })

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

      Text($r('app.string.password_hint_8chars'))
        .fontSize(10)
        .fontColor(this.getColors().textTertiary)
        .padding({ left: 2, top: 4 })

      Row({ space: 4 }) {
        ForEach([0, 1, 2, 3], (barIndex: number) => {
          Column()
            .layoutWeight(1)
            .height(3)
            .borderRadius(2)
            .backgroundColor(this.getBarColor(barIndex, this.calculateStrength(this.password)))
        }, (barIndex: number) => barIndex.toString())
      }
      .width('100%')
      .padding({ top: 6, bottom: 3 })

      Text(this.getStrengthLabel(this.calculateStrength(this.password)))
        .fontSize(10)
        .fontColor(this.getStrengthColor(this.calculateStrength(this.password)))
        .width('100%')
        .textAlign(TextAlign.End)

      // Confirm password label
      Text($r('app.string.field_confirm_password'))
        .fontSize(12)
        .fontWeight(600)
        .fontColor(this.getColors().textSecondary)
        .padding({ left: 2, top: 6, bottom: 6 })

      // Confirm password input
      Row() {
        TextInput({ placeholder: $r('app.string.placeholder_reenter'), text: this.confirmPassword })
          .type(this.confirmVisible ? InputType.Normal : InputType.Password)
          .fontSize(17)
          .letterSpacing(4)
          .textAlign(TextAlign.Center)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.confirmPassword = value;
          })

      }
      .width('100%')
      .backgroundColor(this.getColors().pageBackground)
      .borderRadius(10)

      if (this.showError) {
        Text($r('app.string.password_not_match'))
          .fontSize(10)
          .fontColor(this.getColors().dangerRed)
          .padding({ left: 2, top: 4 })
      }

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

        Text($r('app.string.button_export'))
          .fontSize(15)
          .fontWeight(600)
          .fontColor(this.getColors().successGreen)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.password !== this.confirmPassword) {
              this.showError = true;
              return;
            }
            if (this.password.length < 8) {
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
