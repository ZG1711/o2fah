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
import { LanguageManager, LANG_SYSTEM, LANG_ZH_CN, LANG_EN, LANG_ZH_TW } from '../common/LanguageManager';
import { promptAction } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';

@Component
export struct SettingsPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('themeMode') themeMode: string = 'system';
  @State toastMessage: string = '';
  @State toastVisible: boolean = false;
  @State autoLockValue: number = 0;
  @State backupReminder: string = 'never';
  @State defaultSort: string = 'manual';
  @State language: string = '';
  @State biometricEnabled: boolean = true;
  @StorageLink('showAppearancePicker') showAppearancePicker: boolean = false;
  @StorageLink('showAutoLockPicker') showAutoLockPicker: boolean = false;
  @StorageLink('showBackupReminderPicker') showBackupReminderPicker: boolean = false;
  @StorageLink('showDefaultSortPicker') showDefaultSortPicker: boolean = false;
  @StorageLink('showLanguagePicker') showLanguagePicker: boolean = false;
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
        this.showToast(this.str($r('app.string.set_toast_backup_imported')), 2000);
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

  private str(res: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(res.id);
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
            this.SectionHeader(this.str($r('app.string.set_section_security')))
            Column() {
              SettingsRow({
                iconEmoji: this.biometricEnabled ? '🔐' : '🔓',
                iconBgColor: this.biometricEnabled ? '#E8F0FE' : '#F0F0F0',
                label: this.str($r('app.string.set_biometric')),
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
                label: this.str($r('app.string.set_auto_lock')),
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

            this.SectionHeader(this.str($r('app.string.set_section_categories')))
            Column() {
              SettingsRow({
                iconEmoji: '🏷️',
                iconBgColor: '#FEF3E4',
                label: this.str($r('app.string.set_manage_tags')),
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

            this.SectionHeader(this.str($r('app.string.set_section_backup')))
            Column() {
              SettingsRow({
                iconEmoji: '📤',
                iconBgColor: '#E8F5E9',
                label: this.str($r('app.string.set_export_backup')),
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
                label: this.str($r('app.string.set_export_qr')),
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
                label: this.str($r('app.string.set_import_backup')),
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
                label: this.str($r('app.string.set_backup_reminder')),
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

            this.SectionHeader(this.str($r('app.string.set_section_preferences')))
            Column() {
              SettingsRow({
                iconEmoji: '🌐',
                iconBgColor: '#E3F2FD',
                label: this.str($r('app.string.set_language')),
                value: this.getLanguageLabel(),
                showArrow: true,
                showDivider: true,
                onRowClick: (): void => {
                  this.showLanguagePicker = true;
                }
              })
              Divider().height(0.5).color(this.getColors().divider).width('100%').margin({ left: 56 })
              SettingsRow({
                iconEmoji: '🎨',
                iconBgColor: '#F3E8FF',
                label: this.str($r('app.string.set_appearance')),
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
                label: this.str($r('app.string.set_default_sort')),
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

            this.SectionHeader(this.str($r('app.string.set_section_other')))
            Column() {
              SettingsRow({
                iconEmoji: '❓',
                iconBgColor: '#F0F0F0',
                label: this.str($r('app.string.set_help_feedback')),
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
                  label: this.str($r('app.string.set_about')),
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
                label: this.str($r('app.string.set_clear_data')),
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
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getColors().pageBackground)

      // Language Picker
      PickerPanel({
        title: this.str($r('app.string.set_picker_language')),
        visible: this.showLanguagePicker,
        selectedValue: this.language.length > 0 ? this.language : LANG_SYSTEM,
        options: this.buildLanguageOptions(),
        onSelect: (value: string): void => {
          this.handleLanguageChange(value);
          this.showLanguagePicker = false;
        },
        onClose: (): void => {
          this.showLanguagePicker = false;
        }
      })

      // Appearance Picker
      PickerPanel({
        title: this.str($r('app.string.set_picker_appearance')),
        visible: this.showAppearancePicker,
        selectedValue: this.themeMode,
        options: this.buildAppearanceOptions(),
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
        title: this.str($r('app.string.set_picker_auto_lock')),
        visible: this.showAutoLockPicker,
        selectedValue: this.autoLockValue.toString(),
        options: this.buildAutoLockOptions(),
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
        title: this.str($r('app.string.set_picker_backup_reminder')),
        visible: this.showBackupReminderPicker,
        selectedValue: this.backupReminder,
        options: this.buildBackupReminderOptions(),
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
        title: this.str($r('app.string.set_picker_sort')),
        visible: this.showDefaultSortPicker,
        selectedValue: this.defaultSort,
        options: this.buildSortOptions(),
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
          this.version = this.str($r('app.string.set_version_failed'));
        });
      const settings: AppSettings = await SettingsStorage.get();
      this.autoLockValue = settings.autoLockTimeout;
      this.backupReminder = settings.backupReminder;
      this.defaultSort = settings.defaultSort;
      this.language = settings.language;
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
      if (partial.language !== undefined) {
        settings.language = partial.language;
        this.language = partial.language;
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
      return this.str($r('app.string.set_theme_light'));
    }
    if (this.themeMode === 'dark') {
      return this.str($r('app.string.set_theme_dark'));
    }
    return this.str($r('app.string.set_theme_system'));
  }

  private getAutoLockLabel(): string {
    if (this.autoLockValue === 0) {
      return this.str($r('app.string.set_autolock_immediate'));
    }
    if (this.autoLockValue === 15) {
      return this.str($r('app.string.set_autolock_15s'));
    }
    if (this.autoLockValue === 30) {
      return this.str($r('app.string.set_autolock_30s'));
    }
    if (this.autoLockValue === 60) {
      return this.str($r('app.string.set_autolock_1min'));
    }
    if (this.autoLockValue === 300) {
      return this.str($r('app.string.set_autolock_5min'));
    }
    return this.str($r('app.string.set_autolock_immediate'));
  }

  private getBackupReminderLabel(): string {
    if (this.backupReminder === 'never') {
      return this.str($r('app.string.set_reminder_never'));
    }
    if (this.backupReminder === 'weekly') {
      return this.str($r('app.string.set_reminder_weekly'));
    }
    if (this.backupReminder === 'monthly') {
      return this.str($r('app.string.set_reminder_monthly'));
    }
    if (this.backupReminder === 'quarterly') {
      return this.str($r('app.string.set_reminder_quarterly'));
    }
    return this.str($r('app.string.set_reminder_weekly'));
  }

  private getSortLabel(): string {
    if (this.defaultSort === 'manual') {
      return this.str($r('app.string.set_sort_manual'));
    }
    if (this.defaultSort === 'name') {
      return this.str($r('app.string.set_sort_name'));
    }
    if (this.defaultSort === 'created') {
      return this.str($r('app.string.set_sort_created'));
    }
    if (this.defaultSort === 'lastUsed') {
      return this.str($r('app.string.set_sort_lastused'));
    }
    return this.str($r('app.string.set_sort_manual'));
  }

  private getLanguageLabel(): string {
    if (this.language === LANG_ZH_CN) {
      return '简体中文';
    }
    if (this.language === LANG_EN) {
      return 'English';
    }
    if (this.language === LANG_ZH_TW) {
      return '繁體中文';
    }
    return this.str($r('app.string.set_language_system'));
  }

  // --- Picker option builders ---

  private buildLanguageOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: this.str($r('app.string.set_language_system')), value: LANG_SYSTEM },
      { label: '简体中文', value: LANG_ZH_CN },
      { label: 'English', value: LANG_EN },
      { label: '繁體中文', value: LANG_ZH_TW }
    ];
    return options;
  }

  private buildAutoLockOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: this.str($r('app.string.set_autolock_immediate')), value: '0', description: this.str($r('app.string.set_autolock_immediate_desc')) },
      { label: this.str($r('app.string.set_autolock_15s')), value: '15', description: this.str($r('app.string.set_autolock_15s_desc')) },
      { label: this.str($r('app.string.set_autolock_30s')), value: '30', description: this.str($r('app.string.set_autolock_30s_desc')) },
      { label: this.str($r('app.string.set_autolock_1min')), value: '60', description: this.str($r('app.string.set_autolock_1min_desc')) },
      { label: this.str($r('app.string.set_autolock_5min')), value: '300', description: this.str($r('app.string.set_autolock_5min_desc')) }
    ];
    return options;
  }

  private buildBackupReminderOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: this.str($r('app.string.set_reminder_never')), value: 'never', description: this.str($r('app.string.set_reminder_never_desc')) },
      { label: this.str($r('app.string.set_reminder_weekly')), value: 'weekly', description: this.str($r('app.string.set_reminder_weekly_desc')) },
      { label: this.str($r('app.string.set_reminder_monthly')), value: 'monthly', description: this.str($r('app.string.set_reminder_monthly_desc')) },
      { label: this.str($r('app.string.set_reminder_quarterly')), value: 'quarterly', description: this.str($r('app.string.set_reminder_quarterly_desc')) }
    ];
    return options;
  }

  private buildAppearanceOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: this.str($r('app.string.set_theme_light')), value: 'light', description: this.str($r('app.string.set_theme_light_desc')), colorPreview: '#F5F5F7' },
      { label: this.str($r('app.string.set_theme_dark')), value: 'dark', description: this.str($r('app.string.set_theme_dark_desc')), colorPreview: '#000000' },
      { label: this.str($r('app.string.set_theme_system')), value: 'system', description: this.str($r('app.string.set_theme_system_desc')), colorPreview: '#E8E8ED' }
    ];
    return options;
  }

  private buildSortOptions(): PickerOption[] {
    const options: PickerOption[] = [
      { label: this.str($r('app.string.set_sort_manual')), value: 'manual', description: this.str($r('app.string.set_sort_manual_desc')) },
      { label: this.str($r('app.string.set_sort_name')), value: 'name', description: this.str($r('app.string.set_sort_name_desc')) },
      { label: this.str($r('app.string.set_sort_created')), value: 'created', description: this.str($r('app.string.set_sort_created_desc')) },
      { label: this.str($r('app.string.set_sort_lastused')), value: 'lastUsed', description: this.str($r('app.string.set_sort_lastused_desc')) }
    ];
    return options;
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

  private handleLanguageChange(value: string): void {
    if (value === LANG_SYSTEM) {
      LanguageManager.apply(LANG_SYSTEM);
      this.saveSettings({ language: '' });
    } else {
      LanguageManager.apply(value);
      this.saveSettings({ language: value });
    }
    this.showToast(this.str($r('app.string.set_language_changed_toast')), 2500);
  }

  // --- Biometric toggle ---

  private handleBiometricToggle(): void {
    if (this.biometricEnabled) {
      // Disabling: show confirmation dialog
      promptAction.showDialog({
        title: this.str($r('app.string.set_dialog_biometric_title')),
        message: this.str($r('app.string.set_dialog_biometric_message')),
        buttons: [
          { text: this.str($r('app.string.button_cancel')), color: '#86868B' },
          { text: this.str($r('app.string.set_dialog_disable')), color: '#FF3B30' }
        ]
      }).then((data: promptAction.ShowDialogSuccessResponse): void => {
        if (data.index === 1) {
          this.saveSettings({ biometricEnabled: false });
        }
      });
    } else {
      const available: boolean = BiometricUtil.checkAvailability();
      if (!available) {
        promptAction.showToast({ message: this.str($r('app.string.set_toast_biometric_unsupported')), duration: 2000 });
        return;
      }
      BiometricUtil.authenticate().then((success: boolean): void => {
        if (success) {
          this.saveSettings({ biometricEnabled: true });
          this.showToast(this.str($r('app.string.set_toast_biometric_enabled')), 2000);
        }
      });
    }
  }

  // --- Backup handlers ---

  private handleExportQr(): void {
    TokenStorage.getAll().then((tokens: TokenModel[]): void => {
      if (tokens.length === 0) {
        this.showToast(this.str($r('app.string.set_toast_no_tokens')), 2000);
        return;
      }
      this.getUIContext().getRouter().pushUrl({ url: 'pages/ExportQrPage' });
    });
  }

  private handleExport(password: string): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    BackupExporter.exportData(password, ctx).then((): void => {
      this.showToast(this.str($r('app.string.set_toast_backup_exported')), 2000);
      promptAction.showToast({ message: this.str($r('app.string.set_toast_backup_exported')), duration: 2000 });
    }).catch((): void => {
      this.showToast(this.str($r('app.string.set_toast_export_failed')), 2000);
    });
  }

  private handleImport(password: string): void {
    if (this.importLocked) {
      this.showToast(this.str($r('app.string.set_toast_import_wait')), 3000);
      return;
    }
    const ctx: Context = this.getUIContext().getHostContext()!;
    BackupImporter.performImport(password, ctx).then((result: MergeResult): void => {
      if (result.newTokens.length === 0 && result.skippedCount === 0) {
        this.showToast(this.str($r('app.string.set_toast_no_file')), 2000);
        return;
      }
      this.importRetryCount = 0;
      this.mergeResult = result;
      this.mergeDialogController.open();
      this.showToast(this.str($r('app.string.set_toast_backup_imported')), 2000);
    }).catch((): void => {
      this.importRetryCount++;
      if (this.importRetryCount >= 3) {
        this.importLocked = true;
        this.showToast(this.str($r('app.string.set_toast_import_locked')), 3000);
        setTimeout(() => {
          this.importLocked = false;
          this.importRetryCount = 0;
        }, 60000);
      } else {
        const msg: string = this.str($r('app.string.set_toast_wrong_password')).replace('%d', (3 - this.importRetryCount).toString());
        this.showToast(msg, 3000);
      }
    });
  }

  // --- Clear data ---

  private handleClearData(): void {
    promptAction.showDialog({
      title: this.str($r('app.string.set_dialog_clear_title')),
      message: this.str($r('app.string.set_dialog_clear_message')),
      buttons: [
        { text: this.str($r('app.string.button_cancel')), color: '#86868B' },
        {
          text: this.str($r('app.string.set_dialog_clear_confirm')), color: '#FF3B30',
        }
      ]
    }).then((data: promptAction.ShowDialogSuccessResponse): void => {
      if (data.index === 1) {
        LanguageManager.apply(LANG_SYSTEM);
        TokenStorage.clear().then((): void => {
          TagStorage.clear().then((): void => {
            SettingsStorage.clear().then((): void => {
              this.showToast(this.str($r('app.string.set_toast_data_cleared')), 2000);
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
