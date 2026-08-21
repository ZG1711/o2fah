import { BRAND_ICON_NAMES } from '../common/BrandIconNames';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

class IconDataSource implements IDataSource {
  private names: string[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(names: string[]) {
    this.names = names;
  }

  totalCount(): number {
    return this.names.length;
  }

  getData(index: number): string {
    return this.names[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  setNames(names: string[]): void {
    this.names = names;
    for (let i: number = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }
}

@Component
export struct IconGrid {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop selected: string = '';
  onSelect?: (name: string) => void;

  @State searchText: string = '';
  private dataSource: IconDataSource = new IconDataSource(BRAND_ICON_NAMES);

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private filteredNames(): string[] {
    const kw: string = this.searchText.trim().toLowerCase();
    if (kw.length === 0) {
      return BRAND_ICON_NAMES;
    }
    const result: string[] = [];
    for (let i: number = 0; i < BRAND_ICON_NAMES.length; i++) {
      if (BRAND_ICON_NAMES[i].indexOf(kw) >= 0) {
        result.push(BRAND_ICON_NAMES[i]);
      }
    }
    return result;
  }

  build() {
    Column() {
      TextInput({ placeholder: '搜索图标名称，不支持中文搜索', text: this.searchText })
        .fontSize(14)
        .backgroundColor(this.getColors().pageBackground)
        .borderRadius(10)
        .padding({ top: 10, bottom: 10, left: 14, right: 14 })
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.searchText = value;
          this.dataSource.setNames(this.filteredNames());
        })

      Grid() {
        LazyForEach(this.dataSource, (name: string) => {
          GridItem() {
            Column() {
              Image($r("app.media." + name))
                .width(28)
                .height(28)
                .objectFit(ImageFit.Contain)
            }
            .width(48)
            .height(48)
            .justifyContent(FlexAlign.Center)
            .borderRadius(10)
            .backgroundColor(this.selected === name ? this.getColors().blueBackground : this.getColors().buttonGray)
            .border({
              width: this.selected === name ? 1.5 : 0,
              color: this.getColors().accentBlue
            })
            .onClick(() => {
              if (this.onSelect !== undefined) {
                this.onSelect(name);
              }
            })
          }
        }, (name: string) => name)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      .height(320)
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }
}

@Component
export struct IconPickerPanel {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop visible: boolean = false;
  @Prop selected: string = '';
  onSelect?: (name: string) => void;
  onClose?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.getColors().overlayBackground)
          .onClick(() => {
            if (this.onClose !== undefined) {
              this.onClose();
            }
          })

        Column() {
          Text('选择图标')
            .fontSize(16)
            .fontWeight(700)
            .fontColor(this.getColors().textPrimary)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 14 })

          IconGrid({
            selected: this.selected,
            onSelect: (name: string): void => {
              if (this.onSelect !== undefined) {
                this.onSelect(name);
              }
              if (this.onClose !== undefined) {
                this.onClose();
              }
            }
          })

          Text('取消')
            .fontSize(15)
            .fontWeight(500)
            .fontColor(this.getColors().textSecondary)
            .width('100%')
            .height(44)
            .textAlign(TextAlign.Center)
            .margin({ top: 4 })
            .onClick(() => {
              if (this.onClose !== undefined) {
                this.onClose();
              }
            })
        }
        .width('100%')
        .padding({ top: 16, left: 20, right: 20, bottom: 28 })
        .backgroundColor(this.getColors().cardBackground)
        .borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%')
      .height('100%')
    }
  }
}
