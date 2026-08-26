import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

@Component
export struct SearchBar {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State searchText: string = '';
  onChange?: (text: string) => void;
  onSortClick?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Row({ space: 8 }) {
      // Search input area
      Row({ space: 8 }) {
        Image(IconConstants.IC_SEARCH)
          .width(16)
          .height(16)
          .fillColor(this.getColors().tabUnselected)
        TextInput({ placeholder: $r('app.string.search_placeholder'), text: this.searchText })
          .placeholderColor(this.getColors().tabUnselected)
          .fontSize(15)
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchText = value;
            if (this.onChange !== undefined) {
              this.onChange(value);
            }
          })
        if (this.searchText.length > 0) {
          Button() {
            Image(IconConstants.IC_CLOSE)
              .width(12)
              .height(12)
              .fillColor('#AEAEB2')
          }
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor('rgba(174,174,178,0.2)')
          .onClick(() => {
            this.searchText = '';
            if (this.onChange !== undefined) {
              this.onChange('');
            }
          })
        }
      }
      .height(42)
      .backgroundColor(this.getColors().searchBarBackground)
      .borderRadius(13)
      .padding({ left: 14, right: this.searchText.length > 0 ? 8 : 14 })
      .layoutWeight(1)

      // Sort button
      Button() {
        Image(IconConstants.IC_SORT)
          .width(18)
          .height(18)
          .fillColor(this.getColors().tabUnselected)
      }
      .width(38)
      .height(38)
      .borderRadius(12)
      .backgroundColor(this.getColors().searchBarBackground)
      .onClick(() => {
        if (this.onSortClick !== undefined) {
          this.onSortClick();
        }
      })
    }
    .width('100%')
    .padding({ top: 10 ,left: 20, right: 20, bottom: 10 })
  }
}
