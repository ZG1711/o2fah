import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';

interface FaqItem {
  emoji: string;
  title: string;
  subtitle: string;
  answer: string;
}

interface GuideItem {
  emoji: string;
  title: string;
  content: string;
}

@Entry
@Component
struct HelpFeedbackPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State faqExpanded: boolean[] = [false, false, false, false, false];
  @State guideExpanded: boolean[] = [false, false, false];
  @State selectedFeedbackType: number = 0;
  @State feedbackContent: string = '';
  @State feedbackEmail: string = '';

  private feedbackTypes: string[] = ['全部', '功能建议', '问题报告', '其他'];

  private faqItems: FaqItem[] = [
    {
      emoji: '🔑',
      title: '如何添加两步验证令牌？',
      subtitle: '扫码、相册识别或手动输入密钥',
      answer: '有三种方式：1. 扫描二维码 — 点击 + 按钮，选择「扫描二维码」 2. 从相册选取 — 通过相册导入 QR 码截图 3. 手动输入 — 手动填写发行方、账户名和密钥。💡 提示：建议直接扫码添加'
    } as FaqItem,
    {
      emoji: '🔄',
      title: 'TOTP 和 HOTP 有什么区别？',
      subtitle: '基于时间 vs 基于计数器',
      answer: 'TOTP (Time-based OTP) 基于当前时间生成验证码，每30或60秒自动刷新。HOTP (HMAC-based OTP) 基于计数器，每次使用后手动触发递增。大多数服务使用 TOTP。'
    } as FaqItem,
    {
      emoji: '💾',
      title: '如何备份令牌数据？',
      subtitle: '导出加密备份文件安全存储',
      answer: '进入设置 > 导出加密备份，设置备份密码后导出 .o2fah 文件。请将备份文件保存在安全位置。建议定期备份以防数据丢失。'
    } as FaqItem,
    {
      emoji: '🔐',
      title: '生物识别锁定安全吗？',
      subtitle: '本地加密 + 系统级生物识别保护',
      answer: 'O2FAH 使用 HarmonyOS 系统级生物识别 API，所有数据存储在本地加密区域。密钥通过系统安全区域保护，不会上传到云端或与其他应用共享。'
    } as FaqItem,
    {
      emoji: '📱',
      title: '更换手机后如何迁移数据？',
      subtitle: '旧手机导出备份，新手机导入恢复',
      answer: '在旧手机上：设置 > 导出加密备份。在新手机上安装 O2FAH：设置 > 导入加密备份，选择备份文件并输入密码即可恢复所有令牌。'
    } as FaqItem
  ];

  private guideItems: GuideItem[] = [
    {
      emoji: '📖',
      title: '快速入门指南',
      content: 'O2FAH 是一款两步验证 (2FA) 令牌管理工具，兼容 TOTP 和 HOTP 协议。\n\n1. 添加令牌：点击主页面右下角 + 按钮，可通过扫描二维码、从相册识别或手动输入密钥三种方式添加。\n\n2. 查看验证码：令牌卡片会实时显示当前验证码及剩余有效时间，点击卡片可快速复制验证码。\n\n3. 整理管理：支持按分类标签筛选、长按拖拽排序、左滑编辑/删除令牌。'
    } as GuideItem,
    {
      emoji: '🏷️',
      title: '如何使用分类标签',
      content: '分类标签帮助你更好地组织和查找令牌。\n\n1. 创建标签：在设置 > 管理分类标签中创建自定义标签，可设置名称和颜色。\n\n2. 分配标签：编辑令牌时可为其选择一个或多个标签。\n\n3. 筛选令牌：主页面顶部标签栏可快速按分类筛选，点击「全部」显示所有令牌。'
    } as GuideItem,
    {
      emoji: '🔄',
      title: '备份与恢复指南',
      content: '请定期备份令牌数据以防丢失。\n\n1. 导出备份：设置 > 导出加密备份，设置备份密码后生成 .o2fah 加密文件，建议保存到安全位置（如电脑或云盘）。\n\n2. 导入恢复：在新设备上打开设置 > 导入加密备份，选择备份文件并输入密码即可恢复所有令牌。\n\n3. 备份提醒：可在设置中开启定期备份提醒，避免遗忘。'
    } as GuideItem
  ];

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  getInputBg(): string {
    if (this.isDarkMode) {
      return this.getColors().buttonGray;
    }
    return this.getColors().pageBackground;
  }

  getTagUnselectedBg(): string {
    if (this.isDarkMode) {
      return this.getColors().buttonGray;
    }
    return this.getColors().tagUnselectedBackground;
  }

  getAnswerTextColor(): string {
    if (this.isDarkMode) {
      return '#AEAEB2';
    }
    return '#555555';
  }

  build() {
    Column() {
      // Navbar
      Row() {
        Image(IconConstants.IC_CHEVRON_LEFT)
          .width(22)
          .height(22)
          .margin({ left: 16, top: 8, bottom: 12 })
          .fillColor("#4285F4")
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('设置')
          .fontSize(16)
          .fontColor('#4285F4')
          .padding({ right: 4, top: 8, bottom: 12 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text('帮助与反馈')
          .fontSize(17)
          .fontWeight(700)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 12 })

        Text('')
          .width(60)
          .padding({ top: 8, bottom: 12 })
      }
      .width('100%')

      Scroll() {
        Column() {
          // ===================== Section 1: FAQ =====================
          this.SectionHeader('常见问题')

          Column() {
            ForEach(this.faqItems, (item: FaqItem, index: number) => {
              Column() {
                // FAQ row
                Row() {
                  Text(item.emoji)
                    .fontSize(16)

                  Column() {
                    Text(item.title)
                      .fontSize(15)
                      .fontWeight(500)
                      .fontColor(this.getColors().textPrimary)
                    Text(item.subtitle)
                      .fontSize(12)
                      .fontColor(this.getColors().textSecondary)
                  }
                  .layoutWeight(1)
                  .margin({ left: 10 })

                  Image(IconConstants.IC_CHEVRON_RIGHT)
                    .width(16)
                    .height(16)
                    .rotate({ angle: this.faqExpanded[index] ? 90 : 0 })
                    .fillColor(this.getColors().chevronColor)
                    .animation({ duration: 200 })
                }
                .width('100%')
                .padding({
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: this.faqExpanded[index] ? 0 : 14
                })
                .onClick(() => {
                  const newExpanded: boolean[] = [...this.faqExpanded];
                  newExpanded[index] = !newExpanded[index];
                  this.faqExpanded = newExpanded;
                })

                // Expanded answer content
                if (this.faqExpanded[index]) {
                  Text(item.answer)
                    .fontSize(14)
                    .fontColor(this.getAnswerTextColor())
                    .lineHeight(24)
                    .width('100%')
                    .padding({ left: 30, right: 16, top: 8, bottom: 14 })
                    .animation({ duration: 250, curve: Curve.EaseOut })
                }

                // Divider between items (not after last)
                if (index < this.faqItems.length - 1) {
                  Divider()
                    .height(0.5)
                    .color(this.getColors().divider)
                    .width('100%')
                }
              }
              .width('100%')
            }, (item: FaqItem, index: number) => index.toString())
          }
          .width('100%')
          .backgroundColor(this.getColors().cardBackground)
          .borderRadius(12)
          .margin({ top: 6 })

          // ===================== Section 2: User Guide =====================
          this.SectionHeader('使用指南')

          Column() {
            ForEach(this.guideItems, (item: GuideItem, index: number) => {
              Column() {
                Row() {
                  Text(item.emoji)
                    .fontSize(16)

                  Text(item.title)
                    .fontSize(15)
                    .fontWeight(500)
                    .fontColor(this.getColors().textPrimary)
                    .layoutWeight(1)
                    .margin({ left: 10 })

                  Image(IconConstants.IC_CHEVRON_RIGHT)
                    .width(16)
                    .height(16)
                    .rotate({ angle: this.guideExpanded[index] ? 90 : 0 })
                    .fillColor(this.getColors().chevronColor)
                    .animation({ duration: 200 })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: this.guideExpanded[index] ? 0 : 14 })
                .onClick(() => {
                  const newExpanded: boolean[] = [...this.guideExpanded];
                  newExpanded[index] = !newExpanded[index];
                  this.guideExpanded = newExpanded;
                })

                if (this.guideExpanded[index]) {
                  Text(item.content)
                    .fontSize(14)
                    .fontColor(this.getAnswerTextColor())
                    .lineHeight(24)
                    .width('100%')
                    .padding({ left: 30, right: 16, top: 8, bottom: 14 })
                    .animation({ duration: 250, curve: Curve.EaseOut })
                }

                // Divider between items (not after last)
                if (index < this.guideItems.length - 1) {
                  Divider()
                    .height(0.5)
                    .color(this.getColors().divider)
                    .width('100%')
                }
              }
              .width('100%')
            }, (item: GuideItem, index: number) => index.toString())
          }
          .width('100%')
          .backgroundColor(this.getColors().cardBackground)
          .borderRadius(12)
          .margin({ top: 6 })

          // ===================== Section 3: Feedback Form =====================
          // this.SectionHeader('问题反馈')

          // Column() {
          //   // Feedback type label
          //   Text('反馈类型')
          //     .fontSize(14)
          //     .fontColor(this.getColors().textSecondary)
          //     .width('100%')
          //     .padding({ bottom: 10 })
          //
          //   // Feedback type tags
          //   Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
          //     ForEach(this.feedbackTypes, (type: string, index: number) => {
          //       Text(type)
          //         .fontSize(13)
          //         .fontWeight(index === this.selectedFeedbackType ? 600 : 500)
          //         .fontColor(index === this.selectedFeedbackType ? '#FFFFFF' : this.getColors().textPrimary)
          //         .backgroundColor(index === this.selectedFeedbackType ? '#4285F4' : this.getTagUnselectedBg())
          //         .borderRadius(16)
          //         .padding({ top: 7, bottom: 7, left: 16, right: 16 })
          //         .margin({ right: 8, bottom: 8 })
          //         .onClick(() => {
          //           this.selectedFeedbackType = index;
          //         })
          //     }, (type: string, index: number) => index.toString())
          //   }
          //   .width('100%')
          //   .margin({ bottom: 16 })
          //
          //   // TextArea for feedback content
          //   TextArea({ placeholder: '请描述您的问题或建议…', text: this.feedbackContent })
          //     .backgroundColor(this.getInputBg())
          //     .borderRadius(10)
          //     .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          //     .constraintSize({ minHeight: 100 })
          //     .width('100%')
          //     .margin({ bottom: 12 })
          //     .onChange((value: string) => {
          //       this.feedbackContent = value;
          //     })
          //
          //   // Email input row
          //   Row() {
          //     Text('📧 联系方式 (选填)')
          //       .fontSize(13)
          //       .fontColor(this.getColors().textSecondary)
          //
          //     TextInput({ placeholder: 'your@email.com', text: this.feedbackEmail })
          //       .backgroundColor(this.getInputBg())
          //       .borderRadius(10)
          //       .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          //       .layoutWeight(1)
          //       .margin({ left: 10 })
          //       .onChange((value: string) => {
          //         this.feedbackEmail = value;
          //       })
          //   }
          //   .width('100%')
          //   .alignItems(VerticalAlign.Center)
          //   .margin({ bottom: 16 })
          //
          //   // Submit button
          //   Button() {
          //     Text('提交反馈')
          //       .fontSize(16)
          //       .fontWeight(600)
          //       .fontColor('#FFFFFF')
          //   }
          //   .width('100%')
          //   .padding({ top: 14, bottom: 14 })
          //   .backgroundColor('#4285F4')
          //   .borderRadius(12)
          //   .onClick(() => {
          //     this.getUIContext().getPromptAction().showToast({ message: '感谢反馈！' });
          //     this.feedbackContent = '';
          //     this.feedbackEmail = '';
          //     this.selectedFeedbackType = 0;
          //   })
          //
          //   // Privacy note
          //   Text('提交即表示同意收集上述信息用于改进产品')
          //     .fontSize(11)
          //     .fontColor(this.getColors().textTertiary)
          //     .width('100%')
          //     .textAlign(TextAlign.Center)
          //     .margin({ top: 8 })
          // }
          // .width('100%')
          // .backgroundColor(this.getColors().cardBackground)
          // .borderRadius(12)
          // .padding(16)
          // .margin({ top: 6 })

          // Bottom spacer
          Column()
            .height(40)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getColors().pageBackground)
  }

  @Builder
  SectionHeader(title: string): void {
    Text(title)
      .fontSize(12)
      .fontWeight(600)
      .fontColor(this.getColors().textSecondary)
      .padding({ left: 4, bottom: 6 })
      .width('100%')
      .margin({ top: 24 })
  }
}
