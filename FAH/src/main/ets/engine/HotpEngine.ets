import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { Base32Decoder } from './Base32Decoder';

export class HotpEngine {
  private static symKeyCache: Map<string, cryptoFramework.SymKey> = new Map<string, cryptoFramework.SymKey>();

  static async generate(secret: string, counter: number, algorithm: string, digits: number): Promise<string> {
    let keyBytes: Uint8Array = Base32Decoder.decode(secret);

    let counterBytes: Uint8Array = HotpEngine.buildCounterBuffer(counter);

    let macAlgName: string = HotpEngine.mapAlgorithm(algorithm);

    let hmacResult: Uint8Array = await HotpEngine.computeHmac(secret, keyBytes, macAlgName, counterBytes);

    let otp: number = HotpEngine.dynamicTruncation(hmacResult);

    let otpCode: number = otp % HotpEngine.powerOfTen(digits);
    let codeStr: string = otpCode.toString();
    while (codeStr.length < digits) {
      codeStr = '0' + codeStr;
    }

    return codeStr;
  }

  private static mapAlgorithm(algorithm: string): string {
    if (algorithm === 'SHA-1') {
      return 'SHA1';
    }
    if (algorithm === 'SHA-256') {
      return 'SHA256';
    }
    if (algorithm === 'SHA-512') {
      return 'SHA512';
    }
    return 'SHA1';
  }

  private static buildCounterBuffer(counter: number): Uint8Array {
    let counterBytes: Uint8Array = new Uint8Array(8);
    let value: number = counter;
    for (let i: number = 7; i >= 0; i--) {
      counterBytes[i] = value & 0xFF;
      value = value >> 8;
    }
    return counterBytes;
  }

  private static async computeHmac(secret: string, keyBytes: Uint8Array, macAlgName: string, messageBytes: Uint8Array): Promise<Uint8Array> {
    const cacheKey: string = secret + '|' + macAlgName;
    let symKey: cryptoFramework.SymKey | undefined = HotpEngine.symKeyCache.get(cacheKey);
    if (symKey === undefined) {
      const symKeyBlob: cryptoFramework.DataBlob = { data: keyBytes };
      const symKeyGenerator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
      symKey = await symKeyGenerator.convertKey(symKeyBlob);
      HotpEngine.symKeyCache.set(cacheKey, symKey);
    }

    let mac: cryptoFramework.Mac = cryptoFramework.createMac(macAlgName);
    await mac.init(symKey);
    await mac.update({ data: messageBytes });
    let macResult: cryptoFramework.DataBlob = await mac.doFinal();

    return new Uint8Array(macResult.data);
  }

  private static dynamicTruncation(hmacResult: Uint8Array): number {
    let offset: number = hmacResult[hmacResult.length - 1] & 0x0F;
    let binary: number = ((hmacResult[offset] & 0x7F) << 24) |
                         ((hmacResult[offset + 1] & 0xFF) << 16) |
                         ((hmacResult[offset + 2] & 0xFF) << 8) |
                         (hmacResult[offset + 3] & 0xFF);
    return binary;
  }

  private static powerOfTen(digits: number): number {
    let result: number = 1;
    for (let i: number = 0; i < digits; i++) {
      result = result * 10;
    }
    return result;
  }
}
