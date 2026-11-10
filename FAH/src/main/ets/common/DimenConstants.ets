export class DimenConstants {
  // Card
  static readonly CARD_RADIUS: number = 18;
  static readonly CARD_PADDING_V: number = 16;
  static readonly CARD_PADDING_H: number = 18;
  static readonly CARD_SPACING: number = 10;

  // Page
  static readonly PAGE_HORIZONTAL_PADDING: number = 20;

  // Search bar
  static readonly SEARCH_BAR_HEIGHT: number = 42;
  static readonly SEARCH_BAR_RADIUS: number = 13;
  static readonly SORT_BTN_SIZE: number = 38;

  // Tags
  static readonly TAG_HEIGHT: number = 32;
  static readonly TAG_RADIUS: number = 18;
  static readonly TAG_PADDING_V: number = 7;
  static readonly TAG_PADDING_H: number = 16;

  // FAB
  static readonly FAB_SIZE: number = 56;
  static readonly FAB_RIGHT: number = 20;
  static readonly FAB_BOTTOM: number = 20;

  // Token card internals
  static readonly TOKEN_ICON_SIZE: number = 42;
  static readonly TOKEN_ICON_RADIUS: number = 13;
  static readonly COUNTDOWN_RING_SIZE: number = 36;
  static readonly COPY_ICON_SIZE: number = 30;
  static readonly REFRESH_BTN_SIZE: number = 36;

  // Dialog
  static readonly DIALOG_WIDTH_STD: number = 300;
  static readonly DIALOG_WIDTH_WIDE: number = 310;
  static readonly DIALOG_WIDTH_NARROW: number = 280;
  static readonly DIALOG_RADIUS: number = 16;

  // Empty state
  static readonly EMPTY_ICON_SIZE: number = 64;

  // Settings
  static readonly SETTINGS_ICON_SIZE: number = 30;
  static readonly SETTINGS_ICON_RADIUS: number = 7;

  // Tab bar
  static readonly TAB_BAR_HEIGHT: number = 56;

  // Picker panel
  static readonly PICKER_RADIUS: number = 20;
  static readonly HANDLE_WIDTH: number = 36;
  static readonly HANDLE_HEIGHT: number = 5;
  static readonly HANDLE_RADIUS: number = 3;

  // Responsive layout
  static readonly TABLET_MIN_WIDTH: number = 600;
  static readonly WIDE_LIST_MIN_WIDTH: number = 840;
  static readonly CONTENT_MAX_WIDTH: number = 760;
  static readonly WIDE_CONTENT_MAX_WIDTH: number = 1000;
  static readonly SETTINGS_MAX_WIDTH: number = 640;
  static readonly FORM_MAX_WIDTH: number = 600;
  static readonly SHEET_MAX_WIDTH: number = 520;
  static readonly SHEET_TABLET_BOTTOM_MARGIN: number = 24;
  static readonly LIST_TWO_COLUMN_GAP: number = 12;

  static isTablet(windowWidth: number): boolean {
    return windowWidth >= DimenConstants.TABLET_MIN_WIDTH;
  }

  static contentMaxWidth(windowWidth: number): number {
    if (windowWidth >= DimenConstants.WIDE_LIST_MIN_WIDTH) {
      return DimenConstants.WIDE_CONTENT_MAX_WIDTH;
    }
    return DimenConstants.CONTENT_MAX_WIDTH;
  }

  static pageSidePadding(windowWidth: number, maxContentWidth: number): number {
    const centered: number = (windowWidth - maxContentWidth) / 2;
    if (centered > DimenConstants.PAGE_HORIZONTAL_PADDING) {
      return centered;
    }
    return DimenConstants.PAGE_HORIZONTAL_PADDING;
  }
}