export class TokenModel {
  id: string = '';
  issuer: string = '';
  account: string = '';
  secret: string = '';
  type: string = 'TOTP';
  algorithm: string = 'SHA-1';
  digits: number = 6;
  period: number = 30;
  counter: number = 0;
  tags: string[] = [];
  icon: string = '';
  iconColor: string = '#4285F4';
  createdAt: number = 0;
  lastUsedAt: number = 0;
  sortOrder: number = 0;

  static create(issuer: string, account: string, secret: string): TokenModel {
    const t: TokenModel = new TokenModel();
    t.id = TokenModel.generateId();
    t.issuer = issuer;
    t.account = account;
    t.secret = secret;
    t.createdAt = Date.now();
    t.sortOrder = Date.now();
    return t;
  }

  private static generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2);
  }
}
