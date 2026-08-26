import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { TokenModel } from '../model/TokenModel';
import { TokenStorage } from '../storage/TokenStorage';
import { OtpUriBuilder } from '../engine/OtpUriBuilder';
import { QrGenerator } from '../engine/QrGenerator';
import { EmptyState } from '../components/EmptyState';
import { image } from '@kit.ImageKit';

@Entry
@Component
struct ExportQrPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State tokens: TokenModel[] = [];
  @State qrStatus: string[] = [];
  @State qrMaps: image.PixelMap[] = [];
  @State currentIndex: number = 0;
  @State loaded: boolean = false;
  @State toastMessage: string = '';
  @State toastVisible: boolean = false;
  private queue: number[] = [];
  private attempted: boolean[] = [];
  private busy: boolean = false;
  private alive: boolean = true;
  private inProgress: number = -1;
  private swiperController: SwiperController = new SwiperController();

  aboutToAppear(): void {
    TokenStorage.init(this.getUIContext().getHostContext()!);
    this.loadTokens();
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.releaseAll();
  }

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        this.NavBar()
        this.WarningBar()

        if (!this.loaded) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(this.getColors().accentBlue)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.tokens.length === 0) {
          EmptyState({ title: this.str($r('app.string.export_qr_empty_title')), subtitle: this.str($r('app.string.export_qr_empty_subtitle')) })
            .width('100%')
            .layoutWeight(1)
        } else {
          Swiper(this.swiperController) {
            ForEach(this.tokens, (token: TokenModel, index: number) => {
              this.QrPageBuilder(token, index)
            }, (token: TokenModel) => token.id)
          }
          .index(this.currentIndex)
          .loop(false)
          .indicator(false)
          .onChange((index: number) => {
            this.currentIndex = index;
            this.prioritize(index);
          })
          .width('100%')
          .layoutWeight(1)

          Row() {
            Text((this.currentIndex + 1).toString() + ' / ' + this.tokens.length.toString())
              .fontSize(14)
              .fontWeight(600)
              .fontColor(this.getColors().textSecondary)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ bottom: 20 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getColors().pageBackground)

      if (this.toastVisible) {
        Row() {
          Text(this.toastMessage)
            .fontSize(14)
            .fontWeight(500)
            .fontColor(this.getColors().white)
            .padding({ top: 10, bottom: 10, left: 20, right: 20 })
            .backgroundColor('rgba(0,0,0,0.8)')
            .borderRadius(22)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .position({ top: 44 })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  NavBar(): void {
    Row() {
      Image(IconConstants.IC_CHEVRON_LEFT)
        .width(22)
        .height(22)
        .margin({ left: 16, top: 8, bottom: 12 })
        .fillColor(this.getColors().accentBlue)
        .onClick(() => {
          this.getUIContext().getRouter().back();
        })

      Text($r('app.string.set_export_qr'))
        .fontSize(16)
        .fontColor('#4285F4')
        .padding({ right: 4, top: 8, bottom: 12 })
        .onClick(() => {
          this.getUIContext().getRouter().back();
        })
    }
    .width('100%')
  }

  @Builder
  WarningBar(): void {
    Row() {
      Text($r('app.string.export_qr_warning'))
        .fontSize(12)
        .fontWeight(500)
        .fontColor('#B45309')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .backgroundColor('#FEF3C7')
    .padding({ top: 10, bottom: 10, left: 16, right: 16 })
  }

  @Builder
  QrPageBuilder(token: TokenModel, index: number): void {
    Column() {
      Text(token.issuer)
        .fontSize(22)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)

      Text(token.account)
        .fontSize(15)
        .fontColor(this.getColors().textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .margin({ top: 4, bottom: 24 })

      Column() {
        if (this.qrStatus[index] === 'ready') {
          Image(this.qrMaps[index])
            .width(260)
            .height(260)
            .objectFit(ImageFit.Contain)
        } else if (this.qrStatus[index] === 'error') {
          Column({ space: 12 }) {
            Text($r('app.string.qr_generate_fail'))
              .fontSize(15)
              .fontWeight(600)
              .fontColor(this.getColors().textSecondary)
            Button($r('app.string.action_retry'))
              .fontSize(14)
              .fontWeight(600)
              .fontColor(this.getColors().white)
              .backgroundColor(this.getColors().accentBlue)
              .borderRadius(10)
              .padding({ left: 24, right: 24, top: 8, bottom: 8 })
              .onClick(() => {
                this.retry(index);
              })
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.getColors().accentBlue)
        }
      }
      .width(260)
      .height(260)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(16)
      .backgroundColor(this.getColors().cardBackground)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 24, right: 24, bottom: 8 })
  }

  // --- Data loading ---

  private async loadTokens(): Promise<void> {
    const tokens: TokenModel[] = await TokenStorage.getAll();
    this.tokens = tokens;
    const n: number = tokens.length;
    const status: string[] = [];
    const att: boolean[] = [];
    for (let i: number = 0; i < n; i++) {
      status.push('loading');
      att.push(false);
    }
    this.qrStatus = status;
    this.attempted = att;
    this.qrMaps = [];
    this.loaded = true;
    if (n === 0) {
      return;
    }
    const startIndex: number = this.resolveStartIndex();
    this.currentIndex = startIndex;
    const order: number[] = [];
    order.push(startIndex);
    for (let i: number = 0; i < n; i++) {
      if (i !== startIndex) {
        order.push(i);
      }
    }
    this.queue = order;
    this.tick();
  }

  private resolveStartIndex(): number {
    const params: Object = this.getUIContext().getRouter().getParams();
    if (params === undefined || params === null) {
      return 0;
    }
    const record: Record<string, Object> = params as Record<string, Object>;
    const focusTokenId: string = record['focusTokenId'] as string;
    if (focusTokenId !== undefined && focusTokenId.length > 0) {
      for (let i: number = 0; i < this.tokens.length; i++) {
        if (this.tokens[i].id === focusTokenId) {
          return i;
        }
      }
    }
    return 0;
  }

  // --- Serial generation queue ---

  private async tick(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    while (this.queue.length > 0) {
      if (!this.alive) {
        break;
      }
      const index: number = this.queue[0];
      this.queue = this.queue.slice(1);
      this.inProgress = index;
      await this.generateOne(index);
      this.inProgress = -1;
    }
    this.busy = false;
  }

  private async generateOne(index: number): Promise<void> {
    if (!this.alive) {
      return;
    }
    const token: TokenModel = this.tokens[index];
    let uri: string = '';
    try {
      uri = OtpUriBuilder.buildUri(token);
    } catch (_e) {
      if (!this.alive) {
        return;
      }
      this.qrStatus[index] = 'error';
      this.refreshQrState();
      this.showToast(this.str($r('app.string.toast_partial_export_fail')));
      return;
    }

    let pm: image.PixelMap | undefined = undefined;
    try {
      pm = await QrGenerator.generateQr(uri);
    } catch (_e) {
      pm = undefined;
    }

    if (!this.alive) {
      if (pm !== undefined) {
        pm.release();
      }
      return;
    }

    if (pm !== undefined) {
      this.qrMaps[index] = pm;
      this.qrStatus[index] = 'ready';
    } else {
      this.qrStatus[index] = 'error';
    }
    this.refreshQrState();
  }

  private prioritize(index: number): void {
    if (this.qrStatus[index] === 'ready' || this.qrStatus[index] === 'error') {
      return;
    }
    if (index === this.inProgress) {
      return;
    }
    if (!this.attempted[index]) {
      this.attempted[index] = true;
      this.queue.push(index);
      this.tick();
      return;
    }
    const newQueue: number[] = [];
    newQueue.push(index);
    for (let i: number = 0; i < this.queue.length; i++) {
      if (this.queue[i] !== index) {
        newQueue.push(this.queue[i]);
      }
    }
    this.queue = newQueue;
    this.tick();
  }

  private retry(index: number): void {
    this.qrStatus[index] = 'loading';
    this.attempted[index] = false;
    this.refreshQrState();
    this.prioritize(index);
  }

  private refreshQrState(): void {
    this.qrMaps = this.qrMaps.slice();
    this.qrStatus = this.qrStatus.slice();
  }

  private releaseAll(): void {
    for (let i: number = 0; i < this.qrMaps.length; i++) {
      if (i < this.qrStatus.length && this.qrStatus[i] === 'ready') {
        this.qrMaps[i].release();
      }
    }
    this.qrMaps = [];
  }

  private showToast(msg: string): void {
    this.toastMessage = msg;
    this.toastVisible = true;
    setTimeout((): void => {
      this.toastVisible = false;
    }, 2000);
  }
}
