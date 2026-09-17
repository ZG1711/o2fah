import { TokenModel } from '../model/TokenModel';

/**
 * 令牌判重。口径与 BackupImporter.mergeTokens 保持一致：
 * 比较 trim 后的 issuer 与 account，区分大小写。
 */
export class TokenMatcher {
  static isDuplicate(existing: TokenModel[], issuer: string, account: string): boolean {
    const targetIssuer: string = issuer.trim();
    const targetAccount: string = account.trim();
    for (let i: number = 0; i < existing.length; i++) {
      if (existing[i].issuer === targetIssuer && existing[i].account === targetAccount) {
        return true;
      }
    }
    return false;
  }
}
