import { IconConstants } from '../common/IconConstants';
import { TagRow, TagRowData } from '../components/TagRow';
import { TagCreateDialog } from '../components/dialogs/TagCreateDialog';
import { TagDeleteDialog } from '../components/dialogs/TagDeleteDialog';
import { ThemeManager, ThemeColors } from '../common/ThemeManager';
import { TagModel } from '../model/TagModel';
import { TagStorage } from '../storage/TagStorage';
import { TokenModel } from '../model/TokenModel';
import { TokenStorage } from '../storage/TokenStorage';

@Entry
@Component
struct TagManagerPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State tags: TagRowData[] = [];
  @State dragTagId: string = '';

  // Swipe tracking
  @State swipedTagId: string = '';

  // Dialog state
  @State dialogTagName: string = '';
  @State dialogTagColor: string = '#4285F4';
  @State isEditMode: boolean = false;
  @State dialogTagId: string = '';
  @State deleteTagName: string = '';
  @State deleteTokenCount: number = 0;

  // Dialog controllers
  private createEditController: CustomDialogController = new CustomDialogController({
    builder: TagCreateDialog({
      isEdit: this.isEditMode,
      tagName: this.dialogTagName,
      tagColor: this.dialogTagColor,
      isDark: this.isDarkMode,
      confirm: (name: string, color: string): void => {
        if (this.isEditMode) {
          this.handleEditConfirm(this.dialogTagId, name, color);
        } else {
          this.handleCreateConfirm(name, color);
        }
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private deleteController: CustomDialogController = new CustomDialogController({
    builder: TagDeleteDialog({
      tagName: this.deleteTagName,
      tokenCount: this.deleteTokenCount,
      confirm: (): void => {
        this.handleDeleteConfirm();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear(): void {
    const ctx: Context = this.getUIContext().getHostContext()!;
    TagStorage.init(ctx);
    TokenStorage.init(ctx);
    this.loadTags();
  }

  onPageShow(): void {
    this.loadTags();
  }

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return ThemeManager.getDarkColors();
    }
    return ThemeManager.getLightColors();
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Image(IconConstants.IC_CHEVRON_LEFT)
          .width(22)
          .height(22)
          .fillColor(this.getColors().accentBlue)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text('管理分类标签')
          .fontSize(17)
          .fontWeight(700)
          .fontColor(this.getColors().textPrimary)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      // Description
      Text('创建自定义分类标签，令牌可标记多个标签进行分类筛选')
        .fontSize(12)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
        .padding({ left: 20, right: 20, top: 0, bottom: 4 })

      // Tag list
      List() {
        ForEach(this.tags, (tag: TagRowData, index: number) => {
          ListItem() {
            TagRow({ tag: tag })
          }
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.swipedTagId = tag.id;
            }
          })
          .swipeAction({
            end: {
              builder: (): void => {
                this.SwipeActionBuilder();
              },
              onAction: (): void => {},
              actionAreaDistance: 112
            }
          } as SwipeActionOptions)
          .margin({ left: 20, right: 20, bottom: 8 })
        }, (tag: TagRowData) => tag.id)
        .onMove((from: number, to: number): void => {
          if (from === to) {
            return;
          }
          const moved: TagRowData = this.tags.splice(from, 1)[0];
          this.tags.splice(to, 0, moved);
          for (let i: number = 0; i < this.tags.length; i++) {
            this.tags[i].sortOrder = i;
          }
          const updatedList: TagRowData[] = [...this.tags];
          this.tags = updatedList;
          this.persistTagSortOrder();
        })
        ListItem(){
          Text('可长按进行拖拽排序')
            .fontSize(12)
            .fontColor(this.getColors().textSecondary)
            .width('100%')
            .padding({ left: 20, right: 20, top: 0, bottom: 4 })
            .textAlign(TextAlign.Center)
        }
        // New tag button
        ListItem() {
          Row({ space: 8 }) {
            Image(IconConstants.IC_ADD)
              .width(18)
              .height(18)
              .fillColor(this.getColors().accentBlue)

            Text('新建分类')
              .fontSize(14)
              .fontWeight(600)
              .fontColor(this.getColors().accentBlue)
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .justifyContent(FlexAlign.Center)
          .borderRadius(14)
          .border({ width: 2, color: '#D1D1D6', style: BorderStyle.Dashed })
        }
        .margin({ left: 20, right: 20 })
        .onClick(() => {
          this.showCreateDialog();
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .onItemDragStart((_event: ItemDragInfo, itemIndex: number): void => {
        if (itemIndex >= 0 && itemIndex < this.tags.length) {
          this.dragTagId = this.tags[itemIndex].id;
          for (let i: number = 0; i < this.tags.length; i++) {
            this.tags[i].isDragging = this.tags[i].id === this.dragTagId;
          }
          this.tags = [...this.tags];
        }
      })
      .onItemDrop((): void => {
        for (let i: number = 0; i < this.tags.length; i++) {
          this.tags[i].isDragging = false;
        }
        this.dragTagId = '';
        this.tags = [...this.tags];
      })
      .padding({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getColors().pageBackground)
  }

  @Builder
  SwipeActionBuilder(): void {
    Row() {
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
        const tag: TagRowData | undefined = this.findTagById(this.swipedTagId);
        if (tag !== undefined) {
          this.showEditDialog(tag);
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
        const tag: TagRowData | undefined = this.findTagById(this.swipedTagId);
        if (tag !== undefined) {
          this.showDeleteDialog(tag);
        }
      })
    }
    .height('100%')
  }

  private findTagById(id: string): TagRowData | undefined {
    for (let i = 0; i < this.tags.length; i++) {
      if (this.tags[i].id === id) {
        return this.tags[i];
      }
    }
    return undefined;
  }

  // --- Data loading ---

  private async loadTags(): Promise<void> {
    const all: TagModel[] = await TagStorage.getAll();
    const tokens: TokenModel[] = await TokenStorage.getAll();
    const countMap: Record<string, number> = {};
    for (let i: number = 0; i < tokens.length; i++) {
      const tagNames: string[] = tokens[i].tags;
      for (let j: number = 0; j < tagNames.length; j++) {
        const name: string = tagNames[j];
        if (countMap[name] !== undefined) {
          countMap[name] = countMap[name] + 1;
        } else {
          countMap[name] = 1;
        }
      }
    }
    const displayTags: TagRowData[] = [];
    for (let i: number = 0; i < all.length; i++) {
      const m: TagModel = all[i];
      const d: TagRowData = {
        id: m.id,
        name: m.name,
        color: m.color,
        tokenCount: countMap[m.name] ?? 0,
        sortOrder: m.sortOrder,
        isDragging: false
      };
      displayTags.push(d);
    }
    this.tags = displayTags;
  }

  // --- Dialog helpers ---

  private showCreateDialog(): void {
    if (this.tags.length >= 20) {
      return;
    }
    this.isEditMode = false;
    this.dialogTagName = '';
    this.dialogTagColor = '#4285F4';
    this.dialogTagId = '';
    this.createEditController.open();
  }

  private showEditDialog(tag: TagRowData): void {
    this.isEditMode = true;
    this.dialogTagName = tag.name;
    this.dialogTagColor = tag.color;
    this.dialogTagId = tag.id;
    this.createEditController.open();
  }

  private showDeleteDialog(tag: TagRowData): void {
    this.deleteTagName = tag.name;
    this.deleteTokenCount = tag.tokenCount;
    this.swipedTagId = tag.id;
    this.deleteController.open();
  }

  // --- Persistence ---

  private persistTagSortOrder(): void {
    const models: TagModel[] = [];
    for (let i: number = 0; i < this.tags.length; i++) {
      const t: TagRowData = this.tags[i];
      const model: TagModel = new TagModel();
      model.id = t.id;
      model.name = t.name;
      model.color = t.color;
      model.sortOrder = i;
      model.tokenCount = t.tokenCount;
      models.push(model);
    }
    TagStorage.saveAll(models);
  }

  private isDuplicateName(name: string, excludeId: string): boolean {
    for (let i: number = 0; i < this.tags.length; i++) {
      if (this.tags[i].id !== excludeId && this.tags[i].name === name) {
        return true;
      }
    }
    return false;
  }

  // --- CRUD handlers ---

  private handleCreateConfirm(name: string, color: string): void {
    const trimmedName: string = name.trim();
    if (trimmedName.length === 0) {
      return;
    }
    if (this.tags.length >= 20) {
      return;
    }
    if (this.isDuplicateName(trimmedName, '')) {
      return;
    }
    const newId: string = Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
    const newTag: TagRowData = {
      id: newId,
      name: trimmedName,
      color: color,
      tokenCount: 0,
      sortOrder: this.tags.length,
      isDragging: false
    };
    this.tags = [...this.tags, newTag];

    const model: TagModel = new TagModel();
    model.id = newId;
    model.name = trimmedName;
    model.color = color;
    model.sortOrder = this.tags.length - 1;
    model.tokenCount = 0;
    TagStorage.save(model);
  }

  private handleEditConfirm(id: string, name: string, color: string): void {
    const trimmedName: string = name.trim();
    if (trimmedName.length === 0) {
      return;
    }
    if (this.isDuplicateName(trimmedName, id)) {
      return;
    }
    for (let i: number = 0; i < this.tags.length; i++) {
      if (this.tags[i].id === id) {
        const oldName: string = this.tags[i].name;
        this.tags[i] = {
          id: this.tags[i].id,
          name: trimmedName,
          color: color,
          tokenCount: this.tags[i].tokenCount,
          sortOrder: this.tags[i].sortOrder,
          isDragging: false
        };
        this.tags = [...this.tags];

        const updated: TagModel = new TagModel();
        updated.id = id;
        updated.name = trimmedName;
        updated.color = color;
        updated.sortOrder = i;
        updated.tokenCount = this.tags[i].tokenCount;
        TagStorage.update(updated);

        if (oldName !== trimmedName) {
          this.renameTagInAllTokens(oldName, trimmedName);
        }
        break;
      }
    }
  }

  private async handleDeleteConfirm(): Promise<void> {
    const tagId: string = this.swipedTagId;
    let tagName: string = '';
    const remaining: TagRowData[] = [];
    for (let i: number = 0; i < this.tags.length; i++) {
      if (this.tags[i].id === tagId) {
        tagName = this.tags[i].name;
      } else {
        remaining.push(this.tags[i]);
      }
    }
    this.tags = remaining;

    try {
      await TagStorage.delete(tagId);
      await this.removeTagFromAllTokens(tagName);
    } catch (_e) {
      await this.removeTagFromAllTokens(tagName);
    }
  }

  private async removeTagFromAllTokens(tagName: string): Promise<void> {
    const allTokens: TokenModel[] = await TokenStorage.getAll();
    for (let i: number = 0; i < allTokens.length; i++) {
      const token: TokenModel = allTokens[i];
      const newTags: string[] = [];
      let found: boolean = false;
      for (let j: number = 0; j < token.tags.length; j++) {
        if (token.tags[j] === tagName) {
          found = true;
        } else {
          newTags.push(token.tags[j]);
        }
      }
      if (found) {
        token.tags = newTags;
        await TokenStorage.update(token);
      }
    }
  }

  private async renameTagInAllTokens(oldName: string, newName: string): Promise<void> {
    const allTokens: TokenModel[] = await TokenStorage.getAll();
    for (let i: number = 0; i < allTokens.length; i++) {
      const token: TokenModel = allTokens[i];
      let found: boolean = false;
      const newTags: string[] = [];
      for (let j: number = 0; j < token.tags.length; j++) {
        if (token.tags[j] === oldName) {
          newTags.push(newName);
          found = true;
        } else {
          newTags.push(token.tags[j]);
        }
      }
      if (found) {
        token.tags = newTags;
        await TokenStorage.update(token);
      }
    }
  }
}
