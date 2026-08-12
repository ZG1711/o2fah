import { TokenStorage } from '../storage/TokenStorage';
import { EncryptionHelper } from '../storage/EncryptionHelper';
import { TokenModel } from '../model/TokenModel';
import { AppSettings } from '../model/AppSettings';
import { SettingsStorage } from '../storage/SettingsStorage';
import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export interface BackupPayload {
  version: string;
  exportedAt: number;
  tokens: TokenModel[];
}

export class BackupExporter {
  static async exportData(password: string, context: Context): Promise<void> {
    const allTokens: TokenModel[] = await TokenStorage.getAll();

    const payload: BackupPayload = {
      version: '1.0.0',
      exportedAt: Date.now(),
      tokens: allTokens
    };

    const payloadJson: string = JSON.stringify(payload);
    const encrypted: string = await EncryptionHelper.encrypt(payloadJson, password);

    const saveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    const timestamp: string = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
    saveOptions.newFileNames = ['O2FAH_backup_' + timestamp + '.o2fah'];

    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const saveResult: string[] = await documentPicker.save(saveOptions);
    if (saveResult.length === 0) {
      return;
    }
    const uri: string = saveResult[0];
    const encoder: util.TextEncoder = new util.TextEncoder();
    const encryptedBytes: Uint8Array = encoder.encodeInto(encrypted);
    const saveBuf: ArrayBuffer = encryptedBytes.buffer.slice(encryptedBytes.byteOffset,
      encryptedBytes.byteOffset + encryptedBytes.byteLength);
    const file: fileIo.File = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    fileIo.writeSync(file.fd, saveBuf);
    fileIo.fsyncSync(file.fd);
    fileIo.closeSync(file);

    const settings: AppSettings = await SettingsStorage.get();
    settings.lastBackupTime = Date.now();
    await SettingsStorage.save(settings);
  }
}
