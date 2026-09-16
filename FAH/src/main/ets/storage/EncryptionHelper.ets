import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { Base64Util } from './Base64Util';

const PBKDF2_ITERATIONS: number = 10000;
const PBKDF2_KEY_SIZE: number = 32;
const SALT_LENGTH: number = 16;
const IV_LENGTH: number = 12;
const AUTH_TAG_LENGTH: number = 16;
const AES_ALGORITHM: string = 'AES256';
const CIPHER_ALGORITHM: string = 'AES256|GCM|PKCS7';
const KDF_ALGORITHM: string = 'PBKDF2|SHA256';

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
    return Base64Util.encode(combined);
  }

  static async decrypt(cipherText: string, password: string): Promise<string> {
    const combined: Uint8Array = Base64Util.decode(cipherText);

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
}
