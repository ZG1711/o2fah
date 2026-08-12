import { ThemeManager, ThemeColors } from '../../common/ThemeManager';

export interface EditResult {
  issuer: string;
  account: string;
  tags: string[];
}

@CustomDialog
export struct EditTokenDialog {
  controller: CustomDialogController;
  @Prop issuer: string = '';
  @Prop account: string = '';
  @Prop tags: string[] = [];
  @Prop tagNames: string[] = [];
  @Prop tagColors: string[] = [];
  @Prop isDark: boolean = false;
  confirm?: (result: EditResult) => void;

  @State editIssuer: string = '';
  @State editAccount: string = '';
  @State tagSelections: boolean[] = [];

  aboutToAppear(): void {
    this.editIssuer = this.issuer;
    this.editAccount = this.account;
    const selections: boolean[] = [];
    for (let i: number = 0; i < this.tagNames.length; i++) {
      let found: boolean = false;
      for (let j: number = 0; j < this.tags.length; j++) {
        if (this.tagNames[i] === this.tags[j]) {
          found = true;
          break;
        }
      }
      selections.push(found);
    }
    this.tagSelections = selections;
  }

  getColors(): ThemeColors {
    if (this.isDark) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column() {
      Text('编辑令牌')
        .fontSize(17)
        .fontWeight(700)
        .fontColor(this.getColors().textPrimary)
        .textAlign(TextAlign.Center)
        .padding({ top: 22, bottom: 8, left: 20, right: 20 })

      Scroll() {
        Column() {
          Text('发行方')
            .fontSize(12)
            .fontWeight(600)
            .fontColor(this.getColors().textSecondary)
            .padding({ left: 2, right: 20, bottom: 6 })

          TextInput({ placeholder: '', text: this.editIssuer })
            .fontSize(15)
            .backgroundColor(this.getColors().pageBackground)
            .borderRadius(10)
            .padding({ top: 12, bottom: 12, left: 14, right: 14 })
            .margin({ left: 20, right: 20 })
            .onChange((value: string) => {
              this.editIssuer = value;
            })

          Text('账户名')
            .fontSize(12)
            .fontWeight(600)
            .fontColor(this.getColors().textSecondary)
            .padding({ left: 2, right: 20, top: 10, bottom: 6 })

          TextInput({ placeholder: '', text: this.editAccount })
            .fontSize(15)
            .backgroundColor(this.getColors().pageBackground)
            .borderRadius(10)
            .padding({ top: 12, bottom: 12, left: 14, right: 14 })
            .margin({ left: 20, right: 20, bottom: 20 })
            .onChange((value: string) => {
              this.editAccount = value;
            })

          if (this.tagNames.length > 0) {
            Text('分类标签')
              .fontSize(12)
              .fontWeight(600)
              .fontColor(this.getColors().textSecondary)
              .padding({ left: 2, right: 20, bottom: 6 })

            Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
              ForEach(this.tagNames, (tag: string, index: number) => {
                Text(tag)
                  .fontSize(13)
                  .fontWeight(500)
                  .fontColor(this.getTagTextColor(index))
                  .padding({ top: 7, bottom: 7, left: 14, right: 14 })
                  .borderRadius(16)
                  .backgroundColor(this.tagColors[index])
                  .border({
                    width: this.tagSelections[index] ? 1 : 1,
                    color: this.tagSelections[index] ? (this.isDark ? '#FFFFFF' : '#1F2937') : this.tagColors[index]
                  })
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    const newSelections: boolean[] = [...this.tagSelections];
                    newSelections[index] = !newSelections[index];
                    this.tagSelections = newSelections;
                  })
              }, (tag: string) => tag)
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 12 })
          }
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxHeight: 420 })
      .scrollBar(BarState.Off)

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

        Text('保存')
          .fontSize(15)
          .fontWeight(600)
          .fontColor(this.getColors().accentBlue)
          .width('50%')
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.confirm !== undefined) {
              const selectedTags: string[] = [];
              for (let i: number = 0; i < this.tagSelections.length; i++) {
                if (this.tagSelections[i]) {
                  selectedTags.push(this.tagNames[i]);
                }
              }
              const result: EditResult = {
                issuer: this.editIssuer,
                account: this.editAccount,
                tags: selectedTags
              };
              this.confirm(result);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .border({ width: { top: 0.5 }, color: this.getColors().divider })
    }
    .width(300)
    .backgroundColor(this.getColors().cardBackground)
    .borderRadius(16)
  }

  private getTagTextColor(index: number): string {
    const color: string = this.tagColors[index];
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
