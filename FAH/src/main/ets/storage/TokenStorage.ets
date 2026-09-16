import { preferences } from '@kit.ArkData';
import { TokenModel } from '../model/TokenModel';
import { HuksStore } from './HuksStore';
import { TokenPayloadCodec } from './TokenPayloadCodec';

const STORE_NAME: string = 'o2fah_tokens';
const KEY_TOKENS_V2: string = 'tokens_v2';
const KEY_TOKENS_LEGACY: string = 'tokens';

export class TokenStorage {
  private static storedContext: Context | undefined = undefined;
  private static prefsCache: preferences.Preferences | undefined = undefined;
  private static cachedTokens: TokenModel[] | undefined = undefined;
  private static decryptFailedFlag: boolean = false;

  static init(ctx: Context): void {
    TokenStorage.storedContext = ctx;
  }

  /** 读取并重置「解密失败」标志（供 UI 层提示一次） */
  static consumeDecryptFailed(): boolean {
    const failed: boolean = TokenStorage.decryptFailedFlag;
    TokenStorage.decryptFailedFlag = false;
    return failed;
  }

  static async getAll(): Promise<TokenModel[]> {
    if (TokenStorage.cachedTokens !== undefined) {
      return TokenStorage.cachedTokens;
    }
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    const encrypted: string = prefs.getSync(KEY_TOKENS_V2, '') as string;
    if (encrypted !== '') {
      try {
        const tokens: TokenModel[] = await TokenStorage.readEncrypted(encrypted);
        TokenStorage.cachedTokens = tokens;
        return tokens;
      } catch (e) {
        TokenStorage.decryptFailedFlag = true;
        TokenStorage.cachedTokens = [];
        return [];
      }
    }
    const legacy: string = prefs.getSync(KEY_TOKENS_LEGACY, '') as string;
    if (legacy !== '' && legacy !== '[]') {
      const tokens: TokenModel[] = TokenStorage.parseTokens(legacy);
      await TokenStorage.writeEncrypted(prefs, tokens);
      const verify: TokenModel[] = await TokenStorage.readEncrypted(
        prefs.getSync(KEY_TOKENS_V2, '') as string);
      if (verify.length !== tokens.length) {
        throw new Error('token migration verify failed');
      }
      prefs.deleteSync(KEY_TOKENS_LEGACY);
      await prefs.flush();
      TokenStorage.cachedTokens = tokens;
      return tokens;
    }
    TokenStorage.cachedTokens = [];
    return [];
  }

  static async save(token: TokenModel): Promise<void> {
    const tokens: TokenModel[] = await TokenStorage.getAll();
    tokens.push(token);
    await TokenStorage.saveAll(tokens);
  }

  static async saveAll(tokens: TokenModel[]): Promise<void> {
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    await TokenStorage.writeEncrypted(prefs, tokens);
    TokenStorage.cachedTokens = tokens;
  }

  static async update(token: TokenModel): Promise<void> {
    const tokens: TokenModel[] = await TokenStorage.getAll();
    for (let i: number = 0; i < tokens.length; i++) {
      if (tokens[i].id === token.id) {
        tokens[i] = token;
        break;
      }
    }
    await TokenStorage.saveAll(tokens);
  }

  static async delete(id: string): Promise<void> {
    const tokens: TokenModel[] = await TokenStorage.getAll();
    const filtered: TokenModel[] = [];
    for (let i: number = 0; i < tokens.length; i++) {
      if (tokens[i].id !== id) {
        filtered.push(tokens[i]);
      }
    }
    await TokenStorage.saveAll(filtered);
  }

  static async clear(): Promise<void> {
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    prefs.deleteSync(KEY_TOKENS_V2);
    prefs.deleteSync(KEY_TOKENS_LEGACY);
    await prefs.flush();
    TokenStorage.cachedTokens = undefined;
  }

  private static async readEncrypted(encrypted: string): Promise<TokenModel[]> {
    const cipher: string = TokenPayloadCodec.extractCipher(encrypted);
    const jsonStr: string = await HuksStore.decrypt(cipher);
    return TokenStorage.parseTokens(jsonStr);
  }

  private static async writeEncrypted(prefs: preferences.Preferences,
    tokens: TokenModel[]): Promise<void> {
    const jsonStr: string = JSON.stringify(tokens);
    const cipher: string = await HuksStore.encrypt(jsonStr);
    prefs.putSync(KEY_TOKENS_V2, TokenPayloadCodec.build(cipher));
    await prefs.flush();
  }

  private static getPrefsSync(ctx: Context): preferences.Preferences {
    if (TokenStorage.prefsCache === undefined) {
      const options: preferences.Options = { name: STORE_NAME };
      TokenStorage.prefsCache = preferences.getPreferencesSync(ctx, options);
    }
    return TokenStorage.prefsCache;
  }

  private static getContext(): Context {
    if (TokenStorage.storedContext === undefined) {
      throw new Error('TokenStorage not initialized. Call TokenStorage.init(context) first.');
    }
    return TokenStorage.storedContext;
  }

  private static parseTokens(jsonStr: string): TokenModel[] {
    const rawArray: Object[] = JSON.parse(jsonStr) as Object[];
    const result: TokenModel[] = [];
    for (let i: number = 0; i < rawArray.length; i++) {
      const raw: Record<string, Object> = rawArray[i] as Record<string, Object>;
      const token: TokenModel = new TokenModel();
      token.id = (raw['id'] ?? '') as string;
      token.issuer = (raw['issuer'] ?? '') as string;
      token.account = (raw['account'] ?? '') as string;
      token.secret = (raw['secret'] ?? '') as string;
      token.type = (raw['type'] ?? 'TOTP') as string;
      token.algorithm = (raw['algorithm'] ?? 'SHA-1') as string;
      token.digits = (raw['digits'] ?? 6) as number;
      token.period = (raw['period'] ?? 30) as number;
      token.counter = (raw['counter'] ?? 0) as number;
      const rawTags: Object = raw['tags'];
      if (rawTags instanceof Array) {
        token.tags = rawTags as string[];
      }
      token.icon = (raw['icon'] ?? '') as string;
      token.iconColor = (raw['iconColor'] ?? '#4285F4') as string;
      token.createdAt = (raw['createdAt'] ?? 0) as number;
      token.lastUsedAt = (raw['lastUsedAt'] ?? 0) as number;
      token.sortOrder = (raw['sortOrder'] ?? 0) as number;
      token.version = (raw['version'] ?? 0) as number;
      result.push(token);
    }
    return result;
  }
}
