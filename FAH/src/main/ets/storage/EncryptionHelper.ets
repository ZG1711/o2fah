import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

const PBKDF2_ITERATIONS: number = 10000;
const PBKDF2_KEY_SIZE: number = 32;
const SALT_LENGTH: number = 16;
const IV_LENGTH: number = 12;
const AUTH_TAG_LENGTH: number = 16;
const AES_ALGORITHM: string = 'AES256';
const CIPHER_ALGORITHM: string = 'AES256|GCM|PKCS7';
const KDF_ALGORITHM: string = 'PBKDF2|SHA256';

const BASE64_CHARS: string =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

export class EncryptionHelper {

  static async encrypt(plainText: string, password: string): Promise<string> {
    const encoder: util.TextEncoder = new util.TextEncoder();
    const plainBytes: Uint8Array = encoder.encodeInto(plainText);
    const plainBlob: cryptoFramework.DataBlob = { data: plainBytes };

    const salt: cryptoFramework.DataBlob = EncryptionHelper.generateRandom(SALT_LENGTH);
    const iv: cryptoFramework.DataBlob = EncryptionHelper.generateRandom(IV_LENGTH);

    const symKey: cryptoFramework.SymKey = EncryptionHelper.deriveKey(password, salt.data);
    const emptyAad: cryptoFramework.DataBlob = { data: new Uint8Array(0) };

    const gcmParams: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: iv,
      aad: emptyAad,
      authTag: { data: new Uint8Array(AUTH_TAG_LENGTH) }
    };

    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher(CIPHER_ALGORITHM);
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, gcmParams);
    const cipherData: cryptoFramework.DataBlob = await cipher.update(plainBlob);
    gcmParams.authTag = await cipher.doFinal(null);

    const authTag: Uint8Array = gcmParams.authTag.data;

    const combined: Uint8Array = EncryptionHelper.concatArrays(
      salt.data, iv.data, cipherData.data, authTag);
    return EncryptionHelper.uint8ArrayToBase64(combined);
  }

  static async decrypt(cipherText: string, password: string): Promise<string> {
    const combined: Uint8Array = EncryptionHelper.base64ToUint8Array(cipherText);

    const salt: Uint8Array = new Uint8Array(SALT_LENGTH);
    const iv: Uint8Array = new Uint8Array(IV_LENGTH);
    const authTag: Uint8Array = new Uint8Array(AUTH_TAG_LENGTH);
    const cipherLen: number = combined.length - SALT_LENGTH - IV_LENGTH - AUTH_TAG_LENGTH;
    const cipherOnly: Uint8Array = new Uint8Array(cipherLen);

    for (let i: number = 0; i < SALT_LENGTH; i++) {
      salt[i] = combined[i];
    }
    for (let i: number = 0; i < IV_LENGTH; i++) {
      iv[i] = combined[SALT_LENGTH + i];
    }
    for (let i: number = 0; i < cipherLen; i++) {
      cipherOnly[i] = combined[SALT_LENGTH + IV_LENGTH + i];
    }
    for (let i: number = 0; i < AUTH_TAG_LENGTH; i++) {
      authTag[i] = combined[SALT_LENGTH + IV_LENGTH + cipherLen + i];
    }

    const symKey: cryptoFramework.SymKey = EncryptionHelper.deriveKey(password, salt);
    const emptyAad: cryptoFramework.DataBlob = { data: new Uint8Array(0) };

    const gcmParams: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: iv },
      aad: emptyAad,
      authTag: { data: authTag }
    };

    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher(CIPHER_ALGORITHM);
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, gcmParams);
    const cipherResult: cryptoFramework.DataBlob = await cipher.update({ data: cipherOnly });
    await cipher.doFinal(null);

    const decoder: util.TextDecoder = new util.TextDecoder('utf-8');
    const result: string = decoder.decodeToString(cipherResult.data, { stream: false });
    return result;
  }

  private static deriveKey(password: string, salt: Uint8Array): cryptoFramework.SymKey {
    const passwordEncoded: Uint8Array = new util.TextEncoder().encodeInto(password);
    const spec: cryptoFramework.PBKDF2Spec = {
      algName: 'PBKDF2',
      password: passwordEncoded,
      salt: salt,
      iterations: PBKDF2_ITERATIONS,
      keySize: PBKDF2_KEY_SIZE
    };
    const kdf: cryptoFramework.Kdf = cryptoFramework.createKdf(KDF_ALGORITHM);
    const derivedData: cryptoFramework.DataBlob = kdf.generateSecretSync(spec);
    const keyGenerator: cryptoFramework.SymKeyGenerator =
      cryptoFramework.createSymKeyGenerator(AES_ALGORITHM);
    const symKey: cryptoFramework.SymKey = keyGenerator.convertKeySync(derivedData);
    return symKey;
  }

  private static generateRandom(length: number): cryptoFramework.DataBlob {
    const rand: cryptoFramework.Random = cryptoFramework.createRandom();
    return rand.generateRandomSync(length);
  }

  private static concatArrays(a: Uint8Array, b: Uint8Array, c: Uint8Array,
    d: Uint8Array): Uint8Array {
    const totalLength: number = a.length + b.length + c.length + d.length;
    const result: Uint8Array = new Uint8Array(totalLength);
    let offset: number = 0;
    for (let i: number = 0; i < a.length; i++) {
      result[offset] = a[i];
      offset++;
    }
    for (let i: number = 0; i < b.length; i++) {
      result[offset] = b[i];
      offset++;
    }
    for (let i: number = 0; i < c.length; i++) {
      result[offset] = c[i];
      offset++;
    }
    for (let i: number = 0; i < d.length; i++) {
      result[offset] = d[i];
      offset++;
    }
    return result;
  }

  private static uint8ArrayToBase64(data: Uint8Array): string {
    let result: string = '';
    for (let i: number = 0; i < data.length; i += 3) {
      const b1: number = data[i];
      const b2: number = (i + 1 < data.length) ? data[i + 1] : 0;
      const b3: number = (i + 2 < data.length) ? data[i + 2] : 0;

      const enc1: number = b1 >> 2;
      const enc2: number = ((b1 & 3) << 4) | (b2 >> 4);
      const enc3: number = ((b2 & 15) << 2) | (b3 >> 6);
      const enc4: number = b3 & 63;

      result += BASE64_CHARS.charAt(enc1);
      result += BASE64_CHARS.charAt(enc2);

      if (i + 1 < data.length) {
        result += BASE64_CHARS.charAt(enc3);
      } else {
        result += '=';
      }

      if (i + 2 < data.length) {
        result += BASE64_CHARS.charAt(enc4);
      } else {
        result += '=';
      }
    }
    return result;
  }

  private static base64ToUint8Array(base64: string): Uint8Array {
    let str: string = base64;
    for (let i: number = str.length - 1; i >= 0; i--) {
      if (str.charAt(i) === '=') {
        str = str.substring(0, i);
      } else {
        break;
      }
    }

    const outputLen: number = Math.floor(str.length * 3 / 4);
    const result: Uint8Array = new Uint8Array(outputLen);
    let byteIndex: number = 0;

    for (let i: number = 0; i < str.length; i += 4) {
      const enc1: number = BASE64_CHARS.indexOf(str.charAt(i));
      const enc2: number = BASE64_CHARS.indexOf(str.charAt(i + 1));
      let enc3: number = 0;
      let enc4: number = 0;

      if (i + 2 < str.length && str.charAt(i + 2) !== '=') {
        enc3 = BASE64_CHARS.indexOf(str.charAt(i + 2));
      }
      if (i + 3 < str.length && str.charAt(i + 3) !== '=') {
        enc4 = BASE64_CHARS.indexOf(str.charAt(i + 3));
      }

      result[byteIndex] = (enc1 << 2) | (enc2 >> 4);
      byteIndex++;

      if (enc3 !== 0 || str.charAt(i + 2) !== '=') {
        if (byteIndex < outputLen) {
          result[byteIndex] = ((enc2 & 15) << 4) | (enc3 >> 2);
          byteIndex++;
        }
      }

      if (enc4 !== 0 || str.charAt(i + 3) !== '=') {
        if (byteIndex < outputLen) {
          result[byteIndex] = ((enc3 & 3) << 6) | enc4;
          byteIndex++;
        }
      }
    }

    if (byteIndex < outputLen) {
      const trimmed: Uint8Array = new Uint8Array(byteIndex);
      for (let i: number = 0; i < byteIndex; i++) {
        trimmed[i] = result[i];
      }
      return trimmed;
    }
    return result;
  }
}
