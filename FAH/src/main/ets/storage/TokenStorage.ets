import { preferences } from '@kit.ArkData';
import { TokenModel } from '../model/TokenModel';

const STORE_NAME: string = 'o2fah_tokens';
const KEY_TOKENS: string = 'tokens';

export class TokenStorage {
  private static storedContext: Context | undefined = undefined;
  private static prefsCache: preferences.Preferences | undefined = undefined;

  static init(ctx: Context): void {
    TokenStorage.storedContext = ctx;
  }

  static async getAll(): Promise<TokenModel[]> {
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    const jsonStr: string = prefs.getSync(KEY_TOKENS, '[]') as string;
    return TokenStorage.parseTokens(jsonStr);
  }

  static async save(token: TokenModel): Promise<void> {
    const tokens: TokenModel[] = await TokenStorage.getAll();
    tokens.push(token);
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(tokens);
    prefs.putSync(KEY_TOKENS, jsonStr);
    await prefs.flush();
  }

  static async saveAll(tokens: TokenModel[]): Promise<void> {
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(tokens);
    prefs.putSync(KEY_TOKENS, jsonStr);
    await prefs.flush();
  }

  static async update(token: TokenModel): Promise<void> {
    const tokens: TokenModel[] = await TokenStorage.getAll();
    for (let i: number = 0; i < tokens.length; i++) {
      if (tokens[i].id === token.id) {
        tokens[i] = token;
        break;
      }
    }
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(tokens);
    prefs.putSync(KEY_TOKENS, jsonStr);
    await prefs.flush();
  }

  static async delete(id: string): Promise<void> {
    const tokens: TokenModel[] = await TokenStorage.getAll();
    const filtered: TokenModel[] = [];
    for (let i: number = 0; i < tokens.length; i++) {
      if (tokens[i].id !== id) {
        filtered.push(tokens[i]);
      }
    }
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    const jsonStr: string = JSON.stringify(filtered);
    prefs.putSync(KEY_TOKENS, jsonStr);
    await prefs.flush();
  }

  static async clear(): Promise<void> {
    const ctx: Context = TokenStorage.getContext();
    const prefs: preferences.Preferences = TokenStorage.getPrefsSync(ctx);
    prefs.deleteSync(KEY_TOKENS);
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
      token.iconColor = (raw['iconColor'] ?? '#4285F4') as string;
      token.createdAt = (raw['createdAt'] ?? 0) as number;
      token.lastUsedAt = (raw['lastUsedAt'] ?? 0) as number;
      token.sortOrder = (raw['sortOrder'] ?? 0) as number;
      result.push(token);
    }
    return result;
  }
}
