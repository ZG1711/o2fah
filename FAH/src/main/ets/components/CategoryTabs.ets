import { ThemeManager, ThemeColors } from '../common/ThemeManager';

export interface TagItem {
  id: string;
  name: string;
  color: string;
}

@Component
export struct CategoryTabs {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop tags: TagItem[] = [];
  @State selectedIndex: number = 0;
  onTagSelect?: (tagId: string, index: number) => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.tags, (tag: TagItem, index: number) => {
          Text(tag.name)
            .fontSize(13)
            .fontWeight(this.selectedIndex === index ? 600 : 500)
            .fontColor(this.getTagTextColor(tag.color))
            .padding({ top: 7, bottom: 7, left: 16, right: 16 })
            .borderRadius(18)
            .backgroundColor(tag.color)
            .border({
              width: 1,
              color: this.selectedIndex === index ? (this.isDarkMode ? '#FFFFFF' : '#1F2937'): tag.color
            })
            .onClick(() => {
              this.selectedIndex = index;
              if (this.onTagSelect !== undefined) {
                this.onTagSelect(tag.id, index);
              }
            })
        }, (tag: TagItem) => tag.id)
      }
      .padding({ left: 20, right: 20, top: 2, bottom: 6 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  private getTagTextColor(color: string): string {
    const r: number = parseInt(color.substring(1, 3), 16);
    const g: number = parseInt(color.substring(3, 5), 16);
    const b: number = parseInt(color.substring(5, 7), 16);
    const luminance: number = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    if (luminance > 0.6) {
      return '#1F2937';
    }
    return '#FFFFFF';
  }
}
