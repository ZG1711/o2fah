import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

export interface TagRowData {
  id: string;
  name: string;
  color: string;
  tokenCount: number;
  sortOrder: number;
  isDragging: boolean;
}

@Component
export struct TagRow {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop tag: TagRowData;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Row() {
      // Color dot
      Column()
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor(this.tag.color)

      // Tag name
      Text(this.tag.name)
        .fontSize(15)
        .fontWeight(500)
        .fontColor(this.getColors().textPrimary)
        .layoutWeight(1)
        .margin({ left: 12 })

      // Token count
      Text(this.tag.tokenCount.toString() + '个令牌')
        .fontSize(13)
        .fontColor(this.getColors().textSecondary)
        .margin({ right: 4 })
    }
    .width('100%')
    .padding({ top: 13, bottom: 13, left: 16, right: 16 })
    .borderRadius(14)
    .backgroundColor(this.getColors().cardBackground)
    .border({ width: this.tag.isDragging ? 1.5 : 0, color: this.getColors().accentBlue })
    .scale({ x: this.tag.isDragging ? 1.03 : 1, y: this.tag.isDragging ? 1.03 : 1 })
    .shadow(this.tag.isDragging ? {
      radius: 20,
      color: 'rgba(0,0,0,0.14)',
      offsetY: 6
    } : {
      radius: 0,
      color: 'transparent',
      offsetY: 0
    })
    .alignItems(VerticalAlign.Center)
  }
}
