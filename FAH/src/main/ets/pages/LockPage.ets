import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { BiometricUtil } from '../utils/BiometricUtil';

@Entry
@Component
struct LockPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('requireBiometricAuth') @Watch('onAuthFlagChanged') requireBiometricAuth: boolean = false;
  @StorageLink('appIsLocked') @Watch('onAppLockedChanged') appIsLocked: boolean = false;
  @State authFailed: boolean = false;
  @State retryCount: number = 0;
  @State showLocked: boolean = false;
  @State remainingSeconds: number = 0;
  private maxRetries: number = 3;
  private countdownTimer: number = -1;
  private authInProgress: boolean = false;
  private dismissed: boolean = false;

  aboutToAppear(): void {
    if (this.requireBiometricAuth) {
      this.startAuth();
    }
  }

  onPageShow(): void {
    if (this.dismissed) {
      return;
    }
    if (!this.authInProgress && !this.showLocked && this.requireBiometricAuth) {
      this.startAuth();
    }
  }

  aboutToDisappear(): void {
    this.stopCountdown();
  }

  onBackPress(): boolean | void {
    return true;
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
    Column() {
      Column({ space: 16 }) {
        Column() {
          Image(IconConstants.IC_FINGERPRINT)
            .width(40)
            .height(40)
            .fillColor(this.getColors().accentBlue)
        }
        .width(72)
        .height(72)
        .borderRadius(36)
        .backgroundColor(this.getColors().blueBackground)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Text($r('app.string.lock_verify_title'))
          .fontSize(18)
          .fontWeight(700)
          .fontColor(this.getColors().textPrimary)

        if (this.showLocked) {
          Text(this.str($r('app.string.lock_too_many')).replace('%d', this.remainingSeconds.toString()))
            .fontSize(13)
            .fontColor(this.getColors().dangerRed)
        } else if (this.authFailed) {
          Text($r('app.string.lock_failed'))
            .fontSize(13)
            .fontColor(this.getColors().dangerRed)
        } else {
          Text($r('app.string.lock_fingerprint_hint'))
            .fontSize(13)
            .fontColor(this.getColors().textSecondary)
        }

        Button(this.showLocked ? this.remainingSeconds.toString() + 's' : this.str($r('app.string.action_retry')))
          .fontSize(15)
          .fontWeight(500)
          .fontColor(this.showLocked ? this.getColors().textTertiary : this.getColors().accentBlue)
          .backgroundColor(this.getColors().buttonGray)
          .borderRadius(12)
          .width('100%')
          .height(44)
          .margin({ top: 8 })
          .onClick(() => {
            if (!this.showLocked) {
              this.authFailed = false;
              this.startAuth();
            }
          })
      }
      .width(280)
      .padding({ top: 32, bottom: 20, left: 24, right: 24 })
      .backgroundColor(this.getColors().cardBackground)
      .borderRadius(20)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#F5F5F7')
  }

  private onAuthFlagChanged(): void {
    if (this.dismissed) {
      return;
    }
    if (this.requireBiometricAuth && !this.authInProgress && !this.showLocked) {
      this.startAuth();
    }
  }

  private onAppLockedChanged(): void {
    if (this.dismissed) {
      return;
    }
    if (!this.appIsLocked && !this.requireBiometricAuth) {
      this.dismissLockPage();
    }
  }

  private dismissLockPage(): void {
    this.dismissed = true;
    this.stopCountdown();
    this.authInProgress = false;
    this.getUIContext().getRouter().back();
  }

  private startAuth(): void {
    if (this.authInProgress || this.dismissed) {
      return;
    }
    this.authInProgress = true;

    const expiry: number = AppStorage.get<number>('lockExpiryTime') ?? 0;
    if (expiry > 0 && Date.now() < expiry) {
      this.authInProgress = false;
      this.showLocked = true;
      this.startCountdown(expiry);
      return;
    }
    if (expiry > 0 && Date.now() >= expiry) {
      AppStorage.set('lockExpiryTime', 0);
      AppStorage.set('lockRetryCountPersisted', 0);
      this.retryCount = 0;
      this.showLocked = false;
      this.stopCountdown();
    }
    const persistedCount: number = AppStorage.get<number>('lockRetryCountPersisted') ?? 0;
    this.retryCount = persistedCount;
    if (this.retryCount >= this.maxRetries) {
      this.authInProgress = false;
      const newExpiry: number = Date.now() + 60000;
      AppStorage.set('lockExpiryTime', newExpiry);
      this.showLocked = true;
      this.startCountdown(newExpiry);
      return;
    }

    BiometricUtil.authenticate().then((success: boolean): void => {
      this.authInProgress = false;
      if (success) {
        AppStorage.set('requireBiometricAuth', false);
        AppStorage.set('appIsLocked', false);
        AppStorage.set('lockExpiryTime', 0);
        AppStorage.set('lockRetryCountPersisted', 0);
        this.stopCountdown();
        this.dismissed = true;
        this.getUIContext().getRouter().back();
      } else {
        const newCount: number = this.retryCount + 1;
        this.retryCount = newCount;
        AppStorage.set('lockRetryCountPersisted', newCount);
        this.authFailed = true;
        if (newCount >= this.maxRetries) {
          const newExpiry: number = Date.now() + 60000;
          AppStorage.set('lockExpiryTime', newExpiry);
          this.showLocked = true;
          this.startCountdown(newExpiry);
        }
      }
    });
  }

  private startCountdown(expiryTime: number): void {
    this.stopCountdown();
    this.countdownTimer = setInterval((): void => {
      const remaining: number = Math.max(0, Math.ceil((expiryTime - Date.now()) / 1000));
      this.remainingSeconds = remaining;
      if (remaining <= 0) {
        AppStorage.set('lockExpiryTime', 0);
        AppStorage.set('lockRetryCountPersisted', 0);
        this.retryCount = 0;
        this.showLocked = false;
        this.remainingSeconds = 0;
        this.stopCountdown();
        this.startAuth();
      }
    }, 200);
  }

  private stopCountdown(): void {
    if (this.countdownTimer >= 0) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }
}
