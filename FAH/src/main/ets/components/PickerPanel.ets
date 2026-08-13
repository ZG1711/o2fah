import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { curves } from '@kit.ArkUI';

export interface PickerOption {
  label: string;
  value: string;
  description?: string;
  colorPreview?: string;
}

@Component
export struct PickerPanel {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop title: string = '';
  @Prop options: PickerOption[] = [];
  @Prop selectedValue: string = '';
  @Prop @Watch('onVisibleChanged') visible: boolean = false;
  @State internalVisible: boolean = false;
  onSelect?: (value: string) => void;
  onClose?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  onVisibleChanged(): void {
    const uiContext = this.getUIContext();
    if (uiContext !== undefined) {
      uiContext.animateTo({ curve: curves.springMotion() }, () => {
        this.internalVisible = this.visible;
      });
    } else {
      this.internalVisible = this.visible;
    }
  }

  build() {
    if (this.internalVisible) {
      Stack({ alignContent: Alignment.Bottom }) {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.getColors().overlayBackground)
          .onClick(() => {
            if (this.onClose !== undefined) {
              this.onClose();
            }
          })

        // Panel
        Column() {
          // Drag handle
          Row()
            .width(36)
            .height(5)
            .borderRadius(3)
            .backgroundColor(this.getColors().dragBar)
            .margin({ bottom: 18 })

          // Title (optional)
          if (this.title.length > 0) {
            Text(this.title)
              .fontSize(15)
              .fontWeight(600)
              .fontColor(this.getColors().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 12 })
          }

          // Options
          Column({ space: 6 }) {
            ForEach(this.options, (option: PickerOption) => {
              Row() {
                // Color preview (for appearance picker)
                if (option.colorPreview !== undefined) {
                  Row()
                    .width(32)
                    .height(16)
                    .borderRadius(4)
                    .backgroundColor(option.colorPreview)
                    .margin({ right: 10 })
                }

                Column({ space: 2 }) {
                  Text(option.label)
                    .fontSize(15)
                    .fontWeight(this.selectedValue === option.value ? 600 : 500)
                    .fontColor(this.getColors().textPrimary)

                  if (option.description !== undefined) {
                    Text(option.description)
                      .fontSize(11)
                      .fontColor(this.selectedValue === option.value ? this.getColors().textSecondary : this.getColors().textTertiary)
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (this.selectedValue === option.value) {
                  Image(IconConstants.IC_CHECK)
                    .width(16)
                    .height(16)
                    .fillColor(this.getColors().accentBlue)
                }
              }
              .width('100%')
              .padding({ top: 13, bottom: 13, left: 16, right: 16 })
              .borderRadius(12)
              .backgroundColor(this.selectedValue === option.value ? this.getColors().blueBackground : Color.Transparent)
              .onClick(() => {
                if (this.onSelect !== undefined) {
                  this.onSelect(option.value);
                }
              })
            }, (option: PickerOption) => option.value)
          }
        }
        .width('100%')
        .padding({ top: 16, bottom: 28, left: 28, right: 28 })
        .backgroundColor(this.getColors().cardBackground)
        .borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%')
      .height('100%')
      .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion() }))
    }
  }
}
