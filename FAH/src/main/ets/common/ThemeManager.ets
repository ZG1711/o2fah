import { ColorClass } from './ColorConstants';
import { SettingsStorage } from '../storage/SettingsStorage';
import { ConfigurationConstant } from '@kit.AbilityKit';

export interface ThemeColors {
  pageBackground: string;
  cardBackground: string;
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  accentBlue: string;
  dangerRed: string;
  editOrange: string;
  successGreen: string;
  searchBarBackground: string;
  tagUnselectedBackground: string;
  tabBarBackground: string;
  divider: string;
  tabSelected: string;
  tabUnselected: string;
  overlayBackground: string;
  white: string;
  buttonGray: string;
  blueBackground: string;
  warningBackground: string;
  warningText: string;
  dangerBackground: string;
  dragBar: string;
  chevronColor: string;
}

const KEY_IS_DARK_MODE: string = 'isDarkMode';
const KEY_THEME_MODE: string = 'themeMode';
const KEY_SYSTEM_IS_DARK: string = 'systemIsDark';
const THEME_MODE_SYSTEM: string = 'system';
const THEME_MODE_LIGHT: string = 'light';
const THEME_MODE_DARK: string = 'dark';

export class ThemeManager {
  private static lightColorsCache: ThemeColors = ThemeManager.buildLightColors();
  private static darkColorsCache: ThemeColors = ThemeManager.buildDarkColors();

  static init(systemColorMode: number): void {
    const systemIsDark: boolean = systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate(KEY_SYSTEM_IS_DARK, systemIsDark);
    AppStorage.setOrCreate(KEY_THEME_MODE, THEME_MODE_SYSTEM);
    AppStorage.setOrCreate(KEY_IS_DARK_MODE, systemIsDark);
  }

  static async loadSavedMode(): Promise<void> {
    try {
      const settings = await SettingsStorage.get();
      const savedMode: string = settings.themeMode;
      if (savedMode === THEME_MODE_LIGHT || savedMode === THEME_MODE_DARK || savedMode === THEME_MODE_SYSTEM) {
        AppStorage.set(KEY_THEME_MODE, savedMode);
        ThemeManager.updateEffectiveDarkMode();
      }
    } catch (_e) {
    }
  }

  static setManualTheme(mode: string): void {
    AppStorage.set(KEY_THEME_MODE, mode);
    ThemeManager.updateEffectiveDarkMode();
    SettingsStorage.get().then((settings): void => {
      settings.themeMode = mode;
      SettingsStorage.save(settings);
    });
  }

  static onSystemColorModeChange(systemColorMode: number): void {
    const systemIsDark: boolean = systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.set(KEY_SYSTEM_IS_DARK, systemIsDark);
    ThemeManager.updateEffectiveDarkMode();
  }

  static isDarkMode(): boolean {
    const result: boolean | undefined = AppStorage.get<boolean>(KEY_IS_DARK_MODE);
    return result ?? false;
  }

  static getThemeMode(): string {
    const result: string | undefined = AppStorage.get<string>(KEY_THEME_MODE);
    return result ?? THEME_MODE_SYSTEM;
  }

  static getThemeModeLabel(): string {
    const mode: string = ThemeManager.getThemeMode();
    if (mode === THEME_MODE_LIGHT) {
      return '浅色';
    }
    if (mode === THEME_MODE_DARK) {
      return '深色';
    }
    return '跟随系统';
  }

  private static updateEffectiveDarkMode(): void {
    const themeMode: string = ThemeManager.getThemeMode();
    let effectiveDark: boolean;
    if (themeMode === THEME_MODE_LIGHT) {
      effectiveDark = false;
    } else if (themeMode === THEME_MODE_DARK) {
      effectiveDark = true;
    } else {
      const systemDark: boolean = AppStorage.get<boolean>(KEY_SYSTEM_IS_DARK) ?? false;
      effectiveDark = systemDark;
    }
    AppStorage.set(KEY_IS_DARK_MODE, effectiveDark);
  }

  static getLightColors(): ThemeColors {
    return ThemeManager.lightColorsCache;
  }

  static getDarkColors(): ThemeColors {
    return ThemeManager.darkColorsCache;
  }

  private static buildLightColors(): ThemeColors {
    const lightColors: ThemeColors = {
      pageBackground: ColorClass.PAGE_BG_LIGHT,
      cardBackground: ColorClass.CARD_BG_LIGHT,
      textPrimary: ColorClass.TEXT_PRIMARY_LIGHT,
      textSecondary: ColorClass.TEXT_SECONDARY_LIGHT,
      textTertiary: ColorClass.TEXT_TERTIARY_LIGHT,
      accentBlue: ColorClass.ACCENT_BLUE,
      dangerRed: ColorClass.DANGER_RED_LIGHT,
      editOrange: ColorClass.EDIT_ORANGE,
      successGreen: ColorClass.SUCCESS_GREEN,
      searchBarBackground: ColorClass.SEARCH_BAR_BG_LIGHT,
      tagUnselectedBackground: ColorClass.TAG_UNSELECTED_BG_LIGHT,
      tabBarBackground: ColorClass.TAB_BAR_BG_LIGHT,
      divider: ColorClass.DIVIDER_LIGHT,
      tabSelected: ColorClass.TAB_SELECTED,
      tabUnselected: ColorClass.TAB_UNSELECTED,
      overlayBackground: ColorClass.OVERLAY_LIGHT,
      white: ColorClass.WHITE,
      buttonGray: ColorClass.BUTTON_GRAY_LIGHT,
      blueBackground: ColorClass.BLUE_BG_LIGHT,
      warningBackground: ColorClass.WARNING_BG,
      warningText: ColorClass.WARNING_TEXT,
      dangerBackground: ColorClass.DANGER_BG_LIGHT,
      dragBar: ColorClass.DRAG_BAR_LIGHT,
      chevronColor: ColorClass.CHEVRON_LIGHT,
    };
    return lightColors;
  }

  private static buildDarkColors(): ThemeColors {
    const darkColors: ThemeColors = {
      pageBackground: ColorClass.PAGE_BG_DARK,
      cardBackground: ColorClass.CARD_BG_DARK,
      textPrimary: ColorClass.TEXT_PRIMARY_DARK,
      textSecondary: ColorClass.TEXT_SECONDARY_DARK,
      textTertiary: ColorClass.TEXT_TERTIARY_DARK,
      accentBlue: ColorClass.ACCENT_BLUE,
      dangerRed: ColorClass.DANGER_RED_DARK,
      editOrange: ColorClass.EDIT_ORANGE,
      successGreen: ColorClass.SUCCESS_GREEN,
      searchBarBackground: ColorClass.SEARCH_BAR_BG_DARK,
      tagUnselectedBackground: ColorClass.TAG_UNSELECTED_BG_DARK,
      tabBarBackground: ColorClass.TAB_BAR_BG_DARK,
      divider: ColorClass.DIVIDER_DARK,
      tabSelected: ColorClass.TAB_SELECTED,
      tabUnselected: ColorClass.TAB_UNSELECTED,
      overlayBackground: ColorClass.OVERLAY_DARK,
      white: ColorClass.WHITE,
      buttonGray: ColorClass.BUTTON_GRAY_DARK,
      blueBackground: ColorClass.BLUE_BG_DARK,
      warningBackground: ColorClass.WARNING_BG,
      warningText: ColorClass.WARNING_TEXT,
      dangerBackground: ColorClass.DANGER_BG_DARK,
      dragBar: ColorClass.DRAG_BAR_DARK,
      chevronColor: ColorClass.CHEVRON_DARK,
    };
    return darkColors;
  }

  static getColors(): ThemeColors {
    if (ThemeManager.isDarkMode()) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }
}
