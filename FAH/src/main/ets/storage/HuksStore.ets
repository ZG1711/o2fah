import { huks } from '@kit.UniversalKeystoreKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Base64Util } from './Base64Util';

const DOMAIN: number = 0x0000;
const KEY_ALIAS: string = 'o2fah_store_key_v1';
const AEAD_LEN: number = 16;
const NONCE_LEN: number = 12;

export class HuksDecryptError extends Error {
  constructor(message: string) {
    super(message);
  }
}

export class HuksStore {
  private static keyReady: boolean = false;

  /** 幂等：仅首次生成密钥 */
  static async ensureKey(): Promise<void> {
    if (HuksStore.keyReady) {
      return;
    }
    const emptyOptions: huks.HuksOptions = { properties: [] };
    const exists: boolean = await huks.hasKeyItem(KEY_ALIAS, emptyOptions);
    if (!exists) {
      const options: huks.HuksOptions = {
        properties: [
          { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
          { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
          {
            tag: huks.HuksTag.HUKS_TAG_PURPOSE,
            value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT |
              huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
          }
        ]
      };
      await huks.generateKeyItem(KEY_ALIAS, options);
    }
    HuksStore.keyReady = true;
  }

  /** 加密 UTF-8 字符串，返回 base64(密文 || AEAD(16) || NONCE(12)) */
  static async encrypt(plainText: string): Promise<string> {
    await HuksStore.ensureKey();
    const options: huks.HuksOptions = {
      properties: [
        { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
        { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
        { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT },
        { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
        { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM }
      ],
      inData: HuksStore.stringToUint8Array(plainText)
    };
    const initResult = await huks.initSession(KEY_ALIAS, options);
    const finishResult = await huks.finishSession(initResult.handle, options);
    const out: Uint8Array | undefined = finishResult.outData;
    if (out === undefined) {
      throw new Error('HUKS encrypt returned empty outData');
    }
    return Base64Util.encode(out);
  }

  /** 解密 base64(密文 || AEAD || NONCE) */
  static async decrypt(cipherBase64: string): Promise<string> {
    await HuksStore.ensureKey();
    const packed: Uint8Array = Base64Util.decode(cipherBase64);
    if (packed.length <= AEAD_LEN + NONCE_LEN) {
      throw new HuksDecryptError('cipher length too short');
    }
    const nonce: Uint8Array = packed.slice(packed.length - NONCE_LEN);
    const aead: Uint8Array = packed.slice(packed.length - NONCE_LEN - AEAD_LEN, packed.length - NONCE_LEN);
    const cipherOnly: Uint8Array = packed.slice(0, packed.length - NONCE_LEN - AEAD_LEN);

    const options: huks.HuksOptions = {
      properties: [
        { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
        { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
        { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
        { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
        { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
        { tag: huks.HuksTag.HUKS_TAG_NONCE, value: nonce },
        { tag: huks.HuksTag.HUKS_TAG_AE_TAG, value: aead }
      ],
      inData: cipherOnly
    };
    try {
      const initResult = await huks.initSession(KEY_ALIAS, options);
      const finishResult = await huks.finishSession(initResult.handle, options);
      const out: Uint8Array | undefined = finishResult.outData;
      if (out === undefined) {
        throw new HuksDecryptError('HUKS decrypt returned empty outData');
      }
      return HuksStore.uint8ArrayToString(out);
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', 'HUKS decrypt failed: %{public}s', JSON.stringify(e));
      throw new HuksDecryptError('HUKS decrypt failed');
    }
  }

  /** 危险操作：仅在用户确认「清除数据」时调用 */
  static async deleteKey(): Promise<void> {
    const emptyOptions: huks.HuksOptions = { properties: [] };
    if (await huks.hasKeyItem(KEY_ALIAS, emptyOptions)) {
      await huks.deleteKeyItem(KEY_ALIAS, emptyOptions);
    }
    HuksStore.keyReady = false;
  }

  private static stringToUint8Array(str: string): Uint8Array {
    return new util.TextEncoder().encodeInto(str);
  }

  private static uint8ArrayToString(data: Uint8Array): string {
    const decoder: util.TextDecoder = new util.TextDecoder('utf-8');
    return decoder.decodeToString(data, { stream: false });
  }
}
