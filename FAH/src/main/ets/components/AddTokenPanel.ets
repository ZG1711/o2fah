import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

@Component
export struct AddTokenPanel {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop visible: boolean = false;
  onClose?: () => void;
  onScanQR?: () => void;
  onPhotoPick?: () => void;
  onManualInput?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column() {
      if (this.visible) {
        Stack({ alignContent: Alignment.Bottom }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.getColors().overlayBackground)
            .onClick(() => {
              if (this.onClose !== undefined) {
                this.onClose();
              }
            })

          Column() {
            Row() {
              Row()
                .width(36)
                .height(5)
                .borderRadius(3)
                .backgroundColor(this.isDarkMode ? '#545458' : '#D1D1D6')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ bottom: 20 })

            Text('添加令牌')
              .fontSize(18)
              .fontWeight(700)
              .fontColor(this.getColors().textPrimary)
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ bottom: 28 })

            Row() {
              Column() {
                Row() {
                  Image(IconConstants.IC_QR_SCAN)
                    .width(34)
                    .height(34)
                    .fillColor(this.getColors().white)
                }
                .width(72)
                .height(72)
                .borderRadius(20)
                .backgroundColor('#4285F4')
                .justifyContent(FlexAlign.Center)
                .shadow({ radius: 14, color: 'rgba(66,133,244,0.30)', offsetX: 0, offsetY: 4 })
                .margin({ bottom: 12 })

                Text('扫描二维码')
                  .fontSize(13)
                  .fontWeight(600)
                  .fontColor(this.getColors().textPrimary)
                  .textAlign(TextAlign.Center)
                Text('相机扫码')
                  .fontSize(11)
                  .fontColor(this.getColors().textSecondary)
                  .textAlign(TextAlign.Center)
              }
              .width(90)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                if (this.onScanQR !== undefined) {
                  this.onScanQR();
                }
              })

              Column() {
                Row() {
                  Image(IconConstants.IC_PHOTO)
                    .width(34)
                    .height(34)
                    .fillColor(this.getColors().white)
                }
                .width(72)
                .height(72)
                .borderRadius(20)
                .backgroundColor('#34C759')
                .justifyContent(FlexAlign.Center)
                .shadow({ radius: 14, color: 'rgba(52,199,89,0.30)', offsetX: 0, offsetY: 4 })
                .margin({ bottom: 12 })

                Text('从相册选取')
                  .fontSize(13)
                  .fontWeight(600)
                  .fontColor(this.getColors().textPrimary)
                  .textAlign(TextAlign.Center)
                Text('识别图片QR')
                  .fontSize(11)
                  .fontColor(this.getColors().textSecondary)
                  .textAlign(TextAlign.Center)
              }
              .width(90)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                if (this.onPhotoPick !== undefined) {
                  this.onPhotoPick();
                }
              })

              Column() {
                Row() {
                  Image(IconConstants.IC_KEYBOARD)
                    .width(34)
                    .height(34)
                    .fillColor(this.getColors().white)
                }
                .width(72)
                .height(72)
                .borderRadius(20)
                .backgroundColor('#FF9500')
                .justifyContent(FlexAlign.Center)
                .shadow({ radius: 14, color: 'rgba(255,149,0,0.30)', offsetX: 0, offsetY: 4 })
                .margin({ bottom: 12 })

                Text('手动输入')
                  .fontSize(13)
                  .fontWeight(600)
                  .fontColor(this.getColors().textPrimary)
                  .textAlign(TextAlign.Center)
                Text('填写密钥')
                  .fontSize(11)
                  .fontColor(this.getColors().textSecondary)
                  .textAlign(TextAlign.Center)
              }
              .width(90)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                if (this.onManualInput !== undefined) {
                  this.onManualInput();
                }
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .margin({ bottom: 32 })

            Button('取消')
              .width('100%')
              .backgroundColor(this.getColors().buttonGray)
              .borderRadius(14)
              .fontSize(16)
              .fontWeight(500)
              .fontColor(this.getColors().textPrimary)
              .onClick(() => {
                if (this.onClose !== undefined) {
                  this.onClose();
                }
              })
          }
          .backgroundColor(this.getColors().cardBackground)
          .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
          .padding({ top: 16, left: 28, right: 28, bottom: 36 })
          .width('100%')
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
