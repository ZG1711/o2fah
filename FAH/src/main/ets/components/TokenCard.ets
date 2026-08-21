import { IconConstants } from '../common/IconConstants';
import { CountdownRing } from './CountdownRing';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { TokenModel } from '../model/TokenModel';

@Component
export struct TokenCard {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop token: TokenModel;
  @Prop code: string = '';
  @Prop remainingSeconds: number = 0;
  @Prop isDragging: boolean = false;
  @Prop tagColorMap: Record<string, string> = {};
  onCardClick?: () => void;
  onRefreshClick?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 12 }) {
          Stack({ alignContent: Alignment.Center }) {
            if (this.token.icon.length > 0) {
              Image($r('app.media.' + this.token.icon))
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain)
            } else {
              Text(this.token.issuer.charAt(0).toUpperCase())
                .fontSize(20)
                .fontWeight(700)
                .fontColor(this.getColors().white)
            }
          }
          .width(42)
          .height(42)
          .borderRadius(13)
          .backgroundColor(this.token.icon.length > 0 ? '#FFFFFF' : this.token.iconColor)
          .border({
            width: this.token.icon.length > 0 ? 0.5 : 0,
            color: this.getColors().divider
          })
          Column({ space: 1 }) {
            Text(this.token.issuer)
              .fontSize(16)
              .fontWeight(600)
              .fontColor(this.getColors().textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.token.account)
              .fontSize(12)
              .fontColor(this.getColors().textSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        if (this.token.type === 'TOTP') {
          CountdownRing({
            totalSeconds: this.token.period,
            remainingSeconds: this.remainingSeconds,
            color: this.token.iconColor
          })
        }
        if (this.token.type === 'HOTP') {
          Button() {
            Image(IconConstants.IC_REFRESH)
              .width(18)
              .height(18)
              .fillColor(this.getColors().accentBlue)
          }
          .width(36)
          .height(36)
          .borderRadius(10)
          .backgroundColor(this.getColors().buttonGray)
          .onClick(() => {
            if (this.onRefreshClick !== undefined) {
              this.onRefreshClick();
            }
          })
        }
      }
      .width('100%')
      .margin({ bottom: 10 })

      Row() {
        Text(this.code)
          .fontSize(32)
          .fontWeight(700)
          .fontColor(this.getColors().textPrimary)
          .letterSpacing(6)
          .lineHeight(32)

        Blank()

        Button() {
          Image(IconConstants.IC_COPY)
            .width(15)
            .height(15)
            .fillColor(this.getColors().textSecondary)
        }
        .width(30)
        .height(30)
        .borderRadius(7)
        .backgroundColor(this.getColors().buttonGray)
        .onClick(() => {
          if (this.onCardClick !== undefined) {
            this.onCardClick();
          }
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 6 })
      .onClick(() => {
        if (this.onCardClick !== undefined) {
          this.onCardClick();
        }
      })

      Row() {
        Row({ space: 6 }) {
          ForEach(this.token.tags, (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontWeight(600)
              .fontColor(this.getTagTextColor(tag))
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(10)
              .backgroundColor(this.getTagColor(tag))
          }, (tag: string) => tag)
        }

        Blank()

        Text(this.getProtocolText())
          .fontSize(10)
          .fontColor(this.getColors().textTertiary)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 16, bottom: 12, left: 18, right: 18 })
    .borderRadius(18)
    .backgroundColor(this.getColors().cardBackground)
    .border({
      width: this.isDragging ? 1.5 : 0,
      color: this.getColors().accentBlue
    })
    .scale({ x: this.isDragging ? 1.04 : 1, y: this.isDragging ? 1.04 : 1 })
    .shadow(this.isDragging ? {
      radius: 40,
      color: 'rgba(0,0,0,0.18)',
      offsetY: 12
    } : {
      radius: 8,
      color: 'rgba(0,0,0,0.04)',
      offsetY: 2
    })
  }

  private getTagColor(tagName: string): string {
    const color: string | undefined = this.tagColorMap[tagName];
    if (color !== undefined) {
      return color;
    }
    return this.token.iconColor;
  }

  private getTagTextColor(tagName: string): string {
    const bg: string = this.getTagColor(tagName);
    const r: number = parseInt(bg.substring(1, 3), 16);
    const g: number = parseInt(bg.substring(3, 5), 16);
    const b: number = parseInt(bg.substring(5, 7), 16);
    const luminance: number = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    if (luminance > 0.6) {
      return '#1F2937';
    }
    return '#FFFFFF';
  }

  private getProtocolText(): string {
    let text: string = this.token.type + ' · ' + this.token.algorithm + ' · ' + this.token.digits.toString() + '位';
    if (this.token.type === 'HOTP') {
      text = text + ' · 计数' + this.token.counter.toString();
    }
    return text;
  }
}
