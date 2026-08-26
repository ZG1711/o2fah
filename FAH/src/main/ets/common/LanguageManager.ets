import { i18n } from '@kit.LocalizationKit';

export const LANG_SYSTEM: string = 'system';
export const LANG_ZH_CN: string = 'zh-CN';
export const LANG_EN: string = 'en-US';
export const LANG_ZH_TW: string = 'zh-TW';

export class LanguageManager {
  static readonly SUPPORTED_CODES: string[] = [LANG_ZH_CN, LANG_EN, LANG_ZH_TW];

  static getSystemLanguage(): string {
    try {
      return i18n.System.getSystemLanguage();
    } catch (_e) {
      return LANG_EN;
    }
  }

  static resolveSystemLanguage(systemLang: string): string {
    const lang: string = systemLang.toLowerCase();
    if (lang.indexOf('zh-hant') >= 0 || lang.indexOf('zh-tw') >= 0 ||
      lang.indexOf('zh-hk') >= 0 || lang.indexOf('zh-mo') >= 0) {
      return LANG_ZH_TW;
    }
    if (lang.indexOf('zh') >= 0) {
      return LANG_ZH_CN;
    }
    if (lang.indexOf('en') >= 0) {
      return LANG_EN;
    }
    return LANG_EN;
  }

  static getDefaultLanguage(): string {
    return LanguageManager.resolveSystemLanguage(LanguageManager.getSystemLanguage());
  }

  static isSupported(code: string): boolean {
    for (let i: number = 0; i < LanguageManager.SUPPORTED_CODES.length; i++) {
      if (LanguageManager.SUPPORTED_CODES[i] === code) {
        return true;
      }
    }
    return false;
  }

  static resolveCurrent(saved: string): string {
    if (saved.length > 0 && LanguageManager.isSupported(saved)) {
      return saved;
    }
    return LanguageManager.getDefaultLanguage();
  }

  private static applyCode(code: string): void {
    try {
      if (LanguageManager.isSupported(code)) {
        i18n.System.setAppPreferredLanguage(code);
      }
    } catch (_e) {
    }
  }

  static apply(code: string): void {
    if (code === LANG_SYSTEM) {
      LanguageManager.applyCode(LanguageManager.getDefaultLanguage());
    } else {
      LanguageManager.applyCode(code);
    }
  }

  static applyStartup(saved: string): void {
    LanguageManager.applyCode(LanguageManager.resolveCurrent(saved));
  }
}
