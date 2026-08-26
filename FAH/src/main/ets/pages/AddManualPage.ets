import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { IconPickerPanel } from '../components/IconPicker';
import { TokenModel } from '../model/TokenModel';
import { TokenStorage } from '../storage/TokenStorage';
import { TagStorage } from '../storage/TagStorage';
import { TagModel } from '../model/TagModel';
import { ClipboardUtil } from '../utils/ClipboardUtil';
import { PickerPanel, PickerOption } from '../components/PickerPanel';

@Entry
@Component
struct AddManualPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State issuer: string = '';
  @State account: string = '';
  @State icon: string = '';
  @State secretKey: string = '';
  @State protocolType: string = 'TOTP';
  @State algorithm: string = 'SHA-1';
  @State digits: string = '6';
  @State period: string = '30';
  @State tagSelections: boolean[] = [];
  @State tagNames: string[] = [];
  @State tagColors: string[] = [];
  @State toastMessage: string = '';
  @State toastVisible: boolean = false;
  @State showAppearancePicker: boolean = false;
  @State showProtocolPicker: boolean = false;
  @State showAlgorithmPicker: boolean = false;
  @State showDigitsPicker: boolean = false;
  @State showPeriodPicker: boolean = false;
  @State showIconPicker: boolean = false;

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
  }

  private buildProtocolOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: 'TOTP', value: 'TOTP', description: this.str($r('app.string.protocol_totp_desc')) },
      { label: 'HOTP', value: 'HOTP', description: this.str($r('app.string.protocol_hotp_desc')) }
    ];
    return options;
  }

  private buildAlgorithmOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: 'SHA-1', value: 'SHA-1', description: this.str($r('app.string.algorithm_sha1_desc')) },
      { label: 'SHA-256', value: 'SHA-256', description: this.str($r('app.string.algorithm_sha256_desc')) },
      { label: 'SHA-512', value: 'SHA-512', description: this.str($r('app.string.algorithm_sha512_desc')) }
    ];
    return options;
  }

  private buildDigitsOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: '6 ' + this.str($r('app.string.unit_digits')), value: '6', description: this.str($r('app.string.digits_6_desc')) },
      { label: '8 ' + this.str($r('app.string.unit_digits')), value: '8', description: this.str($r('app.string.digits_8_desc')) }
    ];
    return options;
  }

  private buildPeriodOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: '30 ' + this.str($r('app.string.unit_seconds')), value: '30', description: this.str($r('app.string.period_30_desc')) },
      { label: '60 ' + this.str($r('app.string.unit_seconds')), value: '60', description: this.str($r('app.string.period_60_desc')) }
    ];
    return options;
  }

  aboutToAppear(): void {
    TagStorage.init(this.getUIContext().getHostContext()!);
    this.loadTags();
  }

  onBackPress(): boolean {
    if (this.showIconPicker || this.showProtocolPicker || this.showAlgorithmPicker ||
      this.showDigitsPicker || this.showPeriodPicker) {
      this.showIconPicker = false;
      this.showProtocolPicker = false;
      this.showAlgorithmPicker = false;
      this.showDigitsPicker = false;
      this.showPeriodPicker = false;
      return true;
    }
    return false;
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

          Text($r('app.string.add_token_manual'))
            .fontSize(17)
            .fontWeight(700)
            .fontColor(this.getColors().textPrimary)
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
            .margin({ left: 10 })

          Text($r('app.string.button_save'))
            .fontSize(15)
            .fontWeight(600)
            .fontColor(this.getColors().accentBlue)
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

              Text(this.icon.length > 0 ? $r('app.string.manual_change_icon') : $r('app.string.manual_select_icon'))
                .fontSize(11)
                .fontColor(this.getColors().textTertiary)
                .margin({ top: 8 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 20 })
            .onClick(() => {
              this.showIconPicker = true;
            })

            Column() {
              Row() {
                Text($r('app.string.field_issuer'))
                  .fontSize(12)
                  .fontWeight(600)
                  .fontColor(this.getColors().textSecondary)
                Text(' *')
                  .fontSize(12)
                  .fontColor(this.getColors().dangerRed)
              }
              .padding({ left: 4 })
              .margin({ bottom: 6 })

              TextInput({ placeholder: $r('app.string.placeholder_issuer'), text: this.issuer })
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
            .margin({ bottom: 14 })

            Column() {
              Row() {
                Text($r('app.string.field_account'))
                  .fontSize(12)
                  .fontWeight(600)
                  .fontColor(this.getColors().textSecondary)
                Text(' *')
                  .fontSize(12)
                  .fontColor(this.getColors().dangerRed)
              }
              .padding({ left: 4 })
              .margin({ bottom: 6 })

              TextInput({ placeholder: $r('app.string.placeholder_account'), text: this.account })
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
            .margin({ bottom: 14 })

            Column() {
              Row() {
                Text($r('app.string.field_secret'))
                  .fontSize(12)
                  .fontWeight(600)
                  .fontColor(this.getColors().textSecondary)
                Text(' *')
                  .fontSize(12)
                  .fontColor(this.getColors().dangerRed)
              }
              .padding({ left: 4 })
              .margin({ bottom: 6 })

              TextInput({ placeholder: '', text: this.secretKey })
                .width('100%')
                .backgroundColor(this.getColors().cardBackground)
                .borderRadius(12)
                .border({ width: 1.5, color: this.getColors().divider })
                .padding({ top: 12, bottom: 12, left: 14, right: 14 })
                .fontSize(15)
                .fontWeight(500)
                .fontColor(this.getColors().textPrimary)
                .onChange((value: string) => {
                  this.secretKey = value;
                })

              Row() {
                Text($r('app.string.secret_hint'))
                  .fontSize(10)
                  .fontColor(this.getColors().textTertiary)
                  .layoutWeight(1)

                Text($r('app.string.action_paste'))
                  .fontSize(10)
                  .fontColor(this.getColors().accentBlue)
                  .fontWeight(600)
                  .onClick(() => {
                    this.handlePaste();
                  })
              }
              .width('100%')
              .padding({ top: 3, left: 4, right: 4 })
            }
            .width('100%')
            .margin({ bottom: 14 })

            Column() {
              Row() {
                Text($r('app.string.advanced_options'))
                  .fontSize(13)
                  .fontWeight(600)
                  .fontColor(this.getColors().accentBlue)
                  .margin({ left: 6 })
              }
              .padding({ top: 6, bottom: 6, left: 4, right: 4 })

              Column() {
                Row() {
                  Text($r('app.string.field_protocol'))
                    .fontSize(13)
                    .fontColor(this.getColors().textSecondary)
                    .layoutWeight(1)

                  Row({ space: 4 }) {
                    Text(this.protocolType)
                      .fontSize(13)
                      .fontWeight(600)
                      .fontColor(this.getColors().textPrimary)
                    Text('▼')
                      .fontSize(10)
                      .fontColor(this.getColors().textSecondary)
                  }
                  .onClick(() => {
                    this.showProtocolPicker = true;
                  })
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .border({ width: { bottom: 1 }, color: this.getColors().divider })

                Row() {
                  Text($r('app.string.field_algorithm'))
                    .fontSize(13)
                    .fontColor(this.getColors().textSecondary)
                    .layoutWeight(1)

                  Row({ space: 4 }) {
                    Text(this.algorithm)
                      .fontSize(13)
                      .fontWeight(600)
                      .fontColor(this.getColors().textPrimary)
                    Text('▼')
                      .fontSize(10)
                      .fontColor(this.getColors().textSecondary)
                  }
                  .onClick(() => {
                    this.showAlgorithmPicker = true;
                  })
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .border({ width: { bottom: 1 }, color: this.getColors().divider })

                Row() {
                  Text($r('app.string.field_digits'))
                    .fontSize(13)
                    .fontColor(this.getColors().textSecondary)
                    .layoutWeight(1)

                  Row({ space: 4 }) {
                    Text(this.digits + this.str($r('app.string.unit_digits')))
                      .fontSize(13)
                      .fontWeight(600)
                      .fontColor(this.getColors().textPrimary)
                    Text('▼')
                      .fontSize(10)
                      .fontColor(this.getColors().textSecondary)
                  }
                  .onClick(() => {
                    this.showDigitsPicker = true;
                  })
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .border({ width: { bottom: 1 }, color: this.getColors().divider })

                Row() {
                  Text(this.protocolType === 'HOTP' ? $r('app.string.field_counter') : $r('app.string.field_period'))
                    .fontSize(13)
                    .fontColor(this.getColors().textSecondary)
                    .layoutWeight(1)

                  Row({ space: 4 }) {
                    Text(this.protocolType === 'HOTP' ? '0' : (this.period + this.str($r('app.string.unit_seconds'))))
                      .fontSize(13)
                      .fontWeight(600)
                      .fontColor(this.getColors().textPrimary)
                    if (this.protocolType === 'TOTP') {
                      Text('▼')
                        .fontSize(10)
                        .fontColor(this.getColors().textSecondary)
                    }
                  }
                  .onClick(() => {
                    if (this.protocolType === 'TOTP') {
                      this.showPeriodPicker = true;
                    }
                  })
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
              }
              .width('100%')
              .backgroundColor(this.getColors().cardBackground)
              .borderRadius(12)
              .border({ width: 1, color: this.getColors().tagUnselectedBackground })
              .padding({ top: 4, left: 14, right: 14 })
            }
            .width('100%')
            .margin({ bottom: 14 })

            Column() {
              Text($r('app.string.field_tags'))
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
          .padding({ top: 4, left: 20, right: 20, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getColors().pageBackground)

      // Protocol Picker
      PickerPanel({
        title: this.str($r('app.string.picker_protocol')),
        visible: this.showProtocolPicker,
        selectedValue: this.protocolType,
        options: this.buildProtocolOptions(),
        onSelect: (value: string): void => {
          this.protocolType = value;
          this.showProtocolPicker = false;
        },
        onClose: (): void => {
          this.showProtocolPicker = false;
        }
      })

      // Algorithm Picker
      PickerPanel({
        title: this.str($r('app.string.picker_algorithm')),
        visible: this.showAlgorithmPicker,
        selectedValue: this.algorithm,
        options: this.buildAlgorithmOptions(),
        onSelect: (value: string): void => {
          this.algorithm = value;
          this.showAlgorithmPicker = false;
        },
        onClose: (): void => {
          this.showAlgorithmPicker = false;
        }
      })

      // Digits Picker
      PickerPanel({
        title: this.str($r('app.string.picker_digits')),
        visible: this.showDigitsPicker,
        selectedValue: this.digits,
        options: this.buildDigitsOptions(),
        onSelect: (value: string): void => {
          this.digits = value;
          this.showDigitsPicker = false;
        },
        onClose: (): void => {
          this.showDigitsPicker = false;
        }
      })

      // Period Picker
      PickerPanel({
        title: this.str($r('app.string.picker_period')),
        visible: this.showPeriodPicker,
        selectedValue: this.period,
        options: this.buildPeriodOptions(),
        onSelect: (value: string): void => {
          this.period = value;
          this.showPeriodPicker = false;
        },
        onClose: (): void => {
          this.showPeriodPicker = false;
        }
      })

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
      this.showToastMsg(this.str($r('app.string.toast_enter_issuer')));
      return;
    }
    if (accountTrimmed.length === 0) {
      this.showToastMsg(this.str($r('app.string.toast_enter_account')));
      return;
    }
    if (secretTrimmed.length === 0) {
      this.showToastMsg(this.str($r('app.string.toast_enter_secret')));
      return;
    }

    const base32Regex: RegExp = /^[A-Z2-7]+=*$/;
    if (!base32Regex.test(secretTrimmed)) {
      this.showToastMsg(this.str($r('app.string.toast_invalid_secret')));
      return;
    }

    const token: TokenModel = TokenModel.create(issuerTrimmed, accountTrimmed, secretTrimmed);
    token.type = this.protocolType;
    token.algorithm = this.algorithm;
    token.digits = parseInt(this.digits);
    token.period = parseInt(this.period);
    token.counter = 0;

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
      this.showToastMsg(this.str($r('app.string.toast_token_added')));
      setTimeout(() => {
        this.getUIContext().getRouter().back();
      }, 800);
    });
  }

  private handlePaste(): void {
    ClipboardUtil.paste().then((text: string): void => {
      if (text.length > 0) {
        this.secretKey = text.toUpperCase();
      }
    });
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
