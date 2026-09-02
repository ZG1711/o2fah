import { IconConstants } from '../common/IconConstants';
import { CountdownRing } from './CountdownRing';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { TokenModel } from '../model/TokenModel';

function drawRoundedOutline(c: CanvasRenderingContext2D, w: number, h: number, rad: number, frac: number): void {
  const halfT: number = w / 2 - rad;
  const side: number = h - 2 * rad;
  const bottom: number = w - 2 * rad;
  const arcLen: number = Math.PI * rad / 2;
  const perimeter: number = 2 * halfT + bottom + 2 * side + 4 * arcLen;
  let f: number = frac;
  if (f < 0) {
    f = 0;
  }
  if (f > 1) {
    f = 1;
  }
  let remain: number = perimeter * f;
  // Start at 12 o'clock of the rounded rectangle and walk clockwise.
  let curX: number = w / 2;
  let curY: number = 0;
  c.beginPath();
  c.moveTo(curX, curY);
  for (let idx: number = 0; idx < 9; idx++) {
    if (remain <= 0.001) {
      break;
    }
    let kind: number = 0;
    let len: number = 0;
    let ex: number = 0;
    let ey: number = 0;
    let acx: number = 0;
    let acy: number = 0;
    let a0: number = 0;
    let a1: number = 0;
    switch (idx) {
      case 0:
        kind = 0;
        len = halfT;
        ex = w - rad;
        ey = 0;
        break;
      case 1:
        kind = 1;
        len = arcLen;
        acx = w - rad;
        acy = rad;
        a0 = -Math.PI / 2;
        a1 = 0;
        ex = w;
        ey = rad;
        break;
      case 2:
        kind = 0;
        len = side;
        ex = w;
        ey = h - rad;
        break;
      case 3:
        kind = 1;
        len = arcLen;
        acx = w - rad;
        acy = h - rad;
        a0 = 0;
        a1 = Math.PI / 2;
        ex = w - rad;
        ey = h;
        break;
      case 4:
        kind = 0;
        len = bottom;
        ex = rad;
        ey = h;
        break;
      case 5:
        kind = 1;
        len = arcLen;
        acx = rad;
        acy = h - rad;
        a0 = Math.PI / 2;
        a1 = Math.PI;
        ex = 0;
        ey = h - rad;
        break;
      case 6:
        kind = 0;
        len = side;
        ex = 0;
        ey = rad;
        break;
      case 7:
        kind = 1;
        len = arcLen;
        acx = rad;
        acy = rad;
        a0 = Math.PI;
        a1 = Math.PI * 1.5;
        ex = rad;
        ey = 0;
        break;
      case 8:
        kind = 0;
        len = halfT;
        ex = w / 2;
        ey = 0;
        break;
      default:
        break;
    }
    if (remain >= len) {
      if (kind === 0) {
        c.lineTo(ex, ey);
      } else {
        c.arc(acx, acy, rad, a0, a1);
      }
      curX = ex;
      curY = ey;
      remain = remain - len;
    } else {
      if (kind === 0) {
        const t: number = len > 0 ? remain / len : 0;
        c.lineTo(curX + (ex - curX) * t, curY + (ey - curY) * t);
      } else {
        const sweep: number = Math.PI / 2;
        c.arc(acx, acy, rad, a0, a0 + sweep * (len > 0 ? remain / len : 0));
      }
      remain = 0;
    }
  }
}

@Component
export struct TokenCard {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @ObjectLink token: TokenModel;
  @Prop code: string = '';
  @Prop @Watch('onRemainingChange') remainingSeconds: number = 0;
  @Prop isDragging: boolean = false;
  @Prop tagColorMap: Record<string, string> = {};
  @Prop hideCode: boolean = false;
  @Prop compactMode: boolean = false;
  onCardClick?: () => void;
  onRefreshClick?: () => void;
  onToggleHide?: () => void;

  private borderCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  @State borderW: number = 0;
  @State borderH: number = 0;
  private redrawTimer: number = -1;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
  }

  private onRemainingChange(): void {
    this.requestRedraw();
  }

  private onCardAreaChange(_oldValue: Area, newValue: Area): void {
    const w: number = Number(newValue.width);
    const h: number = Number(newValue.height);
    if (w <= 0 || h <= 0) {
      return;
    }
    if (w !== this.borderW || h !== this.borderH) {
      this.borderW = w;
      this.borderH = h;
      this.requestRedraw();
    }
  }

  private requestRedraw(): void {
    if (this.redrawTimer >= 0) {
      clearTimeout(this.redrawTimer);
    }
    this.redrawTimer = setTimeout(() => {
      this.redrawBorder();
    }, 0);
  }

  aboutToDisappear(): void {
    if (this.redrawTimer >= 0) {
      clearTimeout(this.redrawTimer);
      this.redrawTimer = -1;
    }
  }

  private redrawBorder(): void {
    this.redrawTimer = -1;
    if (this.borderW <= 0 || this.borderH <= 0) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.borderCtx;
    ctx.clearRect(0, 0, this.borderW, this.borderH);
    ctx.lineCap = 'butt';
    const strokeInset: number = 1.5;
    const w: number = this.borderW - strokeInset * 2;
    const h: number = this.borderH - strokeInset * 2;
    const rad: number = 16.5;
    const total: number = this.token.period > 0 ? this.token.period : 30;
    const ratio: number = total > 0 ? this.remainingSeconds / total : 0;
    ctx.save();
    ctx.translate(strokeInset, strokeInset);
    ctx.strokeStyle = this.getRingTrackColor();
    ctx.lineWidth = 3;
    drawRoundedOutline(ctx, w, h, rad, 1);
    ctx.stroke();
    if (ratio > 0.002) {
      ctx.strokeStyle = this.token.iconColor;
      ctx.beginPath();
      drawRoundedOutline(ctx, w, h, rad, ratio);
      ctx.stroke();
    }
    ctx.restore();
  }

  private getRingTrackColor(): string {
    if (this.isDarkMode) {
      return '#3A3A3C';
    }
    return '#E5E5E5';
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.compactMode) {
        this.CompactCard()
      } else {
        this.DetailCard()
      }
      if (this.compactMode && this.token.type === 'TOTP' && this.borderH > 0) {
        Canvas(this.borderCtx)
          .width(this.borderW)
          .height(this.borderH)
          .hitTestBehavior(HitTestMode.Transparent)
          .onReady(() => {
            this.requestRedraw();
          })
      }
    }
    .width('100%')
  }

  @Builder
  CompactCard(): void {
    Column() {
      Row() {
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
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor(this.token.icon.length > 0 ? '#FFFFFF' : this.token.iconColor)
        .border({
          width: this.token.icon.length > 0 ? 0.5 : 0,
          color: this.getColors().divider
        })
        .margin({ right: 10 })

        Column({ space: 3 }) {
          Row() {
            Text(this.token.issuer)
              .fontSize(15)
              .fontWeight(600)
              .fontColor(this.getColors().textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .margin({ right: 10 })

            if (this.hideCode) {
              this.MaskCodeRow(10, 3, 25)
            } else {
              Text(this.code)
                .fontSize(25)
                .fontWeight(700)
                .fontColor(this.getColors().textPrimary)
                .letterSpacing(3)
                .lineHeight(25)
                .maxLines(1)
            }
          }
          .width('100%')

          Row() {
            Text(this.token.account)
              .fontSize(11)
              .fontColor(this.getColors().textSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            if (this.token.type === 'HOTP') {
              Button() {
                Image(IconConstants.IC_REFRESH)
                  .width(13)
                  .height(13)
                  .fillColor(this.getColors().accentBlue)
              }
              .width(24)
              .height(24)
              .borderRadius(7)
              .backgroundColor(this.getColors().buttonGray)
              .margin({ right: 6 })
              .onClick(() => {
                if (this.onRefreshClick !== undefined) {
                  this.onRefreshClick();
                }
              })
            }

            if (this.onToggleHide !== undefined) {
              Button() {
                Image(this.hideCode ? IconConstants.IC_EYE_OFF : IconConstants.IC_EYE)
                  .width(13)
                  .height(13)
              }
              .width(24)
              .height(24)
              .borderRadius(7)
              .backgroundColor(this.getColors().buttonGray)
              .onClick(() => {
                if (this.onToggleHide !== undefined) {
                  this.onToggleHide();
                }
              })
            }

            Button() {
              Image(IconConstants.IC_COPY)
                .width(13)
                .height(13)
            }
            .width(24)
            .height(24)
            .borderRadius(7)
            .margin({left: 5})
            .backgroundColor(this.getColors().buttonGray)
            .onClick(() => {
              if (this.onCardClick !== undefined) {
                this.onCardClick();
              }
            })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        if (this.onCardClick !== undefined) {
          this.onCardClick();
        }
      })
    }
    .width('100%')
    .padding({ top: 12, bottom: 10, left: 18, right: 18 })
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
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.onCardAreaChange(_oldValue, newValue);
    })
  }

  @Builder
  DetailCard(): void {
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
        if (this.hideCode) {
          this.MaskCodeRow(13, 6, 32)
        } else {
          Text(this.code)
            .fontSize(32)
            .fontWeight(700)
            .fontColor(this.getColors().textPrimary)
            .letterSpacing(6)
            .lineHeight(32)
            .maxLines(1)
        }

        Blank()

        if (this.onToggleHide !== undefined) {
          Button() {
            Image(this.hideCode ? IconConstants.IC_EYE_OFF : IconConstants.IC_EYE)
              .width(15)
              .height(15)
          }
          .width(30)
          .height(30)
          .borderRadius(7)
          .backgroundColor(this.getColors().buttonGray)
          .margin({ right: 6 })
          .onClick(() => {
            if (this.onToggleHide !== undefined) {
              this.onToggleHide();
            }
          })
        }

        Button() {
          Image(IconConstants.IC_COPY)
            .width(15)
            .height(15)
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

  private buildMaskDots(): number[] {
    const arr: number[] = [];
    for (let i: number = 0; i < this.token.digits; i++) {
      arr.push(i);
    }
    return arr;
  }

  @Builder
  MaskCodeRow(dotSize: number, gap: number, lineHeight: number): void {
    Row({ space: gap }) {
      ForEach(this.buildMaskDots(), (idx: number) => {
        Stack()
          .width(dotSize)
          .height(dotSize)
          .borderRadius(dotSize / 2)
          .backgroundColor(this.getColors().textPrimary)
      }, (idx: number) => idx.toString())
    }
    .height(lineHeight)
    .alignItems(VerticalAlign.Center)
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
    let text: string = this.token.type + ' · ' + this.token.algorithm + ' · ' + this.token.digits.toString() + this.str($r('app.string.unit_digits'));
    if (this.token.type === 'HOTP') {
      text = text + ' · ' + this.str($r('app.string.unit_counter')) + this.token.counter.toString();
    }
    return text;
  }
}
