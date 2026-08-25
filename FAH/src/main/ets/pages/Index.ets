import { SearchBar } from '../components/SearchBar';
import { CategoryTabs, TagItem } from '../components/CategoryTabs';
import { TokenCard } from '../components/TokenCard';
import { FabButton } from '../components/FabButton';
import { EmptyState } from '../components/EmptyState';
import { SortMenu } from '../components/SortMenu';
import { AddTokenPanel } from '../components/AddTokenPanel';
import { SettingsPage } from './SettingsPage';
import { IconConstants } from '../common/IconConstants';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { TokenModel } from '../model/TokenModel';
import { TokenStorage } from '../storage/TokenStorage';
import { TotpEngine } from '../engine/TotpEngine';
import { HotpEngine } from '../engine/HotpEngine';
import { OtpUriParser } from '../engine/OtpUriParser';
import { EditTokenDialog, EditResult } from '../components/dialogs/EditTokenDialog';
import { DeleteTokenDialog } from '../components/dialogs/DeleteTokenDialog';
import { ImportPasswordDialog } from '../components/dialogs/ImportPasswordDialog';
import { ImportMergeDialog } from '../components/dialogs/ImportMergeDialog';
import { BackupImporter, MergeResult } from '../backup/BackupImporter';
import { ClipboardUtil } from '../utils/ClipboardUtil';
import { SettingsStorage } from '../storage/SettingsStorage';
import { TagStorage } from '../storage/TagStorage';
import { TagModel } from '../model/TagModel';
import { AppSettings } from '../model/AppSettings';
import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { abilityAccessCtrl, PermissionRequestResult } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
@Entry
@Component
struct Index {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('navigateToTokens') @Watch('onNavigateToTokens') navigateToTokens: boolean = false;
  @StorageLink('requireBiometricAuth') @Watch('onRequireAuthChanged') requireBiometricAuth: boolean = false;
  @StorageLink('appIsLocked') @Watch('onAppLockedChanged') appIsLocked: boolean = false;
  @State currentTabIndex: number = 0;
  @State searchText: string = '';
  @State selectedTagIndex: number = 0;
  @State selectedSort: string = 'manual';
  @State showSortMenu: boolean = false;
  @State showAddPanel: boolean = false;
  @State toastMessage: string = '';
  @State toastType: string = 'success';
  @State toastVisible: boolean = false;
  @State tokens: TokenModel[] = [];
  @State codeMap: Record<string, string> = {};
  @State remainingMap: Record<string, number> = {};
  @State swipedTokenId: string = '';
  @State editDialogIssuer: string = '';
  @State editDialogAccount: string = '';
  @State editDialogIcon: string = '';
  @State editDialogTags: string[] = [];
  @State editDialogTagNames: string[] = [];
  @State editDialogTagColors: string[] = [];
  @State deleteDialogTokenName: string = '';
  @State showBackupBanner: boolean = false;
  @State daysSinceBackup: number = 0;
  @State dragItemId: string = '';
  @State dragHintShown: boolean = false;
  @State tagColorMap: Record<string, string> = {};
  @StorageLink('pendingImportUri') @Watch('onImportUri') pendingImportUri: string = '';
  @State importLocked: boolean = false;
  @State importRetryCount: number = 0;
  @State mergeResult: MergeResult = {
    newTokens: [],
    skippedCount: 0,
    addedCount: 0,
    totalAfter: 0
  };
  private timerId: number = -1;
  private lockPushed: boolean = false;
  private editingTokenId: string = '';
  private deletingTokenId: string = '';
  private tabTitles: string[] = ['令牌', '设置'];
  private displayTokensCache: TokenModel[] = [];
  private cacheTokensRef: TokenModel[] | undefined = undefined;
  private cacheDisplayTagsRef: TagItem[] | undefined = undefined;
  private cacheSearchText: string = '';
  private cacheSelectedTagIndex: number = -1;
  private cacheSelectedSort: string = '';

  @State displayTags: TagItem[] = [{ id: 'all', name: '全部', color: '#6B7280' }];

  private editDialogController: CustomDialogController = new CustomDialogController({
    builder: EditTokenDialog({
      issuer: this.editDialogIssuer,
      account: this.editDialogAccount,
      icon: this.editDialogIcon,
      tags: this.editDialogTags,
      tagNames: this.editDialogTagNames,
      tagColors: this.editDialogTagColors,
      isDark: this.isDarkMode,
      confirm: (result: EditResult): void => {
        this.handleEditConfirm(result.issuer, result.account, result.icon, result.tags);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
    onWillDismiss: (action: DismissDialogAction): void => {
      if (action.reason === DismissReason.PRESS_BACK) {
        const pickerOpen: boolean = AppStorage.get<boolean>('editIconPickerOpen') ?? false;
        if (pickerOpen) {
          AppStorage.set('editIconPickerOpen', false);
          return;
        }
      }
      action.dismiss();
    }
  });

  private deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: DeleteTokenDialog({
      tokenName: this.deleteDialogTokenName,
      isDark: this.isDarkMode,
      confirm: (): void => {
        this.handleDeleteConfirm();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private fileImportDialogController: CustomDialogController = new CustomDialogController({
    builder: ImportPasswordDialog({
      isDark: this.isDarkMode,
      confirm: (password: string): void => {
        this.handleFileImport(password);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private fileImportMergeController: CustomDialogController = new CustomDialogController({
    builder: ImportMergeDialog({
      mergeResult: this.mergeResult,
      isDark: this.isDarkMode,
      confirm: (): void => {
        this.toastMessage = '备份已导入';
        this.toastType = 'success';
        this.toastVisible = true;
        setTimeout((): void => {
          this.toastVisible = false;
        }, 2000);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear(): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    TokenStorage.init(ctx);
    SettingsStorage.init(ctx);
    TagStorage.init(ctx);
    ThemeManager.loadSavedMode();
    const hintFlag: boolean | undefined = AppStorage.get<boolean>('dragSortHintShown');
    this.dragHintShown = hintFlag ?? false;
    this.checkBackupReminder();
    this.timerId = setInterval(() => {
      this.updateCountdown();
    }, 1000);
  }

  onPageShow(): void {
    if (this.requireBiometricAuth && !this.lockPushed) {
      this.pushLockPage();
      return;
    }
    this.loadTokens();
    this.loadTags();
    this.loadDefaultSort();
    if (this.pendingImportUri.length > 0) {
      this.fileImportDialogController.open();
    }
  }

  onRequireAuthChanged(): void {
    if (this.requireBiometricAuth && !this.lockPushed) {
      this.pushLockPage();
    }
    if (!this.requireBiometricAuth) {
      this.lockPushed = false;
    }
  }

  onAppLockedChanged(): void {
    if (this.appIsLocked && !this.lockPushed) {
      this.pushLockPage();
    }
  }

  private pushLockPage(): void {
    this.lockPushed = true;
    this.getUIContext().getRouter().pushUrl({ url: 'pages/LockPage' });
  }

  onNavigateToTokens(): void {
    if (this.navigateToTokens) {
      this.currentTabIndex = 0;
      AppStorage.set('navigateToTokens', false);
      this.loadTokens();
      this.loadTags();
    }
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  onBackPress(): boolean | void {
    if (this.showSortMenu || this.showAddPanel) {
      this.showSortMenu = false;
      this.showAddPanel = false;
      return true;
    }
    if (AppStorage.get('showAppearancePicker') === true ||
        AppStorage.get('showAutoLockPicker') === true ||
        AppStorage.get('showBackupReminderPicker') === true ||
        AppStorage.get('showDefaultSortPicker') === true) {
      AppStorage.set('showAppearancePicker', false);
      AppStorage.set('showAutoLockPicker', false);
      AppStorage.set('showBackupReminderPicker', false);
      AppStorage.set('showDefaultSortPicker', false);
      return true;
    }
    return false;
  }

  onImportUri(): void {
    if (this.pendingImportUri.length > 0 && !this.requireBiometricAuth && !this.appIsLocked) {
      this.fileImportDialogController.open();
    }
  }

  private handleFileImport(password: string): void {
    const uri: string = this.pendingImportUri;
    AppStorage.set('pendingImportUri', '');
    BackupImporter.performImportFromUri(uri, password).then((result: MergeResult): void => {
      if (result.newTokens.length === 0 && result.skippedCount === 0) {
        this.toastMessage = '无法读取备份文件';
        this.toastType = 'error';
        this.toastVisible = true;
        setTimeout((): void => { this.toastVisible = false; }, 2000);
        return;
      }
      this.importRetryCount = 0;
      this.mergeResult = result;
      this.fileImportMergeController.open();
      this.loadTokens();
    }).catch((): void => {
      this.importRetryCount++;
      if (this.importRetryCount >= 3) {
        this.importLocked = true;
        this.toastMessage = '密码错误次数过多，请等待1分钟';
        this.toastType = 'error';
        this.toastVisible = true;
        setTimeout((): void => { this.toastVisible = false; }, 3000);
        setTimeout(() => {
          this.importLocked = false;
          this.importRetryCount = 0;
        }, 60000);
      } else {
        this.toastMessage = '密码错误，请重试 (剩余 ' + (3 - this.importRetryCount).toString() + ' 次)';
        this.toastType = 'error';
        this.toastVisible = true;
        setTimeout((): void => { this.toastVisible = false; }, 3000);
      }
    });
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
        Tabs({ barPosition: BarPosition.End }) {
          // Tab 0: Token List
          TabContent() {
            Column() {
              // Search bar
              SearchBar({
                onChange: (text: string) => {
                  this.searchText = text;
                },
                onSortClick: () => {
                  this.showSortMenu = !this.showSortMenu;
                }
              })

              // Category tabs
              CategoryTabs({
                tags: this.displayTags,
                selectedIndex: this.selectedTagIndex,
                onTagSelect: (tagId: string, index: number) => {
                  this.selectedTagIndex = index;
                }
              })

              // Token list area with FAB
              Stack({ alignContent: Alignment.BottomEnd }) {
                // Backup reminder banner
                if (this.showBackupBanner) {
                  Row() {
                    Row() {
                      Text('已 ' + this.daysSinceBackup.toString() + ' 天未备份令牌数据，建议导出备份')
                        .fontSize(12)
                        .fontColor('#B45309')
                        .layoutWeight(1)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text('立即备份')
                        .fontSize(12)
                        .fontWeight(600)
                        .fontColor('#2563EB')
                        .onClick(() => {
                          this.currentTabIndex = 1;
                          this.showBackupBanner = false;
                        })

                      Text('✕')
                        .fontSize(14)
                        .fontColor('#B45309')
                        .margin({ left: 8 })
                        .onClick(() => {
                          this.showBackupBanner = false;
                        })
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                  }
                  .width('100%')
                  .backgroundColor('#FEF3C7')
                  .padding({ left: 20, right: 20, bottom: 4 })
                }
                if (this.tokens.length > 0) {
                  List({ space: 10 }) {
                    ForEach(this.getDisplayTokens(), (item: TokenModel) => {
                      ListItem() {
                        TokenCard({
                          token: item,
                          code: this.codeMap[item.id] ?? '',
                          remainingSeconds: this.remainingMap[item.id] ?? 0,
                          isDragging: this.dragItemId === item.id,
                          tagColorMap: this.tagColorMap,
                          onCardClick: (): void => {
                            this.copyCode(this.codeMap[item.id] ?? '');
                          },
                          onRefreshClick: (): void => {
                            this.handleHotpRefresh(item);
                          }
                        })
                      }
                      .onTouch((event: TouchEvent) => {
                        if (event.type === TouchType.Down) {
                          this.swipedTokenId = item.id;
                        }
                      })
                      .swipeAction({
                        end: {
                          builder: (): void => {
                            this.SwipeActionsBuilder();
                          },
                          onAction: (): void => {
                          },
                          actionAreaDistance: 168
                        }
                      } as SwipeActionOptions)
                    }, (item: TokenModel) => item.id)
                    .onMove((from: number, to: number): void => {
                      if (from === to) {
                        return;
                      }
                      const displayed: TokenModel[] = this.computeDisplayTokens();
                      const moved: TokenModel = displayed.splice(from, 1)[0];
                      displayed.splice(to, 0, moved);
                      const newTokens: TokenModel[] = [...displayed];
                      for (let i: number = 0; i < this.tokens.length; i++) {
                        let found: boolean = false;
                        for (let j: number = 0; j < displayed.length; j++) {
                          if (this.tokens[i].id === displayed[j].id) {
                            found = true;
                            break;
                          }
                        }
                        if (!found) {
                          newTokens.push(this.tokens[i]);
                        }
                      }
                      for (let i: number = 0; i < newTokens.length; i++) {
                        newTokens[i].sortOrder = i;
                      }
                      this.tokens = newTokens;
                      TokenStorage.saveAll(newTokens);
                      this.showToast('排序已保存 ✓', 'success');
                    })
                  }
                  .width('100%')
                  .height('100%')
                  .padding({ left: 20, right: 20, top: 6 })
                  .scrollBar(BarState.Off)
                  .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
                  .onItemDragStart((_event: ItemDragInfo, itemIndex: number): void => {
                    const displayed: TokenModel[] = this.getDisplayTokens();
                    if (itemIndex >= 0 && itemIndex < displayed.length) {
                      this.dragItemId = displayed[itemIndex].id;
                    }
                  })
                  .onItemDrop((): void => {
                    this.dragItemId = '';
                    if (!this.dragHintShown) {
                      this.dragHintShown = true;
                      AppStorage.set('dragSortHintShown', true);
                    }
                  })
                } else {
                  EmptyState()
                }



                // FAB button
                Column() {
                  FabButton({ onFabClick: () => { this.showAddPanel = true; } })
                }
                .padding({ right: 20, bottom: 20 })
              }
              .layoutWeight(1)
              .width('100%')
            }
            .width('100%')
            .height('100%')
            .backgroundColor(this.getColors().pageBackground)
          }
          .tabBar(this.TabBarBuilder(0))

          // Tab 1: Settings
          TabContent() {
            SettingsPage()
          }
          .tabBar(this.TabBarBuilder(1))
        }
        .barHeight(56)
        .onChange((index: number) => {
          this.currentTabIndex = index;
          if (index === 0) {
            this.loadTokens();
            this.loadTags();
            this.loadDefaultSort();
          }
        })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.getColors().tabBarBackground)
        .scrollable(true)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')

      // Sort menu overlay
      if (this.showSortMenu) {
        SortMenu({
          selectedSort: this.selectedSort,
          visible: true,
          onSelectSort: (sortKey: string) => {
            this.selectedSort = sortKey;
            this.showSortMenu = false;
          },
          onClose: () => {
            this.showSortMenu = false;
          }
        })
      }

      // Add token panel overlay
      if (this.showAddPanel) {
        AddTokenPanel({
          visible: true,
          onClose: () => { this.showAddPanel = false; },
          onScanQR: () => {
            this.showAddPanel = false;
            this.startCameraScan();
          },
          onPhotoPick: () => {
            this.showAddPanel = false;
            this.openPhotoPicker();
          },
          onManualInput: () => {
            this.showAddPanel = false;
            this.navigateToManualInput();
          }
        })
      }

      // Toast overlay
      if (this.toastVisible) {
        Row() {
          Row({ space: 8 }) {
            Image(this.toastType === 'success' ? IconConstants.IC_TOAST_SUCCESS :
              this.toastType === 'warning' ? IconConstants.IC_TOAST_WARNING :
                IconConstants.IC_TOAST_ERROR)
              .width(16)
              .height(16)

            Text(this.toastMessage)
              .fontSize(14)
              .fontWeight(500)
              .fontColor(this.getColors().white)
          }
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

  // --- Data loading and timer ---

  private async loadTokens(): Promise<void> {
    const all: TokenModel[] = await TokenStorage.getAll();
    this.tokens = all;
    const codeMapCopy: Record<string, string> = {};
    const remainingCopy: Record<string, number> = {};
    const tasks: Promise<void>[] = [];
    for (let i: number = 0; i < all.length; i++) {
      const t: TokenModel = all[i];
      if (t.type === 'TOTP') {
        tasks.push(TotpEngine.generateWithToken(t).then((code: string): void => {
          codeMapCopy[t.id] = code;
          remainingCopy[t.id] = TotpEngine.getRemainingSeconds(t.period);
        }));
      } else if (t.type === 'HOTP') {
        tasks.push(HotpEngine.generate(t.secret, t.counter, t.algorithm, t.digits).then((code: string): void => {
          codeMapCopy[t.id] = code;
        }));
      }
    }
    await Promise.all(tasks);
    this.codeMap = codeMapCopy;
    this.remainingMap = remainingCopy;
    this.tokens = [...all];
  }

  private async loadTags(): Promise<void> {
    const savedTags: TagModel[] = await TagStorage.getAll();
    const tagItems: TagItem[] = [{ id: 'all', name: '全部', color: '#6B7280' }];
    const colorMap: Record<string, string> = {};
    for (let i: number = 0; i < savedTags.length; i++) {
      tagItems.push({ id: savedTags[i].name, name: savedTags[i].name, color: savedTags[i].color });
      colorMap[savedTags[i].name] = savedTags[i].color;
    }
    this.displayTags = tagItems;
    this.tagColorMap = colorMap;
  }

  private async loadDefaultSort(): Promise<void> {
    const settings: AppSettings = await SettingsStorage.get();
    this.selectedSort = settings.defaultSort;
  }

  private updateCountdown(): void {
    const newRemaining: Record<string, number> = {};
    for (let i: number = 0; i < this.tokens.length; i++) {
      const t: TokenModel = this.tokens[i];
      if (t.type === 'TOTP') {
        const remaining: number = TotpEngine.getRemainingSeconds(t.period);
        newRemaining[t.id] = remaining;
        if (remaining === t.period - 1 || this.codeMap[t.id] === undefined) {
          TotpEngine.generateWithToken(t).then((code: string): void => {
            this.codeMap[t.id] = code;
          });
        }
      }
    }
    this.remainingMap = newRemaining;
  }

  // --- Filtering and sorting ---

  private getDisplayTokens(): TokenModel[] {
    if (this.tokens === this.cacheTokensRef &&
        this.displayTags === this.cacheDisplayTagsRef &&
        this.searchText === this.cacheSearchText &&
        this.selectedTagIndex === this.cacheSelectedTagIndex &&
        this.selectedSort === this.cacheSelectedSort) {
      return this.displayTokensCache;
    }
    this.cacheTokensRef = this.tokens;
    this.cacheDisplayTagsRef = this.displayTags;
    this.cacheSearchText = this.searchText;
    this.cacheSelectedTagIndex = this.selectedTagIndex;
    this.cacheSelectedSort = this.selectedSort;
    this.displayTokensCache = this.computeDisplayTokens();
    return this.displayTokensCache;
  }

  private computeDisplayTokens(): TokenModel[] {
    let result: TokenModel[] = [];
    const searchLower: string = this.searchText.toLowerCase();
    let selectedTagName: string = '';
    if (this.selectedTagIndex > 0 && this.selectedTagIndex < this.displayTags.length) {
      selectedTagName = this.displayTags[this.selectedTagIndex].name;
    }
    for (let i: number = 0; i < this.tokens.length; i++) {
      const t: TokenModel = this.tokens[i];
      if (searchLower.length > 0) {
        const issuerLower: string = t.issuer.toLowerCase();
        const accountLower: string = t.account.toLowerCase();
        if (issuerLower.indexOf(searchLower) < 0 && accountLower.indexOf(searchLower) < 0) {
          continue;
        }
      }
      if (selectedTagName.length > 0) {
        let hasTag: boolean = false;
        for (let j: number = 0; j < t.tags.length; j++) {
          if (t.tags[j] === selectedTagName) {
            hasTag = true;
            break;
          }
        }
        if (!hasTag) {
          continue;
        }
      }
      result.push(t);
    }
    if (this.selectedSort === 'name') {
      result.sort((a: TokenModel, b: TokenModel): number => {
        const aname: string = a.issuer.toLowerCase();
        const bname: string = b.issuer.toLowerCase();
        if (aname < bname) {
          return -1;
        }
        if (aname > bname) {
          return 1;
        }
        return 0;
      });
    } else if (this.selectedSort === 'created') {
      result.sort((a: TokenModel, b: TokenModel): number => {
        return b.createdAt - a.createdAt;
      });
    } else if (this.selectedSort === 'lastUsed') {
      result.sort((a: TokenModel, b: TokenModel): number => {
        return b.lastUsedAt - a.lastUsedAt;
      });
    } else {
      result.sort((a: TokenModel, b: TokenModel): number => {
        return a.sortOrder - b.sortOrder;
      });
    }
    return result;
  }

  // --- Copy code ---

  private copyCode(code: string): void {
    ClipboardUtil.copy(code);
    this.showToast('已复制 ✓', 'success');
  }

  // --- HOTP refresh ---

  private async handleHotpRefresh(token: TokenModel): Promise<void> {
    const newCounter: number = token.counter + 1;
    const code: string = await HotpEngine.generate(token.secret, newCounter, token.algorithm, token.digits);
    token.counter = newCounter;
    token.lastUsedAt = Date.now();
    this.codeMap[token.id] = code;
    this.tokens = [...this.tokens];
    await TokenStorage.update(token);
    ClipboardUtil.copy(code);
    this.showToast('已刷新并复制 ✓', 'success');
  }

  // --- Edit / Delete ---

  private findTokenById(id: string): TokenModel | undefined {
    for (let i: number = 0; i < this.tokens.length; i++) {
      if (this.tokens[i].id === id) {
        return this.tokens[i];
      }
    }
    return undefined;
  }

  private showEditDialog(token: TokenModel): void {
    this.editingTokenId = token.id;
    this.editDialogIssuer = token.issuer;
    this.editDialogAccount = token.account;
    this.editDialogIcon = token.icon;
    this.editDialogTags = token.tags;
    this.editDialogTagNames = [];
    this.editDialogTagColors = [];
    for (let i: number = 1; i < this.displayTags.length; i++) {
      this.editDialogTagNames.push(this.displayTags[i].name);
      this.editDialogTagColors.push(this.displayTags[i].color);
    }
    this.editDialogController.open();
  }

  private showDeleteDialog(token: TokenModel): void {
    this.deletingTokenId = token.id;
    this.deleteDialogTokenName = token.issuer + ' (' + token.account + ')';
    this.deleteDialogController.open();
  }

  private async handleEditConfirm(issuer: string, account: string, icon: string, tags: string[]): Promise<void> {
    const token: TokenModel | undefined = this.findTokenById(this.editingTokenId);
    if (token !== undefined) {
      token.issuer = issuer;
      token.account = account;
      token.icon = icon;
      token.tags = tags;
      token.lastUsedAt = Date.now();
      this.tokens = [...this.tokens];
      await TokenStorage.update(token);
      this.showToast('令牌已更新 ✓', 'success');
    }
  }

  private async handleDeleteConfirm(): Promise<void> {
    await TokenStorage.delete(this.deletingTokenId);
    const newTokens: TokenModel[] = [];
    for (let i: number = 0; i < this.tokens.length; i++) {
      if (this.tokens[i].id !== this.deletingTokenId) {
        newTokens.push(this.tokens[i]);
      }
    }
    this.tokens = newTokens;
    const newCodeMap: Record<string, string> = {};
    const newRemaining: Record<string, number> = {};
    for (let i: number = 0; i < newTokens.length; i++) {
      const id: string = newTokens[i].id;
      newCodeMap[id] = this.codeMap[id] ?? '';
      newRemaining[id] = this.remainingMap[id] ?? 0;
    }
    this.codeMap = newCodeMap;
    this.remainingMap = newRemaining;
    this.showToast('令牌已删除', 'warning');
  }

  // --- Camera QR scan ---

  private startCameraScan(): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(ctx, ['ohos.permission.CAMERA'])
      .then((data: PermissionRequestResult): void => {
        if (data.authResults.length > 0 && data.authResults[0] === 0) {
          this.launchScan();
        } else {
          this.showToast('需要相机权限才能扫描二维码', 'warning');
        }
      })
      .catch((): void => {
        this.showToast('无法获取相机权限', 'warning');
      });
  }

  private launchScan(): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: true
    };
    scanBarcode.startScanForResult(ctx, options)
      .then((result: scanBarcode.ScanResult): void => {
        const value: string = result.originalValue;
        if (value.startsWith('otpauth://') || OtpUriParser.parse(value) !== null) {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/AddConfirmPage',
            params: { uri: value }
          });
        } else {
          this.showToast('未识别到有效令牌', 'warning');
        }
      })
      .catch((): void => {
      });
  }

  // --- Navigation ---

  private navigateToManualInput(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/AddManualPage' });
  }

  // --- Photo picker for album QR recognition ---

  private openPhotoPicker(): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    const photoOption: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoOption.maxSelectNumber = 1;

    const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    photoPicker.select(photoOption)
      .then((result: photoAccessHelper.PhotoSelectResult): void => {
        if (!result.photoUris || result.photoUris.length === 0) {
          return;
        }
        const imageUri: string = result.photoUris[0];
        const inputImage: detectBarcode.InputImage = { uri: imageUri };
        const scanOpts: scanBarcode.ScanOptions = {
          scanTypes: [scanCore.ScanType.QR_CODE],
          enableMultiMode: false,
          enableAlbum: true
        };
        detectBarcode.decode(inputImage, scanOpts)
          .then((results: Array<scanBarcode.ScanResult>): void => {
            if (results.length === 0) {
              this.showToast('未识别到有效令牌', 'warning');
              return;
            }
            const value: string = results[0].originalValue;
            if (value.startsWith('otpauth://') || OtpUriParser.parse(value) !== null) {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/AddConfirmPage',
                params: { uri: value }
              });
            } else {
              this.showToast('未识别到有效令牌', 'warning');
            }
          })
          .catch((): void => {
            this.showToast('未识别到有效令牌', 'warning');
          });
      })
      .catch((): void => {
        this.showToast('无法打开相册', 'warning');
      });
  }

  showToast(msg: string, type: string): void {
    this.toastMessage = msg;
    this.toastType = type;
    this.toastVisible = true;
    setTimeout(() => {
      this.toastVisible = false;
    }, 2000);
  }

  // --- Backup reminder ---

  private async checkBackupReminder(): Promise<void> {
    const settings: AppSettings = await SettingsStorage.get();
    const reminder: string = settings.backupReminder;
    if (reminder === 'never') {
      return;
    }
    const lastBackup: number = settings.lastBackupTime;
    if (lastBackup === 0) {
      this.showBackupBanner = true;
      this.daysSinceBackup = 99;
      return;
    }
    const now: number = Date.now();
    const elapsedDays: number = Math.floor((now - lastBackup) / (1000 * 60 * 60 * 24));
    let thresholdDays: number = 7;
    if (reminder === 'monthly') {
      thresholdDays = 30;
    } else if (reminder === 'quarterly') {
      thresholdDays = 90;
    } else if (reminder === 'biweekly') {
      thresholdDays = 14;
    }
    if (elapsedDays >= thresholdDays) {
      this.showBackupBanner = true;
      this.daysSinceBackup = elapsedDays;
    }
  }

  // --- Builders ---

  @Builder
  TabBarBuilder(idx: number): void {
    Column() {
      Image(idx === 0 ? $r('app.media.ic_tab_tokens') : $r('app.media.ic_tab_settings'))
        .width(22)
        .height(22)
        .fillColor(this.currentTabIndex === idx ? this.getColors().tabSelected : this.getColors().tabUnselected)
      Text(this.tabTitles[idx])
        .fontSize(10)
        .fontWeight(this.currentTabIndex === idx ? 600 : 500)
        .fontColor(this.currentTabIndex === idx ? this.getColors().tabSelected : this.getColors().tabUnselected)
        .margin({ top: 5 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SwipeActionsBuilder(): void {
    Row() {
      Button() {
        Text('二维码')
          .fontSize(12)
          .fontWeight(600)
          .fontColor(this.getColors().white)
      }
      .width(56)
      .height('100%')
      .backgroundColor('#007AFF')
      .borderRadius(0)
      .onClick(() => {
        const token: TokenModel | undefined = this.findTokenById(this.swipedTokenId);
        if (token !== undefined) {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/ExportQrPage',
            params: { focusTokenId: token.id }
          });
        }
      })

      Button() {
        Text('编辑')
          .fontSize(12)
          .fontWeight(600)
          .fontColor(this.getColors().white)
      }
      .width(56)
      .height('100%')
      .backgroundColor('#FF9500')
      .borderRadius(0)
      .onClick(() => {
        const token: TokenModel | undefined = this.findTokenById(this.swipedTokenId);
        if (token !== undefined) {
          this.showEditDialog(token);
        }
      })

      Button() {
        Text('删除')
          .fontSize(12)
          .fontWeight(600)
          .fontColor(this.getColors().white)
      }
      .width(56)
      .height('100%')
      .backgroundColor('#FF3B30')
      .borderRadius(0)
      .onClick(() => {
        const token: TokenModel | undefined = this.findTokenById(this.swipedTokenId);
        if (token !== undefined) {
          this.showDeleteDialog(token);
        }
      })
    }
  }

}
