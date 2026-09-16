const BASE64_CHARS: string =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/**
 * Base64 编解码（纯手写，不依赖 util.Base64Helper，避免引入额外编码差异）。
 * 供 HUKS 密文与备份加解密共用。
 */
export class Base64Util {
  static encode(data: Uint8Array): string {
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

  static decode(base64: string): Uint8Array {
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
