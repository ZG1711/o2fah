import { TokenStorage } from '../storage/TokenStorage';
import { TagStorage } from '../storage/TagStorage';
import { EncryptionHelper } from '../storage/EncryptionHelper';
import { TokenModel } from '../model/TokenModel';
import { TagModel } from '../model/TagModel';
import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export interface BackupPayload {
  version: string;
  exportedAt: number;
  tokens: TokenModel[];
  tags?: TagModel[];
}

export interface DecryptedBackup {
  tokens: TokenModel[];
  tags: TagModel[];
}

export interface MergeResult {
  newTokens: TokenModel[];
  skippedCount: number;
  addedCount: number;
  totalAfter: number;
}

export class BackupImporter {
  static async importFile(password: string, context: Context): Promise<DecryptedBackup> {
    let uri: string = '';
    const selectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    selectOptions.maxSelectNumber = 1;
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const selectResult: string[] = await documentPicker.select(selectOptions);
    if (selectResult.length === 0) {
      const empty: DecryptedBackup = { tokens: [], tags: [] };
      return empty;
    }
    uri = selectResult[0];
    return await BackupImporter.readAndDecrypt(uri, password);
  }

  static async importFromUri(uri: string, password: string): Promise<DecryptedBackup> {
    return await BackupImporter.readAndDecrypt(uri, password);
  }

  private static async readAndDecrypt(uri: string, password: string): Promise<DecryptedBackup> {
    const file: fileIo.File = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    const stat: fileIo.Stat = fileIo.statSync(file.fd);
    const buf: ArrayBuffer = new ArrayBuffer(stat.size);
    const bytesRead: number = fileIo.readSync(file.fd, buf);
    fileIo.closeSync(file);

    const decoder: util.TextDecoder = new util.TextDecoder('utf-8');
    const view: Uint8Array = new Uint8Array(buf, 0, bytesRead);
    const content: string = decoder.decodeToString(view, { stream: false });
    const decrypted: string = await EncryptionHelper.decrypt(content, password);
    const payload: BackupPayload = JSON.parse(decrypted) as BackupPayload;
    let tags: TagModel[] = [];
    if (payload.tags !== undefined) {
      tags = payload.tags;
    }
    const result: DecryptedBackup = {
      tokens: payload.tokens,
      tags: tags
    };
    return result;
  }

  static mergeTokens(existing: TokenModel[], imported: TokenModel[]): MergeResult {
    const newTokens: TokenModel[] = [];
    let skippedCount: number = 0;
    let addedCount: number = 0;

    for (let i: number = 0; i < imported.length; i++) {
      const importedToken: TokenModel = imported[i];
      let isDuplicate: boolean = false;
      for (let j: number = 0; j < existing.length; j++) {
        const existingToken: TokenModel = existing[j];
        if (existingToken.issuer === importedToken.issuer &&
          existingToken.account === importedToken.account) {
          isDuplicate = true;
          break;
        }
      }
      if (isDuplicate) {
        skippedCount = skippedCount + 1;
      } else {
        const newToken: TokenModel = BackupImporter.cloneToken(importedToken);
        newToken.id = BackupImporter.generateId();
        newToken.createdAt = Date.now();
        newToken.sortOrder = Date.now();
        newToken.lastUsedAt = 0;
        newToken.version = 0;
        newTokens.push(newToken);
        addedCount = addedCount + 1;
      }
    }

    const totalAfter: number = existing.length + addedCount;
    const result: MergeResult = {
      newTokens: newTokens,
      skippedCount: skippedCount,
      addedCount: addedCount,
      totalAfter: totalAfter
    };
    return result;
  }

  static mergeTags(existing: TagModel[], imported: TagModel[]): TagModel[] {
    const toAdd: TagModel[] = [];
    for (let i: number = 0; i < imported.length; i++) {
      const importedTag: TagModel = imported[i];
      let exists: boolean = false;
      for (let j: number = 0; j < existing.length; j++) {
        if (existing[j].name === importedTag.name) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        const newTag: TagModel = BackupImporter.cloneTag(importedTag);
        newTag.id = BackupImporter.generateId();
        newTag.sortOrder = existing.length + toAdd.length;
        newTag.tokenCount = 0;
        toAdd.push(newTag);
      }
    }
    return toAdd;
  }

  static async performImport(password: string, context: Context): Promise<MergeResult> {
    const decrypted: DecryptedBackup = await BackupImporter.importFile(password, context);
    return await BackupImporter.mergeAndSave(decrypted.tokens, decrypted.tags);
  }

  static async performImportFromUri(uri: string, password: string): Promise<MergeResult> {
    const decrypted: DecryptedBackup = await BackupImporter.importFromUri(uri, password);
    return await BackupImporter.mergeAndSave(decrypted.tokens, decrypted.tags);
  }

  private static async mergeAndSave(importedTokens: TokenModel[], importedTags: TagModel[]): Promise<MergeResult> {
    if (importedTokens.length === 0) {
      const emptyResult: MergeResult = {
        newTokens: [],
        skippedCount: 0,
        addedCount: 0,
        totalAfter: 0
      };
      return emptyResult;
    }

    const existing: TokenModel[] = await TokenStorage.getAll();
    const mergeResult: MergeResult = BackupImporter.mergeTokens(existing, importedTokens);

    for (let i: number = 0; i < mergeResult.newTokens.length; i++) {
      await TokenStorage.save(mergeResult.newTokens[i]);
    }

    await BackupImporter.importTags(importedTags);

    return mergeResult;
  }

  private static async importTags(importedTags: TagModel[]): Promise<void> {
    if (importedTags.length === 0) {
      return;
    }
    const existingTags: TagModel[] = await TagStorage.getAll();
    const toAdd: TagModel[] = BackupImporter.mergeTags(existingTags, importedTags);
    if (toAdd.length === 0) {
      return;
    }
    const combined: TagModel[] = [];
    for (let i: number = 0; i < existingTags.length; i++) {
      combined.push(existingTags[i]);
    }
    for (let i: number = 0; i < toAdd.length; i++) {
      combined.push(toAdd[i]);
    }
    await TagStorage.saveAll(combined);
  }

  private static cloneToken(source: TokenModel): TokenModel {
    const json: string = JSON.stringify(source);
    return JSON.parse(json) as TokenModel;
  }

  private static cloneTag(source: TagModel): TagModel {
    const json: string = JSON.stringify(source);
    return JSON.parse(json) as TagModel;
  }

  private static generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
  }
}
