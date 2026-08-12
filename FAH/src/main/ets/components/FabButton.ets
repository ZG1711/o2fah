import { ThemeManager, ThemeColors } from '../common/ThemeManager';

@Component
export struct FabButton {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onFabClick?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Button() {
      Text('+')
        .fontSize(28)
        .fontWeight(300)
        .fontColor(this.getColors().white)
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor(this.getColors().accentBlue)
    .shadow(this.isDarkMode ? {
      radius: 0,
      color: 'transparent',
      offsetY: 0
    } : {
      radius: 20,
      color: 'rgba(66,133,244,0.35)',
      offsetY: 4
    })
    .onClick(() => {
      if (this.onFabClick !== undefined) {
        this.onFabClick();
      }
    })
  }
}
