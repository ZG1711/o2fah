import { TokenStorage } from '../storage/TokenStorage';
import { EncryptionHelper } from '../storage/EncryptionHelper';
import { TokenModel } from '../model/TokenModel';
import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export interface BackupPayload {
  version: string;
  exportedAt: number;
  tokens: TokenModel[];
}

export interface MergeResult {
  newTokens: TokenModel[];
  skippedCount: number;
  addedCount: number;
  totalAfter: number;
}

export class BackupImporter {
  static async importFile(password: string, context: Context): Promise<TokenModel[]> {
    let uri: string = '';
    const selectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    selectOptions.maxSelectNumber = 1;
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const selectResult: string[] = await documentPicker.select(selectOptions);
    if (selectResult.length === 0) {
      return [];
    }
    uri = selectResult[0];
    return await BackupImporter.readAndDecrypt(uri, password);
  }

  static async importFromUri(uri: string, password: string): Promise<TokenModel[]> {
    return await BackupImporter.readAndDecrypt(uri, password);
  }

  private static async readAndDecrypt(uri: string, password: string): Promise<TokenModel[]> {

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
    return payload.tokens;
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
        const newToken: TokenModel = new TokenModel();
        newToken.id = Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
        newToken.issuer = importedToken.issuer;
        newToken.account = importedToken.account;
        newToken.secret = importedToken.secret;
        newToken.type = importedToken.type;
        newToken.algorithm = importedToken.algorithm;
        newToken.digits = importedToken.digits;
        newToken.period = importedToken.period;
        newToken.counter = importedToken.counter;
        newToken.tags = importedToken.tags;
        newToken.icon = importedToken.icon;
        newToken.iconColor = importedToken.iconColor;
        newToken.createdAt = Date.now();
        newToken.sortOrder = Date.now();
        newToken.lastUsedAt = 0;
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

  static async performImport(password: string, context: Context): Promise<MergeResult> {
    const importedTokens: TokenModel[] = await BackupImporter.importFile(password, context);
    return await BackupImporter.mergeAndSave(importedTokens);
  }

  static async performImportFromUri(uri: string, password: string): Promise<MergeResult> {
    const importedTokens: TokenModel[] = await BackupImporter.importFromUri(uri, password);
    return await BackupImporter.mergeAndSave(importedTokens);
  }

  private static async mergeAndSave(importedTokens: TokenModel[]): Promise<MergeResult> {
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

    return mergeResult;
  }
}
