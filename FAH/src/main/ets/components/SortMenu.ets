import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

export interface SortOption {
  key: string;
  label: string;
}

@Component
export struct SortMenu {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop selectedSort: string = 'manual';
  @Prop visible: boolean = false;
  @Prop compactMode: boolean = false;
  onSelectSort?: (sortKey: string) => void;
  onClose?: () => void;
  onToggleCardMode?: () => void;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
  }

  private buildOptions(): SortOption[] {
    const options: SortOption[] = [
      { key: 'manual', label: this.str($r('app.string.set_sort_manual')) },
      { key: 'name', label: this.str($r('app.string.set_sort_name')) },
      { key: 'created', label: this.str($r('app.string.set_sort_created')) },
      { key: 'lastUsed', label: this.str($r('app.string.set_sort_lastused')) }
    ];
    return options;
  }

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.TopStart }) {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.01)')
          .onClick(() => {
            if (this.onClose !== undefined) {
              this.onClose();
            }
          })

        // Menu card
        Column() {
          Text($r('app.string.settings_sort'))
            .fontSize(12)
            .fontWeight(600)
            .fontColor(this.getColors().textSecondary)
            .padding({ top: 10, bottom: 6, left: 16, right: 16 })
            .width('100%')

          ForEach(this.buildOptions(), (option: SortOption) => {
            Row() {
              Text(option.label)
                .fontSize(15)
                .fontWeight(this.selectedSort === option.key ? 600 : 400)
                .fontColor(this.getColors().textPrimary)
                .layoutWeight(1)
              if (this.selectedSort === option.key) {
                Image(IconConstants.IC_CHECK)
                  .width(16)
                  .height(16)
                  .fillColor(this.getColors().accentBlue)
              }
            }
            .width('100%')
            .padding({ top: 11, bottom: 11, left: 16, right: 16 })
            .onClick(() => {
              if (this.onSelectSort !== undefined) {
                this.onSelectSort(option.key);
              }
            })
          }, (option: SortOption) => option.key)

          Divider()
            .width('100%')
            .color(this.getColors().divider)
            .margin({ top: 6, bottom: 4 })

          Text($r('app.string.menu_display'))
            .fontSize(12)
            .fontWeight(600)
            .fontColor(this.getColors().textSecondary)
            .padding({ top: 6, bottom: 4, left: 16, right: 16 })
            .width('100%')

          Row() {
            Text($r('app.string.menu_card_detail'))
              .fontSize(15)
              .fontWeight(!this.compactMode ? 600 : 400)
              .fontColor(this.getColors().textPrimary)
              .layoutWeight(1)
            if (!this.compactMode) {
              Image(IconConstants.IC_CHECK)
                .width(16)
                .height(16)
                .fillColor(this.getColors().accentBlue)
            }
          }
          .width('100%')
          .padding({ top: 9, bottom: 9, left: 16, right: 16 })
          .onClick(() => {
            if (this.onToggleCardMode !== undefined) {
              this.onToggleCardMode();
            }
          })

          Row() {
            Text($r('app.string.menu_card_compact'))
              .fontSize(15)
              .fontWeight(this.compactMode ? 600 : 400)
              .fontColor(this.getColors().textPrimary)
              .layoutWeight(1)
            if (this.compactMode) {
              Image(IconConstants.IC_CHECK)
                .width(16)
                .height(16)
                .fillColor(this.getColors().accentBlue)
            }
          }
          .width('100%')
          .padding({ top: 9, bottom: 10, left: 16, right: 16 })
          .onClick(() => {
            if (this.onToggleCardMode !== undefined) {
              this.onToggleCardMode();
            }
          })
        }
        .width(216)
        .borderRadius(14)
        .backgroundColor(this.getColors().cardBackground)
        .shadow(this.isDarkMode ? undefined : ({ radius: 20, color: 'rgba(0,0,0,0.12)', offsetY: 4 } as ShadowOptions))
        .position({ right: 20, top: 48 })
      }
      .width('100%')
      .height('100%')
    }
  }
}
