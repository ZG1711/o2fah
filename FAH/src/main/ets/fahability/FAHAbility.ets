import { AbilityConstant, ConfigurationConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { SettingsStorage } from '../storage/SettingsStorage';
import { AppSettings } from '../model/AppSettings';
import { BiometricUtil } from '../utils/BiometricUtil';
import { LanguageManager } from '../common/LanguageManager';

const DOMAIN = 0x0000;
const BIOMETRIC_AUTH_KEY: string = 'requireBiometricAuth';
const APP_LOCKED_KEY: string = 'appIsLocked';
const CACHED_BIOMETRIC_ENABLED: string = 'cachedBiometricEnabled';
const CACHED_AUTO_LOCK_TIMEOUT: string = 'cachedAutoLockTimeout';

export default class FAHAbility extends UIAbility {
  private lastBackgroundTimestamp: number = 0;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    SettingsStorage.init(this.context);
    BiometricUtil.init(this.context);
    const systemColorMode: number = this.context.config.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    ThemeManager.init(systemColorMode);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    AppStorage.setOrCreate(BIOMETRIC_AUTH_KEY, false);
    AppStorage.setOrCreate(APP_LOCKED_KEY, false);
    AppStorage.setOrCreate(CACHED_BIOMETRIC_ENABLED, true);
    AppStorage.setOrCreate(CACHED_AUTO_LOCK_TIMEOUT, 0);
    AppStorage.setOrCreate('lockExpiryTime', 0);
    AppStorage.setOrCreate('lockRetryCountPersisted', 0);
    AppStorage.setOrCreate('pendingImportUri', '');
    if (want.uri !== undefined && want.uri.length > 0) {
      AppStorage.set('pendingImportUri', want.uri);
    }
    this.loadCachedSettings();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    if (want.uri !== undefined && want.uri.length > 0) {
      AppStorage.set('pendingImportUri', want.uri);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const newColorMode: number = newConfig.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    ThemeManager.onSystemColorModeChange(newColorMode);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    this.applyBiometricLock();
    AppStorage.set(APP_LOCKED_KEY, false);
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    this.lastBackgroundTimestamp = Date.now();
    const biometricEnabled: boolean = AppStorage.get<boolean>(CACHED_BIOMETRIC_ENABLED) ?? true;
    const autoLockTimeout: number = AppStorage.get<number>(CACHED_AUTO_LOCK_TIMEOUT) ?? 0;
    if (biometricEnabled && autoLockTimeout === 0) {
      AppStorage.set(APP_LOCKED_KEY, true);
    }
  }

  private loadCachedSettings(): void {
    SettingsStorage.get().then((settings: AppSettings): void => {
      AppStorage.set(CACHED_BIOMETRIC_ENABLED, settings.biometricEnabled);
      AppStorage.set(CACHED_AUTO_LOCK_TIMEOUT, settings.autoLockTimeout);
      LanguageManager.applyStartup(settings.language);
    });
  }

  private applyBiometricLock(): void {
    const biometricEnabled: boolean = AppStorage.get<boolean>(CACHED_BIOMETRIC_ENABLED) ?? true;
    if (!biometricEnabled) {
      AppStorage.set(BIOMETRIC_AUTH_KEY, false);
      return;
    }

    const autoLockTimeout: number = AppStorage.get<number>(CACHED_AUTO_LOCK_TIMEOUT) ?? 0;
    if (autoLockTimeout === 0) {
      AppStorage.set(BIOMETRIC_AUTH_KEY, true);
      return;
    }

    if (this.lastBackgroundTimestamp === 0) {
      AppStorage.set(BIOMETRIC_AUTH_KEY, false);
      return;
    }

    const now: number = Date.now();
    const elapsed: number = now - this.lastBackgroundTimestamp;
    const timeoutMs: number = autoLockTimeout * 1000;

    if (elapsed >= timeoutMs) {
      AppStorage.set(BIOMETRIC_AUTH_KEY, true);
    } else {
      AppStorage.set(BIOMETRIC_AUTH_KEY, false);
    }
  }
}
