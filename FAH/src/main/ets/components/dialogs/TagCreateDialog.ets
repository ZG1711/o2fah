import { ThemeManager, ThemeColors } from '../../common/ThemeManager';

const ALL_COLORS: string[] = [
  '#000000', '#1A1A1A', '#333333', '#4D4D4D', '#666666', '#808080', '#999999', '#B3B3B3',
  '#CC0000', '#CC3300', '#CC6600', '#CC9900', '#CCCC00', '#99CC00', '#66CC00', '#33CC00',
  '#00CC00', '#00CC33', '#00CC66', '#00CC99', '#00CCCC', '#0099CC', '#0066CC', '#0033CC',
  '#0000CC', '#3300CC', '#6600CC', '#9900CC', '#CC00CC', '#CC0099', '#CC0066', '#CC0033',
  '#FF0000', '#FF3300', '#FF6600', '#FF9900', '#FFCC00', '#CCFF00', '#99FF00', '#66FF00',
  '#33FF00', '#00FF00', '#00FF33', '#00FF66', '#00FF99', '#00FFCC', '#00CCFF', '#0099FF',
  '#0066FF', '#0033FF', '#0000FF', '#3300FF', '#6600FF', '#9900FF', '#CC00FF', '#FF00FF',
  '#FF0099', '#FF0066', '#FF0033', '#FFFFFF', '#F0F0F0', '#E0E0E0', '#D0D0D0', '#C0C0C0',
  '#FFB3B3', '#FFD9B3', '#FFFFB3', '#B3FFB3', '#B3FFD9', '#B3FFFF', '#B3D9FF', '#B3B3FF',
  '#D9B3FF', '#FFB3FF', '#FFB3D9', '#E8F0FE', '#E8F5E9', '#FFF3E0', '#F3E8FF', '#FFEBEA',
  '#E0F7FA', '#FFF8E1', '#FCE4EC', '#E8EAF6', '#FFF3CD'
];

@CustomDialog
export struct TagCreateDialog {
  controller: CustomDialogController;
  @Prop isEdit: boolean = false;
  @Prop tagName: string = '';
  @Prop tagColor: string = '#4285F4';
  @Prop isDark: boolean = false;
  confirm?: (name: string, color: string) => void;

  @State inputName: string = '';
  @State selectedColor: string = '#4285F4';
  @State showColorPicker: boolean = false;

  private presetColors: string[] = [
    '#4285F4',
    '#34C759',
    '#FF9500',
    '#FF3B30',
    '#A855F7',
    '#0EA5E9'
  ];

  aboutToAppear(): void {
    this.inputName = this.tagName;
    this.selectedColor = this.tagColor;
  }

  getColors(): ThemeColors {
    if (this.isDark) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private getColorRows(): string[][] {
    const rows: string[][] = [];
    const cols: number = 8;
    for (let i: number = 0; i < ALL_COLORS.length; i = i + cols) {
      const row: string[] = [];
      for (let j: number = i; j < i + cols && j < ALL_COLORS.length; j++) {
        row.push(ALL_COLORS[j]);
      }
      rows.push(row);
    }
    return rows;
  }

  build() {
    Column() {
      Text(this.isEdit ? '编辑分类标签' : '新建分类标签')
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .textAlign(TextAlign.Center)
        .padding({ top: 22, bottom: 10, left: 20, right: 20 })

      Text('标签名称')
        .fontSize(12)
        .fontWeight(600)
        .fontColor(this.getColors().textSecondary)
        .padding({ left: 22, right: 20, bottom: 6 })

      TextInput({ placeholder: '例如: 游戏', text: this.inputName })
        .fontSize(15)
        .backgroundColor(this.getColors().pageBackground)
        .borderRadius(10)
        .padding({ top: 12, bottom: 12, left: 14, right: 14 })
        .margin({ left: 20, right: 20 })
        .border({ width: 1.5, color: this.getColors().divider })
        .onChange((value: string) => {
          this.inputName = value;
        })

      Text('最多10个字符，不可与已有标签重复')
        .fontSize(10)
        .fontColor(this.getColors().textTertiary)
        .padding({ left: 22, right: 20, top: 4, bottom: 10 })

      Text('预设颜色')
        .fontSize(12)
        .fontWeight(600)
        .fontColor(this.getColors().textSecondary)
        .padding({ left: 22, right: 20, bottom: 8 })

      Row({ space: 12 }) {
        ForEach(this.presetColors, (color: string) => {
          Column()
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor(color)
            .border(this.selectedColor === color ?
              ({ width: 3, color: this.getColors().textPrimary } as BorderOptions) :
              undefined)
            .onClick(() => {
              this.selectedColor = color;
            })
        }, (color: string) => color)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 12 })

      Text('其他颜色')
        .fontSize(12)
        .fontWeight(600)
        .fontColor(this.getColors().textSecondary)
        .padding({ left: 22, right: 20, bottom: 6 })

      Row({ space: 12 }) {
        Column()
          .width(24)
          .height(24)
          .borderRadius(6)
          .backgroundColor(this.selectedColor)
          .border({ width: 1, color: this.getColors().divider })

        Text(this.selectedColor)
          .fontSize(14)
          .fontColor(this.getColors().textPrimary)
      }
      .height(44)
      .backgroundColor(this.getColors().pageBackground)
      .borderRadius(10)
      .padding({ left: 14, right: 14 })
      .margin({ left: 20, right: 20 })
      .onClick(() => {
        this.showColorPicker = !this.showColorPicker;
      })

      if (this.showColorPicker) {
        Scroll() {
          Column({ space: 6 }) {
            ForEach(this.getColorRows(), (row: string[]) => {
              Row({ space: 6 }) {
                ForEach(row, (color: string) => {
                  Column()
                    .width(28)
                    .height(28)
                    .borderRadius(6)
                    .backgroundColor(color)
                    .border({ width: 1, color: this.getColors().divider })
                    .onClick(() => {
                      this.selectedColor = color;
                      this.showColorPicker = false;
                    })
                }, (color: string) => color)
              }
              .justifyContent(FlexAlign.Start)
            }, (row: string[]) => row[0])
          }
          .padding({ left: 8, right: 8 })
        }
        .height(160)
        .scrollBar(BarState.Off)
        .backgroundColor(this.getColors().pageBackground)
        .borderRadius(10)
        .margin({ left: 20, right: 20, top: 6, bottom: 12 })
      }

      Row() {
        Text('取消')
          .fontSize(15)
          .fontWeight(500)
          .fontColor(this.getColors().textSecondary)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.controller.close();
          })

        Text(this.isEdit ? '保存' : '创建')
          .fontSize(15)
          .fontWeight(600)
          .fontColor(this.inputName.trim().length > 0 ? this.getColors().accentBlue : this.getColors().textTertiary)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.inputName.trim().length === 0) {
              return;
            }
            if (this.confirm !== undefined) {
              this.confirm(this.inputName, this.selectedColor);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .border({ width: { top: 0.5 }, color: this.getColors().divider })
    }
    .width(320)
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(16)
  }
}
