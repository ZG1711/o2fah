export interface NormalizeResult {
  secret: string;
  correctedCount: number;
}

const BASE32_PATTERN: RegExp = /^[A-Z2-7]+$/;

/**
 * Base32 密钥归一化：
 * 1) 剔除空格 / - / _ / 制表符 / 换行 / = 填充
 * 2) 小写转大写
 * 3) 非法字符 0→O、1→I、8→B（三者均不在 Base32 字母表内，映射无歧义）
 * 归一化后仍可能非法（如含 '!'），由调用方用 isValid() 判定。
 */
export class SecretNormalizer {
  static normalize(input: string): NormalizeResult {
    let cleaned: string = '';
    let correctedCount: number = 0;
    for (let i: number = 0; i < input.length; i++) {
      const upper: string = input.charAt(i).toUpperCase();
      if (upper === ' ' || upper === '-' || upper === '_' || upper === '\t'
        || upper === '\n' || upper === '\r' || upper === '=') {
        continue;
      }
      if (upper === '0') {
        cleaned = cleaned + 'O';
        correctedCount = correctedCount + 1;
      } else if (upper === '1') {
        cleaned = cleaned + 'I';
        correctedCount = correctedCount + 1;
      } else if (upper === '8') {
        cleaned = cleaned + 'B';
        correctedCount = correctedCount + 1;
      } else {
        cleaned = cleaned + upper;
      }
    }
    const result: NormalizeResult = { secret: cleaned, correctedCount: correctedCount };
    return result;
  }

  static isValid(secret: string): boolean {
    if (secret.length === 0) {
      return false;
    }
    return BASE32_PATTERN.test(secret);
  }
}
