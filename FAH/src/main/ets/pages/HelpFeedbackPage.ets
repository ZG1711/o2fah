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

  private getFaqItems(): FaqItem[] {
    const items: FaqItem[] = [
      {
        emoji: '🔑',
        title: this.str($r('app.string.faq1_title')),
        subtitle: this.str($r('app.string.faq1_subtitle')),
        answer: this.str($r('app.string.faq1_answer'))
      } as FaqItem,
      {
        emoji: '🔄',
        title: this.str($r('app.string.faq2_title')),
        subtitle: this.str($r('app.string.faq2_subtitle')),
        answer: this.str($r('app.string.faq2_answer'))
      } as FaqItem,
      {
        emoji: '💾',
        title: this.str($r('app.string.faq3_title')),
        subtitle: this.str($r('app.string.faq3_subtitle')),
        answer: this.str($r('app.string.faq3_answer'))
      } as FaqItem,
      {
        emoji: '🔐',
        title: this.str($r('app.string.faq4_title')),
        subtitle: this.str($r('app.string.faq4_subtitle')),
        answer: this.str($r('app.string.faq4_answer'))
      } as FaqItem,
      {
        emoji: '📱',
        title: this.str($r('app.string.faq5_title')),
        subtitle: this.str($r('app.string.faq5_subtitle')),
        answer: this.str($r('app.string.faq5_answer'))
      } as FaqItem
    ];
    return items;
  }

  private getGuideItems(): GuideItem[] {
    const items: GuideItem[] = [
      {
        emoji: '📖',
        title: this.str($r('app.string.guide1_title')),
        content: this.str($r('app.string.guide1_content'))
      } as GuideItem,
      {
        emoji: '🏷️',
        title: this.str($r('app.string.guide2_title')),
        content: this.str($r('app.string.guide2_content'))
      } as GuideItem,
      {
        emoji: '🔄',
        title: this.str($r('app.string.guide3_title')),
        content: this.str($r('app.string.guide3_content'))
      } as GuideItem
    ];
    return items;
  }

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
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
        Text($r('app.string.tab_settings'))
          .fontSize(16)
          .fontColor('#4285F4')
          .padding({ right: 4, top: 8, bottom: 12 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text($r('app.string.settings_help_feedback'))
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
          this.SectionHeader(this.str($r('app.string.section_faq')))

          Column() {
            ForEach(this.getFaqItems(), (item: FaqItem, index: number) => {
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
                if (index < this.getFaqItems().length - 1) {
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
          this.SectionHeader(this.str($r('app.string.section_guide')))

          Column() {
            ForEach(this.getGuideItems(), (item: GuideItem, index: number) => {
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
                if (index < this.getGuideItems().length - 1) {
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
        .height("100%")
        .padding({ left: 20, right: 20 })

      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
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
