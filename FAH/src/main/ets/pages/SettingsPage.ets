import { SettingsRow } from '../components/SettingsRow';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { PickerPanel, PickerOption } from '../components/PickerPanel';
import { ExportPasswordDialog } from '../components/dialogs/ExportPasswordDialog';
import { ImportPasswordDialog } from '../components/dialogs/ImportPasswordDialog';
import { ImportMergeDialog } from '../components/dialogs/ImportMergeDialog';
import { BackupExporter } from '../backup/BackupExporter';
import { BackupImporter, MergeResult } from '../backup/BackupImporter';
import { SettingsStorage } from '../storage/SettingsStorage';
import { TokenStorage } from '../storage/TokenStorage';
import { TagStorage } from '../storage/TagStorage';
import { TokenModel } from '../model/TokenModel';
import { AppSettings } from '../model/AppSettings';
import { BiometricUtil } from '../utils/BiometricUtil';
import { promptAction } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';

const AUTO_LOCK_OPTIONS: PickerOption[] = [
  { label: '立即', value: '0', description: '每次进入后台立即锁定' },
  { label: '15 秒', value: '15', description: '进入后台 15 秒后锁定' },
  { label: '30 秒', value: '30', description: '进入后台 30 秒后锁定' },
  { label: '1 分钟', value: '60', description: '进入后台 1 分钟后锁定' },
  { label: '5 分钟', value: '300', description: '进入后台 5 分钟后锁定' }
];

const BACKUP_REMINDER_OPTIONS: PickerOption[] = [
  { label: '从不', value: 'never', description: '不提醒，需要时手动备份' },
  { label: '每周', value: 'weekly', description: '每周提醒一次备份' },
  { label: '每月', value: 'monthly', description: '每月提醒一次备份' },
  { label: '每季度', value: 'quarterly', description: '每季度提醒一次备份' }
];

const APPEARANCE_OPTIONS: PickerOption[] = [
  { label: '浅色', value: 'light', description: '始终使用浅色主题', colorPreview: '#F5F5F7' },
  { label: '深色', value: 'dark', description: '始终使用深色主题', colorPreview: '#000000' },
  { label: '跟随系统', value: 'system', description: '自动匹配系统深色/浅色设置', colorPreview: '#E8E8ED' }
];

const SORT_OPTIONS: PickerOption[] = [
  { label: '手动拖动排序', value: 'manual', description: '按 sortOrder 字段，长按卡片拖拽调整' },
  { label: '按名称 A-Z', value: 'name', description: '按发行方字母升序' },
  { label: '按添加时间', value: 'created', description: '按添加时间倒序（最新在前）' },
  { label: '按最近使用', value: 'lastUsed', description: '按最近使用倒序（最近复制在前）' }
];

@Component
export struct SettingsPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('themeMode') themeMode: string = 'system';
  @State toastMessage: string = '';
  @State toastVisible: boolean = false;
  @State autoLockValue: number = 0;
  @State backupReminder: string = 'weekly';
  @State defaultSort: string = 'manual';
  @State biometricEnabled: boolean = true;
  @StorageLink('showAppearancePicker') showAppearancePicker: boolean = false;
  @StorageLink('showAutoLockPicker') showAutoLockPicker: boolean = false;
  @StorageLink('showBackupReminderPicker') showBackupReminderPicker: boolean = false;
  @StorageLink('showDefaultSortPicker') showDefaultSortPicker: boolean = false;
  @State importRetryCount: number = 0;
  @State importLocked: boolean = false;
  @State version: string = ""
  @State mergeResult: MergeResult = {
    newTokens: [],
    skippedCount: 0,
    addedCount: 0,
    totalAfter: 0
  };

  private exportDialogController: CustomDialogController = new CustomDialogController({
    builder: ExportPasswordDialog({
      isDark: this.isDarkMode,
      confirm: (password: string): void => {
        this.handleExport(password);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private importDialogController: CustomDialogController = new CustomDialogController({
    builder: ImportPasswordDialog({
      isDark: this.isDarkMode,
      confirm: (password: string): void => {
        this.handleImport(password);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private mergeDialogController: CustomDialogController = new CustomDialogController({
    builder: ImportMergeDialog({
      mergeResult: this.mergeResult,
      isDark: this.isDarkMode,
      confirm: (): void => {
        this.showToast('备份已导入 ✓', 2000);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear(): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    SettingsStorage.init(ctx);
    TokenStorage.init(ctx);
    this.loadSettings();
  }

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Stack() {
      Column() {
        Scroll() {
          Column() {
            this.SectionHeader('安全')
            Column() {
              SettingsRow({
                iconEmoji: this.biometricEnabled ? '🔐' : '🔓',
                iconBgColor: this.biometricEnabled ? '#E8F0FE' : '#F0F0F0',
                label: '生物识别锁定',
                hasToggle: true,
                toggleOn: this.biometricEnabled,
                showArrow: false,
                showDivider: true,
                onToggle: (): void => {
                  this.handleBiometricToggle();
                }
              })
              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              SettingsRow({
                iconEmoji: '⏱️',
                iconBgColor: this.biometricEnabled ? '#E8F0FE' : '#F0F0F0',
                label: '自动锁定',
                value: this.biometricEnabled ? this.getAutoLockLabel() : '',
                showArrow: this.biometricEnabled,
                showDivider: false,
                dimmed: !this.biometricEnabled,
                onRowClick: (): void => {
                  if (this.biometricEnabled) {
                    this.showAutoLockPicker = true;
                  }
                }
              })
            }
            .width('100%')
            .backgroundColor(this.getColors().cardBackground)
            .borderRadius(12)

            this.SectionHeader('分类')
            Column() {
              SettingsRow({
                iconEmoji: '🏷️',
                iconBgColor: '#FEF3E4',
                label: '管理分类标签',
                showArrow: true,
                showDivider: false,
                onRowClick: () => {
                  this.getUIContext().getRouter().pushUrl({ url: 'pages/TagManagerPage' });
                }
              })
            }
            .width('100%')
            .backgroundColor(this.getColors().cardBackground)
            .borderRadius(12)

            this.SectionHeader('数据备份')
            Column() {
              SettingsRow({
                iconEmoji: '📤',
                iconBgColor: '#E8F5E9',
                label: '导出加密备份',
                showArrow: true,
                showDivider: true,
                onRowClick: () => {
                  this.exportDialogController.open();
                }
              })
              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              SettingsRow({
                iconEmoji: '📱',
                iconBgColor: '#E8F5E9',
                label: '导出二维码',
                showArrow: true,
                showDivider: true,
                onRowClick: () => {
                  this.handleExportQr();
                }
              })
              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              SettingsRow({
                iconEmoji: '📥',
                iconBgColor: '#E8F5E9',
                label: '导入加密备份',
                showArrow: true,
                showDivider: true,
                onRowClick: () => {
                  this.importDialogController.open();
                }
              })
              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              SettingsRow({
                iconEmoji: '🔔',
                iconBgColor: '#E8F5E9',
                label: '备份提醒',
                value: this.getBackupReminderLabel(),
                showArrow: true,
                showDivider: false,
                onRowClick: (): void => {
                  this.showBackupReminderPicker = true;
                }
              })
            }
            .width('100%')
            .backgroundColor(this.getColors().cardBackground)
            .borderRadius(12)

            this.SectionHeader('偏好设置')
            Column() {
              SettingsRow({
                iconEmoji: '🎨',
                iconBgColor: '#F3E8FF',
                label: '外观',
                value: this.getThemeLabel(),
                showArrow: true,
                showDivider: true,
                onRowClick: (): void => {
                  this.showAppearancePicker = true;
                }
              })
              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              SettingsRow({
                iconEmoji: '📊',
                iconBgColor: '#F3E8FF',
                label: '默认排序',
                value: this.getSortLabel(),
                showArrow: true,
                showDivider: false,
                onRowClick: (): void => {
                  this.showDefaultSortPicker = true;
                }
              })
            }
            .width('100%')
            .backgroundColor(this.getColors().cardBackground)
            .borderRadius(12)

            this.SectionHeader('其他')
            Column() {
              SettingsRow({
                iconEmoji: '❓',
                iconBgColor: '#F0F0F0',
                label: '帮助与反馈',
                showArrow: true,
                showDivider: true,
                onRowClick: () => {
                  this.getUIContext().getRouter().pushUrl({ url: 'pages/HelpFeedbackPage' });
                }
              })
              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              if (this.version){
                SettingsRow({
                  iconEmoji: 'ℹ️',
                  iconBgColor: '#F0F0F0',
                  label: '关于 O2FAH',
                  value: this.version,
                  showArrow: true,
                  showDivider: true,
                  onRowClick: () => {
                    this.getUIContext().getRouter().pushUrl({ url: 'pages/AboutPage' });
                  }
                })
              }

              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              SettingsRow({
                label: '清除所有数据',
                isDestructive: true,
                showArrow: false,
                showDivider: false,
                onRowClick: (): void => {
                  this.handleClearData();
                }
              })
            }
            .width('100%')
            .backgroundColor(this.getColors().cardBackground)
            .borderRadius(12)

            Text('O2FAH '+ this.version +'· ❤️')
              .fontSize(11)
              .fontColor(this.getColors().textTertiary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 32 })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getColors().pageBackground)

      // Appearance Picker
      PickerPanel({
        title: '外观',
        visible: this.showAppearancePicker,
        selectedValue: this.themeMode,
        options: APPEARANCE_OPTIONS,
        onSelect: (value: string): void => {
          ThemeManager.setManualTheme(value);
          this.showAppearancePicker = false;
        },
        onClose: (): void => {
          this.showAppearancePicker = false;
        }
      })

      // Auto-lock Picker
      PickerPanel({
        title: '自动锁定',
        visible: this.showAutoLockPicker,
        selectedValue: this.autoLockValue.toString(),
        options: AUTO_LOCK_OPTIONS,
        onSelect: (value: string): void => {
          this.handleAutoLockChange(Number(value));
          this.showAutoLockPicker = false;
        },
        onClose: (): void => {
          this.showAutoLockPicker = false;
        }
      })

      // Backup Reminder Picker
      PickerPanel({
        title: '备份提醒',
        visible: this.showBackupReminderPicker,
        selectedValue: this.backupReminder,
        options: BACKUP_REMINDER_OPTIONS,
        onSelect: (value: string): void => {
          this.handleBackupReminderChange(value);
          this.showBackupReminderPicker = false;
        },
        onClose: (): void => {
          this.showBackupReminderPicker = false;
        }
      })

      // Default Sort Picker
      PickerPanel({
        title: '默认排序',
        visible: this.showDefaultSortPicker,
        selectedValue: this.defaultSort,
        options: SORT_OPTIONS,
        onSelect: (value: string): void => {
          this.handleSortChange(value);
          this.showDefaultSortPicker = false;
        },
        onClose: (): void => {
          this.showDefaultSortPicker = false;
        }
      })

      // Toast overlay
      if (this.toastVisible) {
        Column() {
          Text(this.toastMessage)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .padding({ top: 12, bottom: 12, left: 20, right: 20 })
            .backgroundColor('#323232')
            .borderRadius(8)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .position({ x: 0, y: '25%' })
        .animation({ duration: 200 })
      }
    }
    .width('100%')
    .height('100%')
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

  // --- Settings load/save ---

  private async loadSettings(): Promise<void> {
    try {
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
        .then((bundleInfo) => {
          this.version = bundleInfo.versionName
        })
        .catch(() => {
          this.version = "获取版本信息失败";
        });
      const settings: AppSettings = await SettingsStorage.get();
      this.autoLockValue = settings.autoLockTimeout;
      this.backupReminder = settings.backupReminder;
      this.defaultSort = settings.defaultSort;
      this.biometricEnabled = settings.biometricEnabled;
    } catch (_e) {
    }
  }

  private async saveSettings(partial: Partial<AppSettings>): Promise<void> {
    try {
      const settings: AppSettings = await SettingsStorage.get();
      if (partial.autoLockTimeout !== undefined) {
        settings.autoLockTimeout = partial.autoLockTimeout;
        this.autoLockValue = partial.autoLockTimeout;
        AppStorage.set('cachedAutoLockTimeout', partial.autoLockTimeout);
      }
      if (partial.backupReminder !== undefined) {
        settings.backupReminder = partial.backupReminder;
        this.backupReminder = partial.backupReminder;
      }
      if (partial.defaultSort !== undefined) {
        settings.defaultSort = partial.defaultSort;
        this.defaultSort = partial.defaultSort;
      }
      if (partial.biometricEnabled !== undefined) {
        settings.biometricEnabled = partial.biometricEnabled;
        this.biometricEnabled = partial.biometricEnabled;
        AppStorage.set('cachedBiometricEnabled', partial.biometricEnabled);
      }
      await SettingsStorage.save(settings);
    } catch (_e) {
    }
  }

  // --- Label helpers ---

  private getThemeLabel(): string {
    if (this.themeMode === 'light') {
      return '浅色';
    }
    if (this.themeMode === 'dark') {
      return '深色';
    }
    return '跟随系统';
  }

  private getAutoLockLabel(): string {
    if (this.autoLockValue === 0) {
      return '立即';
    }
    if (this.autoLockValue === 15) {
      return '15 秒';
    }
    if (this.autoLockValue === 30) {
      return '30 秒';
    }
    if (this.autoLockValue === 60) {
      return '1 分钟';
    }
    if (this.autoLockValue === 300) {
      return '5 分钟';
    }
    return '立即';
  }

  private getBackupReminderLabel(): string {
    if (this.backupReminder === 'never') {
      return '从不';
    }
    if (this.backupReminder === 'weekly') {
      return '每周';
    }
    if (this.backupReminder === 'monthly') {
      return '每月';
    }
    if (this.backupReminder === 'quarterly') {
      return '每季度';
    }
    return '每周';
  }

  private getSortLabel(): string {
    if (this.defaultSort === 'manual') {
      return '手动拖动';
    }
    if (this.defaultSort === 'name') {
      return '按名称 A-Z';
    }
    if (this.defaultSort === 'created') {
      return '按添加时间';
    }
    if (this.defaultSort === 'lastUsed') {
      return '按最近使用';
    }
    return '手动拖动';
  }

  // --- Picker handlers ---

  private handleAutoLockChange(value: number): void {
    this.saveSettings({ autoLockTimeout: value });
  }

  private handleBackupReminderChange(value: string): void {
    this.saveSettings({ backupReminder: value });
  }

  private handleSortChange(value: string): void {
    this.saveSettings({ defaultSort: value });
  }

  // --- Biometric toggle ---

  private handleBiometricToggle(): void {
    if (this.biometricEnabled) {
      // Disabling: show confirmation dialog
      promptAction.showDialog({
        title: '关闭生物识别锁定',
        message: '关闭后将跳过生物识别验证，任何能打开手机的人都能查看令牌。确定关闭？',
        buttons: [
          { text: '取消', color: '#86868B' },
          { text: '关闭', color: '#FF3B30' }
        ]
      }).then((data: promptAction.ShowDialogSuccessResponse): void => {
        if (data.index === 1) {
          this.saveSettings({ biometricEnabled: false });
        }
      });
    } else {
      const available: boolean = BiometricUtil.checkAvailability();
      if (!available) {
        promptAction.showToast({ message: '设备不支持生物识别', duration: 2000 });
        return;
      }
      BiometricUtil.authenticate().then((success: boolean): void => {
        if (success) {
          this.saveSettings({ biometricEnabled: true });
          this.showToast('生物识别已开启', 2000);
        }
      });
    }
  }

  // --- Backup handlers ---

  private handleExportQr(): void {
    TokenStorage.getAll().then((tokens: TokenModel[]): void => {
      if (tokens.length === 0) {
        this.showToast('暂无令牌可导出', 2000);
        return;
      }
      this.getUIContext().getRouter().pushUrl({ url: 'pages/ExportQrPage' });
    });
  }

  private handleExport(password: string): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    BackupExporter.exportData(password, ctx).then((): void => {
      this.showToast('备份已导出 ✓', 2000);
      promptAction.showToast({ message: '备份已导出', duration: 2000 });
    }).catch((): void => {
      this.showToast('导出失败', 2000);
    });
  }

  private handleImport(password: string): void {
    if (this.importLocked) {
      this.showToast('请等待 1 分钟后再试', 3000);
      return;
    }
    const ctx: Context = this.getUIContext().getHostContext()!;
    BackupImporter.performImport(password, ctx).then((result: MergeResult): void => {
      if (result.newTokens.length === 0 && result.skippedCount === 0) {
        this.showToast('未选择文件或文件为空', 2000);
        return;
      }
      this.importRetryCount = 0;
      this.mergeResult = result;
      this.mergeDialogController.open();
      this.showToast('备份已导入 ✓', 2000);
    }).catch((): void => {
      this.importRetryCount++;
      if (this.importRetryCount >= 3) {
        this.importLocked = true;
        this.showToast('密码错误次数过多，请等待 1 分钟', 3000);
        setTimeout(() => {
          this.importLocked = false;
          this.importRetryCount = 0;
        }, 60000);
      } else {
        this.showToast('密码错误，请重试 (剩余 ' + (3 - this.importRetryCount).toString() + ' 次)', 3000);
      }
    });
  }

  // --- Clear data ---

  private handleClearData(): void {
    promptAction.showDialog({
      title: '清除所有数据',
      message: '确定要清除所有令牌和设置吗？此操作不可恢复。',
      buttons: [
        { text: '取消', color: '#86868B' },
        {
          text: '清除', color: '#FF3B30',
        }
      ]
    }).then((data: promptAction.ShowDialogSuccessResponse): void => {
      if (data.index === 1) {
        TokenStorage.clear().then((): void => {
          TagStorage.clear().then((): void => {
            SettingsStorage.clear().then((): void => {
              this.showToast('所有数据已清除', 2000);
              AppStorage.set('navigateToTokens', true);
            });
          });
        });
      }
    });
  }

  // --- Toast helper ---

  showToast(msg: string, duration: number): void {
    this.toastMessage = msg;
    this.toastVisible = true;
    setTimeout((): void => {
      this.toastVisible = false;
    }, duration);
  }
}
