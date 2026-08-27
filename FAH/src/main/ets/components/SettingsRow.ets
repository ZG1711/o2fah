import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

@Component
export struct SettingsRow {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop iconEmoji: string = '';
  @Prop iconBgColor: string = '#E8F0FE';
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop showArrow: boolean = true;
  @Prop isDestructive: boolean = false;
  @Prop showDivider: boolean = true;
  @Prop hasToggle: boolean = false;
  @Prop toggleOn: boolean = false;
  @Prop dimmed: boolean = false;
  onRowClick?: () => void;
  onToggle?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Row() {
      if (this.isDestructive) {
        Text(this.label)
          .fontSize(15)
          .fontWeight(500)
          .fontColor(this.getColors().dangerRed)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        Column() {
          Text(this.iconEmoji)
            .fontSize(15)
        }
        .width(30)
        .height(30)
        .borderRadius(7)
        .backgroundColor(this.dimmed ? this.getColors().buttonGray : this.iconBgColor)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Text(this.label)
          .fontSize(15)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
          .margin({ left: 10 })

        Row({ space: 4 }) {
          if (this.hasToggle) {
            Toggle({ type: ToggleType.Switch, isOn: this.toggleOn })
              .onTouchIntercept((): HitTestMode => {
                if (this.onToggle !== undefined) {
                  this.onToggle();
                }
                return HitTestMode.None;
              })
          }
          if (this.value.length > 0) {
            Text(this.value)
              .fontSize(15)
              .fontColor(this.getColors().textSecondary)
          }
          if (this.showArrow && !this.hasToggle) {
            Image(IconConstants.IC_CHEVRON_RIGHT)
              .width(16)
              .height(16)
              .fillColor(this.getColors().chevronColor)
          }
        }
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding({ top: 13, bottom: 13, left: 16, right: 16 })
    .opacity(this.dimmed && !this.hasToggle ? 0.4 : 1.0)
    .onClick(() => {
      if (this.dimmed && !this.hasToggle) {
        return;
      }
      if (this.onRowClick !== undefined) {
        this.onRowClick();
      }
    })
  }
}
