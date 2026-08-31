import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { bundleManager } from '@kit.AbilityKit';

interface LibInfo {
  name: string;
  desc: string;
  license: string;
}

@Entry
@Component
struct AboutPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State clickCount: number = 0;
  @State version: string = ""
  @State packName: string = ""
  @State minCompatibleVersionCode: number = 0
  @State targetVersion: number = 0

  aboutToAppear(): void {
    this.getBundleInfoForSelf()
    this.libItems[0].desc = this.str($r('app.string.about_lib_sdk_desc'));
  }
  private libItems: LibInfo[] = [
    { name: 'HarmonyOS SDK', desc: '', license: '-' } as LibInfo,
    { name: "Simple-icons", desc: 'Icon SVG', license: 'CC0-1.0' } as LibInfo
  ];

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
  }

  getCapsuleBgLight(): string {
    return '#E8F0FE';
  }

  getCapsuleTextBlue(): string {
    return '#4285F4';
  }

  getCapsuleBgDark(): string {
    return '#1A3454';
  }

  getGrayCapsuleBg(): string {
    if (this.isDarkMode) {
      return '#2C2C2E';
    }
    return '#F0F0F0';
  }

  getGrayCapsuleText(): string {
    if (this.isDarkMode) {
      return '#8E8E93';
    }
    return '#86868B';
  }

  getGreenText(): string {
    return '#34C759';
  }

  getFooterPrimary(): string {
    if (this.isDarkMode) {
      return '#8E8E93';
    }
    return '#AEAEB2';
  }

  getFooterSecondary(): string {
    if (this.isDarkMode) {
      return '#636366';
    }
    return '#C7C7CC';
  }

  async getBundleInfoForSelf(){
    await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .then((bundleInfo) => {
        this.version = bundleInfo.versionName
        this.packName = bundleInfo.name;
        this.minCompatibleVersionCode = bundleInfo.minCompatibleVersionCode;
        this.targetVersion = bundleInfo.targetVersion;
      })
      .catch(() => {
        this.version = this.str($r('app.string.set_version_failed'));
        this.packName = this.str($r('app.string.about_pack_failed'));
      });
  }

  getTagBgColor(): string {
    if (this.isDarkMode) {
      return this.getCapsuleBgDark();
    }
    return this.getCapsuleBgLight();
  }

  build() {
    Column() {
      // ===================== Navbar =====================
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

        Text($r('app.string.settings_about'))
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
          // ===================== App Identity =====================
          Column() {
            Column() {
              Image($r('app.media.startIcon'))
                .width(80)
                .height(80)
            }
            .width(80)
            .height(80)
            .borderRadius(22)
            .backgroundColor('#4285F4')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .shadow({
              radius: 16,
              color: 'rgba(66,133,244,0.3)',
              offsetY: 4
            })

            Text($r("app.string.app_name"))
              .fontSize(22)
              .fontWeight(700)
              .fontColor(this.getColors().textPrimary)
              .margin({ top: 14 })

            Text($r('app.string.about_app_desc'))
              .fontSize(12)
              .fontColor('#AEAEB2')
              .margin({ top: 2 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 28, bottom: 24 })

          // ===================== Group 1: 应用信息 =====================
          this.SectionHeader(this.str($r('app.string.about_section_app_info')))
          Column() {
            this.InfoRow(this.str($r('app.string.about_app_name')), 'O2FAH', true)
            if (this.version)
              this.InfoRow(this.str($r('app.string.about_version_label')), this.version, true)
            this.InfoRow('Github', "https://github.com/ZG1711/o2fah", true)
            this.InfoRow('Gitee',"https://gitee.com/ZG1711/o2fah", true)
          }
          .width('100%')
          .backgroundColor(this.getColors().cardBackground)
          .borderRadius(12)
          .margin({ top: 6 })

          // ===================== Group 2: 技术信息 =====================
          this.SectionHeader(this.str($r('app.string.about_section_tech')))
          Column() {
            // 认证协议
            Row() {
              Text(this.str($r('app.string.about_protocol')))
                .fontSize(15)
                .fontColor(this.getColors().textPrimary)
                .layoutWeight(1)

              Row({ space: 4 }) {
                this.CapsuleTag('TOTP', true)
                this.CapsuleTag('HOTP', true)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })

            Divider().height(0.5).color(this.getColors().divider).width('100%')

            // 哈希算法
            Row() {
              Text(this.str($r('app.string.about_hash_algo')))
                .fontSize(15)
                .fontColor(this.getColors().textPrimary)
                .layoutWeight(1)

              Row({ space: 4 }) {
                this.CapsuleTag('SHA-1', true)
                this.CapsuleTag('SHA-256', true)
                this.CapsuleTag('SHA-512', true)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })

            Divider().height(0.5).color(this.getColors().divider).width('100%')

            // 数据存储
            Row() {
              Text(this.str($r('app.string.about_data_storage')))
                .fontSize(15)
                .fontColor(this.getColors().textPrimary)
                .layoutWeight(1)

              Text(this.str($r('app.string.about_storage_local')))
                .fontSize(15)
                .fontColor(this.getColors().textSecondary)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })

            Divider().height(0.5).color(this.getColors().divider).width('100%')

            // 网络权限
            Row() {
              Text(this.str($r('app.string.about_network')))
                .fontSize(15)
                .fontColor(this.getColors().textPrimary)
                .layoutWeight(1)

              Text(this.str($r('app.string.about_network_none')))
                .fontSize(12)
                .fontColor(this.getGrayCapsuleText())
                .backgroundColor(this.getGrayCapsuleBg())
                .borderRadius(6)
                .padding({ top: 3, bottom: 3, left: 10, right: 10 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          }
          .width('100%')
          .backgroundColor(this.getColors().cardBackground)
          .borderRadius(12)
          .margin({ top: 6 })

          // ===================== Group 3: 第三方开源库 =====================
          this.SectionHeader(this.str($r('app.string.about_section_libs')))
          Column() {
            ForEach(this.libItems, (item: LibInfo, index: number) => {
              Column() {
                Row() {
                  Column() {
                    Text(item.name)
                      .fontSize(15)
                      .fontWeight(500)
                      .fontColor(this.getColors().textPrimary)
                    Text(item.desc)
                      .fontSize(12)
                      .fontColor('#AEAEB2')
                  }
                  .layoutWeight(1)

                  Text(item.license)
                    .fontSize(12)
                    .fontColor(item.license === '—' ? this.getColors().textTertiary : this.getGreenText())
                    .fontWeight(500)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })

                if (index < this.libItems.length - 1) {
                  Divider().height(0.5).color(this.getColors().divider).width('100%')
                }
              }
              .width('100%')
            }, (item: LibInfo, index: number) => index.toString())
          }
          .width('100%')
          .backgroundColor(this.getColors().cardBackground)
          .borderRadius(12)
          .margin({ top: 6 })

          // ===================== Footer =====================
          Column() {
            Text($r('app.string.about_footer'))
              .fontSize(13)
              .fontColor(this.getFooterPrimary())
              .width('100%')
              .textAlign(TextAlign.Center)

            Text('© 2026 O2FAH. All rights reserved.')
              .fontSize(11)
              .fontColor(this.getFooterSecondary())
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 6 })
          }
          .width('100%')
          .padding({ top: 8, bottom: 32 })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
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
      .margin({ top: 20 })
  }

  @Builder
  InfoRow(label: string, value: string, showDivider: boolean): void {
    Column() {
      Row() {
        Text(label)
          .fontSize(15)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)

        Text(value)
          .fontSize(15)
          .fontColor(this.getColors().textSecondary)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })

      if (showDivider) {
        Divider().height(0.5).color(this.getColors().divider).width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  CapsuleTag(text: string, isBlue: boolean): void {
    Text(text)
      .fontSize(11)
      .fontColor(this.getCapsuleTextBlue())
      .fontWeight(500)
      .backgroundColor(this.getTagBgColor())
      .borderRadius(6)
      .padding({ top: 3, bottom: 3, left: 8, right: 8 })
  }
}
