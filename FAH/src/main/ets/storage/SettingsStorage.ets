import { preferences } from '@kit.ArkData';
import { AppSettings } from '../model/AppSettings';

const STORE_NAME: string = 'o2fah_settings';
const KEY_SETTINGS: string = 'settings';
const KEY_LAST_BACKGROUND: string = 'lastBackgroundTime';

export class SettingsStorage {
  static readonly CURRENT_SETTINGS_VERSION: number = 1;

  private static storedContext: Context | undefined = undefined;
  private static prefsCache: preferences.Preferences | undefined = undefined;

  static init(ctx: Context): void {
    SettingsStorage.storedContext = ctx;
  }

  static async get(): Promise<AppSettings> {
    const ctx: Context = SettingsStorage.getContext();
    const prefs: preferences.Preferences = SettingsStorage.getPrefsSync(ctx);
    const jsonStr: string = prefs.getSync(KEY_SETTINGS, '{}') as string;
    const settings: AppSettings = SettingsStorage.parseSettings(jsonStr);
    // 历史数据（无 schemaVersion）补齐版本标记并落盘，避免每次启动重复判定
    const rawHadVersion: boolean = jsonStr.indexOf('"schemaVersion"') >= 0;
    if (!rawHadVersion && jsonStr !== '{}') {
      await SettingsStorage.save(settings);
    }
    return settings;
  }

  static async save(settings: AppSettings): Promise<void> {
    const ctx: Context = SettingsStorage.getContext();
    const prefs: preferences.Preferences = SettingsStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(settings);
    prefs.putSync(KEY_SETTINGS, jsonStr);
    await prefs.flush();
  }

  static saveLastBackgroundTime(timestamp: number): void {
    const ctx: Context = SettingsStorage.getContext();
    const prefs: preferences.Preferences = SettingsStorage.getPrefsSync(ctx);
    prefs.putSync(KEY_LAST_BACKGROUND, timestamp);
    prefs.flush();
  }

  static getLastBackgroundTime(): number {
    const ctx: Context = SettingsStorage.getContext();
    const prefs: preferences.Preferences = SettingsStorage.getPrefsSync(ctx);
    return prefs.getSync(KEY_LAST_BACKGROUND, 0) as number;
  }

  static async clear(): Promise<void> {
    const ctx: Context = SettingsStorage.getContext();
    const prefs: preferences.Preferences = SettingsStorage.getPrefsSync(ctx);
    prefs.deleteSync(KEY_SETTINGS);
    await prefs.flush();
  }

  private static getPrefsSync(ctx: Context): preferences.Preferences {
    if (SettingsStorage.prefsCache === undefined) {
      const options: preferences.Options = { name: STORE_NAME };
      SettingsStorage.prefsCache = preferences.getPreferencesSync(ctx, options);
    }
    return SettingsStorage.prefsCache;
  }

  private static getContext(): Context {
    if (SettingsStorage.storedContext === undefined) {
      throw new Error('SettingsStorage not initialized. Call SettingsStorage.init(context) first.');
    }
    return SettingsStorage.storedContext;
  }

  private static parseSettings(jsonStr: string): AppSettings {
    const raw: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
    const settings: AppSettings = new AppSettings();
    if (raw['schemaVersion'] !== undefined) {
      settings.schemaVersion = (raw['schemaVersion']) as number;
    }
    // 迁移：无 schemaVersion 的历史数据按 v1 处理。
    // v1 → v1 无字段变更，仅补版本标记；未来版本迁移在此追加字段改写。
    if (settings.schemaVersion < SettingsStorage.CURRENT_SETTINGS_VERSION) {
      settings.schemaVersion = SettingsStorage.CURRENT_SETTINGS_VERSION;
    }
    if (raw['biometricEnabled'] !== undefined) {
      settings.biometricEnabled = (raw['biometricEnabled']) as boolean;
    }
    if (raw['autoLockTimeout'] !== undefined) {
      settings.autoLockTimeout = (raw['autoLockTimeout']) as number;
    }
    if (raw['backupReminder'] !== undefined) {
      settings.backupReminder = (raw['backupReminder']) as string;
    }
    if (raw['themeMode'] !== undefined) {
      settings.themeMode = (raw['themeMode']) as string;
    }
    if (raw['defaultSort'] !== undefined) {
      settings.defaultSort = (raw['defaultSort']) as string;
    }
    if (raw['language'] !== undefined) {
      settings.language = (raw['language']) as string;
    }
    if (raw['lastBackupTime'] !== undefined) {
      settings.lastBackupTime = (raw['lastBackupTime']) as number;
    }
    if (raw['codesHidden'] !== undefined) {
      settings.codesHidden = (raw['codesHidden']) as boolean;
    }
    if (raw['cardCompact'] !== undefined) {
      settings.cardCompact = (raw['cardCompact']) as boolean;
    }
    if (raw['developerMode'] !== undefined) {
      settings.developerMode = (raw['developerMode']) as boolean;
    }
    if (raw['mockDataEnabled'] !== undefined) {
      settings.mockDataEnabled = (raw['mockDataEnabled']) as boolean;
    }
    if (raw['privacyMode'] !== undefined) {
      settings.privacyMode = (raw['privacyMode']) as boolean;
    }
    return settings;
  }
}
