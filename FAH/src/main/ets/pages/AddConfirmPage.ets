import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { matchIcon } from '../common/BrandIconNames';
import { IconPickerPanel } from '../components/IconPicker';
import { TokenModel } from '../model/TokenModel';
import { TokenStorage } from '../storage/TokenStorage';
import { TagStorage } from '../storage/TagStorage';
import { TagModel } from '../model/TagModel';
import { OtpUriParser } from '../engine/OtpUriParser';
import { pasteboard } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct AddConfirmPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State issuer: string = '';
  @State account: string = '';
  @State icon: string = '';
  @State secretKey: string = '';
  @State parsedToken: TokenModel = new TokenModel();
  @State showKey: boolean = false;
  @State tagSelections: boolean[] = [];
  @State tagNames: string[] = [];
  @State tagColors: string[] = [];
  @State toastMessage: string = '';
  @State toastVisible: boolean = false;
  @State loading: boolean = false;
  @State showIconPicker: boolean = false;

  aboutToAppear(): void {
    TagStorage.init(this.getUIContext().getHostContext()!);
    this.loadTags();
    const params = router.getParams() as Record<string, Object>;
    if (params !== undefined && params !== null) {
      const uri: string = params['uri'] as string;
      if (uri !== undefined && uri.length > 0) {
        const token: TokenModel | null = OtpUriParser.parse(uri);
        if (token !== null) {
          this.parsedToken = token;
          this.issuer = token.issuer;
          this.account = token.account;
          this.secretKey = token.secret;
          this.icon = matchIcon(token.issuer);
        }
      }
    }
  }

  private getInitial(): string {
    if (this.issuer.trim().length > 0) {
      return this.issuer.trim().charAt(0).toUpperCase();
    }
    if (this.account.trim().length > 0) {
      return this.account.trim().charAt(0).toUpperCase();
    }
    return '?';
  }

  onBackPress(): boolean {
    if (this.showIconPicker) {
      this.showIconPicker = false;
      return true;
    }
    return false;
  }

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Row() {
          Image(IconConstants.IC_CHEVRON_LEFT)
            .width(22)
            .height(22)
            .fillColor(this.getColors().accentBlue)
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })

          Text('确认令牌信息')
            .fontSize(17)
            .fontWeight(700)
            .fontColor(this.getColors().textPrimary)
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
            .margin({ left: 10 })

          Button('保存')
            .backgroundColor(this.getColors().successGreen)
            .borderRadius(10)
            .fontSize(14)
            .fontWeight(600)
            .fontColor(this.getColors().white)
            .padding({ top: 7, bottom: 7, left: 18, right: 18 })
            .onClick(() => {
              this.handleSave();
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12, left: 16, right: 16 })
        .backgroundColor(this.getColors().pageBackground)

        Scroll() {
          Column() {
            Column() {
              Stack({ alignContent: Alignment.Center }) {
                if (this.icon.length > 0) {
                  Image($r('app.media.' + this.icon))
                    .width(48)
                    .height(48)
                    .objectFit(ImageFit.Contain)
                } else {
                  Text(this.getInitial())
                    .fontSize(26)
                    .fontWeight(700)
                    .fontColor(this.getColors().white)
                }
              }
              .width(76)
              .height(76)
              .borderRadius(20)
              .backgroundColor(this.icon.length > 0 ? this.getColors().cardBackground : this.getColors().accentBlue)
              .border({
                width: this.icon.length > 0 ? 1 : 0,
                color: this.getColors().divider,
                style: BorderStyle.Dashed
              })

              Text(this.icon.length > 0 ? '点击更换图标' : '点击选择图标')
                .fontSize(11)
                .fontColor(this.getColors().textTertiary)
                .margin({ top: 8 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 22 })
            .onClick(() => {
              this.showIconPicker = true;
            })

            Column() {
              Text('发行方')
                .fontSize(12)
                .fontWeight(600)
                .fontColor(this.getColors().textSecondary)
                .padding({ left: 4 })
                .margin({ bottom: 6 })

              TextInput({ placeholder: '', text: this.issuer })
                .width('100%')
                .backgroundColor(this.getColors().cardBackground)
                .borderRadius(12)
                .border({ width: 1.5, color: this.getColors().divider })
                .padding({ top: 12, bottom: 12, left: 14, right: 14 })
                .fontSize(15)
                .fontWeight(500)
                .fontColor(this.getColors().textPrimary)
                .onChange((value: string) => {
                  this.issuer = value;
                })
            }
            .width('100%')
            .margin({ bottom: 12 })

            Column() {
              Text('账户名')
                .fontSize(12)
                .fontWeight(600)
                .fontColor(this.getColors().textSecondary)
                .padding({ left: 4 })
                .margin({ bottom: 6 })

              TextInput({ placeholder: '', text: this.account })
                .width('100%')
                .backgroundColor(this.getColors().cardBackground)
                .borderRadius(12)
                .border({ width: 1.5, color: this.getColors().divider })
                .padding({ top: 12, bottom: 12, left: 14, right: 14 })
                .fontSize(15)
                .fontWeight(500)
                .fontColor(this.getColors().textPrimary)
                .onChange((value: string) => {
                  this.account = value;
                })
            }
            .width('100%')
            .margin({ bottom: 12 })

            Column() {
              Text('密钥')
                .fontSize(12)
                .fontWeight(600)
                .fontColor(this.getColors().textSecondary)
                .padding({ left: 4 })
                .margin({ bottom: 6 })

              Row() {
                Text(this.showKey ? this.secretKey : '••••••••••••••••')
                  .fontSize(14)
                  .fontColor(this.showKey ? this.getColors().textPrimary : this.getColors().textTertiary)
                  .layoutWeight(1)

                Row({ space: 10 }) {
                  Image(IconConstants.IC_EYE)
                    .width(16)
                    .height(16)
                    .fillColor(this.getColors().textSecondary)
                    .onClick(() => {
                      this.showKey = !this.showKey;
                    })

                  Image(IconConstants.IC_COPY)
                    .width(16)
                    .height(16)
                    .fillColor(this.getColors().accentBlue)
                    .onClick(() => {
                      this.copySecret();
                    })
                }
              }
              .width('100%')
              .backgroundColor(this.getColors().cardBackground)
              .borderRadius(12)
              .border({ width: 1.5, color: this.getColors().divider })
              .padding({ top: 12, bottom: 12, left: 14, right: 14 })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Column() {
              Text('协议信息（自动识别）')
                .fontSize(12)
                .fontWeight(600)
                .fontColor(this.getColors().textSecondary)
                .padding({ left: 4 })
                .margin({ bottom: 6 })

              Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
                Text(this.parsedToken.type.length > 0 ? this.parsedToken.type : 'TOTP')
                  .fontSize(12)
                  .fontWeight(600)
                  .fontColor(this.getColors().accentBlue)
                  .padding({ top: 3, bottom: 3, left: 10, right: 10 })
                  .borderRadius(6)
                  .backgroundColor(this.getColors().blueBackground)
                  .margin({ right: 8, bottom: 4 })

                Text(this.parsedToken.algorithm.length > 0 ? this.parsedToken.algorithm : 'SHA-1')
                  .fontSize(12)
                  .fontWeight(500)
                  .fontColor(this.getColors().textPrimary)
                  .padding({ top: 3, bottom: 3, left: 10, right: 10 })
                  .borderRadius(6)
                  .backgroundColor(this.getColors().buttonGray)
                  .margin({ right: 8, bottom: 4 })

                Text((this.parsedToken.digits > 0 ? this.parsedToken.digits : 6).toString() + '位')
                  .fontSize(12)
                  .fontWeight(500)
                  .fontColor(this.getColors().textPrimary)
                  .padding({ top: 3, bottom: 3, left: 10, right: 10 })
                  .borderRadius(6)
                  .backgroundColor(this.getColors().buttonGray)
                  .margin({ right: 8, bottom: 4 })

                Text((this.parsedToken.period > 0 ? this.parsedToken.period : 30).toString() + 's')
                  .fontSize(12)
                  .fontWeight(500)
                  .fontColor(this.getColors().textPrimary)
                  .padding({ top: 3, bottom: 3, left: 10, right: 10 })
                  .borderRadius(6)
                  .backgroundColor(this.getColors().buttonGray)
                  .margin({ right: 8, bottom: 4 })
              }
              .width('100%')
              .backgroundColor(this.getColors().cardBackground)
              .borderRadius(12)
              .border({ width: 1, color: this.getColors().tagUnselectedBackground })
              .padding({ top: 10, bottom: 10, left: 14, right: 14 })
            }
            .width('100%')
            .margin({ bottom: 12 })

            Column() {
              Text('分类标签')
                .fontSize(12)
                .fontWeight(600)
                .fontColor(this.getColors().textSecondary)
                .padding({ left: 4 })
                .margin({ bottom: 8 })

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
                      width: 1,
                      color: this.tagSelections[index] ? (this.isDarkMode ? '#FFFFFF' : '#1F2937') : this.tagColors[index]
                    })
                    .opacity(1)
                    .margin({ right: 8, bottom: 8 })
                    .onClick(() => {
                      const newSelections: boolean[] = [...this.tagSelections];
                      newSelections[index] = !newSelections[index];
                      this.tagSelections = newSelections;
                    })
                }, (tag: string) => tag)
              }
              .width('100%')
            }
            .width('100%')
          }
          .width('100%')
          .padding({ top: 0, left: 20, right: 20, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getColors().pageBackground)

      // Icon Picker
      IconPickerPanel({
        visible: this.showIconPicker,
        selected: this.icon,
        onSelect: (name: string): void => {
          this.icon = name;
        },
        onClose: (): void => {
          this.showIconPicker = false;
        }
      })

      // Loading overlay
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.getColors().accentBlue)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('rgba(0,0,0,0.3)')
      }

      // Toast overlay
      if (this.toastVisible) {
        Row() {
          Text(this.toastMessage)
            .fontSize(14)
            .fontWeight(500)
            .fontColor(this.getColors().white)
            .padding({ top: 10, bottom: 10, left: 20, right: 20 })
            .backgroundColor('rgba(0,0,0,0.8)')
            .borderRadius(22)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .position({ top: 44 })
      }
    }
    .width('100%')
    .height('100%')
  }

  // --- Save logic ---

  private handleSave(): void {
    const issuerTrimmed: string = this.issuer.trim();
    const accountTrimmed: string = this.account.trim();
    const secretTrimmed: string = this.secretKey.trim().toUpperCase();

    if (issuerTrimmed.length === 0) {
      this.showToastMsg('请输入发行方');
      return;
    }
    if (accountTrimmed.length === 0) {
      this.showToastMsg('请输入账户名');
      return;
    }
    if (secretTrimmed.length === 0) {
      this.showToastMsg('密钥不能为空');
      return;
    }

    this.loading = true;
    const token: TokenModel = TokenModel.create(issuerTrimmed, accountTrimmed, secretTrimmed);
    token.type = this.parsedToken.type.length > 0 ? this.parsedToken.type : 'TOTP';
    token.algorithm = this.parsedToken.algorithm.length > 0 ? this.parsedToken.algorithm : 'SHA-1';
    token.digits = this.parsedToken.digits > 0 ? this.parsedToken.digits : 6;
    token.period = this.parsedToken.period > 0 ? this.parsedToken.period : 30;
    token.counter = this.parsedToken.counter;

    const selectedTags: string[] = [];
    for (let i: number = 0; i < this.tagSelections.length; i++) {
      if (this.tagSelections[i]) {
        selectedTags.push(this.tagNames[i]);
      }
    }
    token.tags = selectedTags;
    token.icon = this.icon;
    token.iconColor = this.getIconColor(issuerTrimmed);

    TokenStorage.save(token).then((): void => {
      this.loading = false;
      this.showToastMsg('令牌已添加 ✓');
      setTimeout(() => {
        this.getUIContext().getRouter().back();
      }, 800);
    });
  }

  private copySecret(): void {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.secretKey);
    const sysBoard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    sysBoard.setData(data);
    this.showToastMsg('密钥已复制 ✓');
  }

  private getIconColor(issuer: string): string {
    const colors: string[] = ['#4285F4', '#34C759', '#FF9500', '#A855F7', '#FF3B30', '#007AFF', '#FF2D55', '#5856D6'];
    let hash: number = 0;
    for (let i: number = 0; i < issuer.length; i++) {
      hash = issuer.charCodeAt(i) + ((hash << 5) - hash);
    }
    const index: number = Math.abs(hash) % colors.length;
    return colors[index];
  }

  private showToastMsg(msg: string): void {
    this.toastMessage = msg;
    this.toastVisible = true;
    setTimeout(() => {
      this.toastVisible = false;
    }, 2000);
  }

  private async loadTags(): Promise<void> {
    const savedTags: TagModel[] = await TagStorage.getAll();
    const names: string[] = [];
    const selections: boolean[] = [];
    const colors: string[] = [];
    for (let i: number = 0; i < savedTags.length; i++) {
      names.push(savedTags[i].name);
      selections.push(false);
      colors.push(savedTags[i].color);
    }
    this.tagNames = names;
    this.tagSelections = selections;
    this.tagColors = colors;
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
